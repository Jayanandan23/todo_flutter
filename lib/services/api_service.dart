import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/task.dart';
import '../models/task_stats.dart';

class ApiService {
  // Toggle this to false to connect to your real Spring Boot backend!
  static bool useMock = true;

  // Base URL for the Spring Boot backend
  // Use 10.0.2.2 for Android emulator, 127.0.0.1/localhost for Desktop/iOS
  static const String baseUrl = 'http://10.0.2.2:8080/api';

  // JWT Auth token
  String? _token;

  ApiService() {
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }

  Future<void> _saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  // ==========================================
  // AUTHENTICATION
  // ==========================================

  Future<User> register(String username, String email, String password) async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 800)); // Simulate delay

      final prefs = await SharedPreferences.getInstance();
      List<String> mockUsers = prefs.getStringList('mock_users') ?? [];

      // Check if user already exists
      for (var userStr in mockUsers) {
        final u = jsonDecode(userStr);
        if (u['email'] == email || u['username'] == username) {
          throw Exception('Username or email already exists');
        }
      }

      final newUser = {
        'id': mockUsers.length + 1,
        'username': username,
        'email': email,
        'password':
            password, // Obviously not secure for production, but this is a local mock
      };

      mockUsers.add(jsonEncode(newUser));
      await prefs.setStringList('mock_users', mockUsers);

      return User(id: newUser['id'] as int, username: username, email: email);
    } else {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return User.fromJson(jsonDecode(response.body));
      } else {
        final errorMsg = _extractErrorMessage(response.body);
        throw Exception(errorMsg);
      }
    }
  }

  Future<User> login(String emailOrUsername, String password) async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 800));

      final prefs = await SharedPreferences.getInstance();
      List<String> mockUsers = prefs.getStringList('mock_users') ?? [];

      // Add a default user if empty for easier testing
      if (mockUsers.isEmpty) {
        final defaultUser = {
          'id': 1,
          'username': 'demo_user',
          'email': 'demo@example.com',
          'password': 'password123',
        };
        mockUsers.add(jsonEncode(defaultUser));
        await prefs.setStringList('mock_users', mockUsers);
      }

      Map<String, dynamic>? matchedUser;
      for (var userStr in mockUsers) {
        final u = jsonDecode(userStr);
        if ((u['email'] == emailOrUsername ||
                u['username'] == emailOrUsername) &&
            u['password'] == password) {
          matchedUser = u;
          break;
        }
      }

      if (matchedUser == null) {
        throw Exception('Invalid username/email or password');
      }

      final mockToken = 'mock_jwt_token_for_user_${matchedUser['id']}';
      await _saveToken(mockToken);

      // Also write username to prefs for profile details
      await prefs.setString('mock_current_username', matchedUser['username']);
      await prefs.setString('mock_current_email', matchedUser['email']);
      await prefs.setInt('mock_current_user_id', matchedUser['id']);

      // Setup initial tasks for first time demo
      await _setupDefaultTasksIfNone(matchedUser['id']);

      return User(
        id: matchedUser['id'],
        username: matchedUser['username'],
        email: matchedUser['email'],
        token: mockToken,
      );
    } else {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username':
              emailOrUsername, // Real endpoint might accept email or username
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = User.fromJson(data);
        if (user.token != null) {
          await _saveToken(user.token!);
        }
        return user;
      } else {
        final errorMsg = _extractErrorMessage(response.body);
        throw Exception(errorMsg);
      }
    }
  }

  // ==========================================
  // TASK CRUD OPERATIONS
  // ==========================================

  Future<List<Task>> getTasks({
    TaskStatus? status,
    TaskPriority? priority,
    DateTime? date,
    String? search,
    int page = 1,
    int limit = 10,
  }) async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 500));
      final tasks = await _getMockTasks();

      List<Task> filtered = List.from(tasks);

      // Filter by status
      if (status != null) {
        filtered = filtered.where((t) => t.status == status).toList();
      }

      // Filter by priority
      if (priority != null) {
        filtered = filtered.where((t) => t.priority == priority).toList();
      }

      // Filter by date (YYYY-MM-DD)
      if (date != null) {
        filtered = filtered
            .where(
              (t) =>
                  t.dueDate.year == date.year &&
                  t.dueDate.month == date.month &&
                  t.dueDate.day == date.day,
            )
            .toList();
      }

      // Filter by search query (case insensitive match on title/description)
      if (search != null && search.trim().isNotEmpty) {
        final query = search.toLowerCase();
        filtered = filtered
            .where(
              (t) =>
                  t.title.toLowerCase().contains(query) ||
                  t.description.toLowerCase().contains(query),
            )
            .toList();
      }

      // Sort by status (pending first, then in progress, completed last)
      // and then by due date
      filtered.sort((a, b) {
        if (a.status != b.status) {
          return a.status.index.compareTo(b.status.index);
        }
        return a.dueDate.compareTo(b.dueDate);
      });

      // Pagination
      final int startIndex = (page - 1) * limit;
      if (startIndex >= filtered.length) {
        return [];
      }
      final int endIndex = startIndex + limit;
      return filtered.sublist(
        startIndex,
        endIndex > filtered.length ? filtered.length : endIndex,
      );
    } else {
      // Build query parameters for REST API
      final queryParameters = <String, String>{
        'page': page.toString(),
        'size': limit.toString(),
        if (status != null) 'status': Task.statusToString(status),
        if (priority != null) 'priority': Task.priorityToString(priority),
        if (date != null)
          'date':
              "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}",
        if (search != null && search.isNotEmpty) 'search': search,
      };

      final uri = Uri.parse(
        '$baseUrl/tasks',
      ).replace(queryParameters: queryParameters);
      final response = await http.get(uri, headers: _getHeaders());

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((item) => Task.fromJson(item)).toList();
      } else {
        throw Exception(_extractErrorMessage(response.body));
      }
    }
  }

  Future<Task> createTask(Task task) async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 500));
      final tasks = await _getMockTasks();

      final newId = tasks.isEmpty
          ? 1
          : tasks
                    .map((t) => t.id ?? 0)
                    .reduce((max, id) => id > max ? id : max) +
                1;

      final newTask = task.copyWith(
        id: newId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      tasks.add(newTask);
      await _saveMockTasks(tasks);
      return newTask;
    } else {
      final response = await http.post(
        Uri.parse('$baseUrl/tasks'),
        headers: _getHeaders(),
        body: jsonEncode(task.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Task.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(_extractErrorMessage(response.body));
      }
    }
  }

  Future<Task> getTaskById(int id) async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 300));
      final tasks = await _getMockTasks();
      final task = tasks.firstWhere(
        (t) => t.id == id,
        orElse: () => throw Exception('Task not found'),
      );
      return task;
    } else {
      final response = await http.get(
        Uri.parse('$baseUrl/tasks/$id'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        return Task.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(_extractErrorMessage(response.body));
      }
    }
  }

  Future<Task> updateTask(Task task) async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 500));
      final tasks = await _getMockTasks();
      final index = tasks.indexWhere((t) => t.id == task.id);

      if (index == -1) {
        throw Exception('Task not found');
      }

      final updatedTask = task.copyWith(updatedAt: DateTime.now());
      tasks[index] = updatedTask;
      await _saveMockTasks(tasks);
      return updatedTask;
    } else {
      final response = await http.put(
        Uri.parse('$baseUrl/tasks/${task.id}'),
        headers: _getHeaders(),
        body: jsonEncode(task.toJson()),
      );

      if (response.statusCode == 200) {
        return Task.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(_extractErrorMessage(response.body));
      }
    }
  }

  Future<void> deleteTask(int id) async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 400));
      final tasks = await _getMockTasks();
      tasks.removeWhere((t) => t.id == id);
      await _saveMockTasks(tasks);
    } else {
      final response = await http.delete(
        Uri.parse('$baseUrl/tasks/$id'),
        headers: _getHeaders(),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(_extractErrorMessage(response.body));
      }
    }
  }

  // ==========================================
  // STATISTICS
  // ==========================================

  Future<TaskStats> getTodayStats() async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 300));
      final tasks = await _getMockTasks();
      final today = DateTime.now();

      final todayTasks = tasks
          .where(
            (t) =>
                t.dueDate.year == today.year &&
                t.dueDate.month == today.month &&
                t.dueDate.day == today.day,
          )
          .toList();

      return TaskStats.fromTasks(todayTasks);
    } else {
      final response = await http.get(
        Uri.parse('$baseUrl/tasks/stats/today'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        return TaskStats.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(_extractErrorMessage(response.body));
      }
    }
  }

  Future<TaskStats> getStatusStats() async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 300));
      final tasks = await _getMockTasks();
      return TaskStats.fromTasks(tasks);
    } else {
      final response = await http.get(
        Uri.parse('$baseUrl/tasks/stats/status'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        return TaskStats.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(_extractErrorMessage(response.body));
      }
    }
  }

  // ==========================================
  // MOCK HELPER METHODS
  // ==========================================

  Future<List<Task>> _getMockTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('mock_current_user_id') ?? 1;
    final key = 'mock_tasks_user_$userId';
    final tasksStr = prefs.getStringList(key) ?? [];

    return tasksStr.map((t) => Task.fromJson(jsonDecode(t))).toList();
  }

  Future<void> _saveMockTasks(List<Task> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('mock_current_user_id') ?? 1;
    final key = 'mock_tasks_user_$userId';
    final tasksStr = tasks.map((t) => jsonEncode(t.toJson())).toList();
    await prefs.setStringList(key, tasksStr);
  }

  Future<void> _setupDefaultTasksIfNone(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'mock_tasks_user_$userId';
    if (!prefs.containsKey(key)) {
      final today = DateTime.now();
      final tomorrow = today.add(const Duration(days: 1));
      final yesterday = today.subtract(const Duration(days: 1));

      final initialTasks = [
        Task(
          id: 1,
          title: 'Design Dashboard UI',
          description:
              'Create premium dark mode screens with glow buttons and stats counters.',
          dueDate: today,
          status: TaskStatus.in_progress,
          priority: TaskPriority.high,
        ),
        Task(
          id: 2,
          title: 'Connect Spring Boot REST Endpoints',
          description:
              'Set useMock = false and configure local Spring Boot server URL.',
          dueDate: today,
          status: TaskStatus.pending,
          priority: TaskPriority.high,
        ),
        Task(
          id: 3,
          title: 'Draft Project Presentation',
          description:
              'Outline database design, REST API endpoints, and Flutter widgets.',
          dueDate: today,
          status: TaskStatus.completed,
          priority: TaskPriority.medium,
        ),
        Task(
          id: 4,
          title: 'Refactor Providers State Management',
          description:
              'Clean up ChangeNotifier and split into AuthProvider and TaskProvider.',
          dueDate: tomorrow,
          status: TaskStatus.pending,
          priority: TaskPriority.medium,
        ),
        Task(
          id: 5,
          title: 'Conduct System Level Testing',
          description:
              'Run integration test suite covering register, login, and CRUD actions.',
          dueDate: tomorrow,
          status: TaskStatus.pending,
          priority: TaskPriority.low,
        ),
        Task(
          id: 6,
          title: 'Verify H2 Database Connections',
          description: 'Review table structures using browser h2-console.',
          dueDate: yesterday,
          status: TaskStatus.completed,
          priority: TaskPriority.low,
        ),
      ];

      final tasksStr = initialTasks.map((t) => jsonEncode(t.toJson())).toList();
      await prefs.setStringList(key, tasksStr);
    }
  }

  String _extractErrorMessage(String responseBody) {
    try {
      final data = jsonDecode(responseBody);
      return data['message'] ?? data['error'] ?? 'API Operation failed';
    } catch (_) {
      return 'API Operation failed';
    }
  }
}
