import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/task_stats.dart';
import '../services/api_service.dart';

class TaskProvider extends ChangeNotifier {
  final ApiService _apiService;

  List<Task> _tasks = [];
  TaskStats _todayStats = TaskStats.empty();
  TaskStats _statusStats = TaskStats.empty();
  bool _isLoading = false;
  String? _errorMessage;

  // Active filters/selectors
  DateTime _selectedDate = DateTime.now();
  TaskStatus? _filterStatus;
  TaskPriority? _filterPriority;
  String _searchQuery = '';

  TaskProvider(this._apiService);

  // Getters
  List<Task> get tasks => _tasks;
  TaskStats get todayStats => _todayStats;
  TaskStats get statusStats => _statusStats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  DateTime get selectedDate => _selectedDate;
  TaskStatus? get filterStatus => _filterStatus;
  TaskPriority? get filterPriority => _filterPriority;
  String get searchQuery => _searchQuery;

  // Filter methods
  void setCalendarDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
    fetchTasksForDate(date);
  }

  void setFilterStatus(TaskStatus? status) {
    _filterStatus = status;
    notifyListeners();
    fetchTasks();
  }

  void setFilterPriority(TaskPriority? priority) {
    _filterPriority = priority;
    notifyListeners();
    fetchTasks();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
    fetchTasks();
  }

  void clearFilters() {
    _filterStatus = null;
    _filterPriority = null;
    _searchQuery = '';
    notifyListeners();
    fetchTasks();
  }

  // ==========================================
  // API ACTIONS
  // ==========================================

  // Fetch tasks matching the general filters (status, priority, search)
  Future<void> fetchTasks() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _tasks = await _apiService.getTasks(
        status: _filterStatus,
        priority: _filterPriority,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );
      
      // Also update overall status counts
      _statusStats = await _apiService.getStatusStats();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch tasks for a specific calendar date (for the Calendar view)
  Future<List<Task>> fetchTasksForDate(DateTime date) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final dateTasks = await _apiService.getTasks(
        date: date,
        status: _filterStatus,
        priority: _filterPriority,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );
      _tasks = dateTasks;
      return dateTasks;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch statistics only
  Future<void> fetchStats() async {
    try {
      _todayStats = await _apiService.getTodayStats();
      _statusStats = await _apiService.getStatusStats();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching stats: $e');
    }
  }

  // Combine fetching of general tasks, today's stats, and status stats
  Future<void> refreshAll() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Fetch tasks for today by default or general tasks depending on view
      _tasks = await _apiService.getTasks(
        status: _filterStatus,
        priority: _filterPriority,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );
      _todayStats = await _apiService.getTodayStats();
      _statusStats = await _apiService.getStatusStats();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create a new task
  Future<bool> addTask(Task task) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.createTask(task);
      await refreshAll();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update an existing task
  Future<bool> editTask(Task task) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.updateTask(task);
      await refreshAll();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete a task
  Future<bool> removeTask(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.deleteTask(id);
      await refreshAll();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
