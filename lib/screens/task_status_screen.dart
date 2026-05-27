import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../widgets/task_card.dart';
import '../widgets/glass_container.dart';
import 'task_form_screen.dart';

class TaskStatusScreen extends StatefulWidget {
  final TaskStatus? initialStatus;

  const TaskStatusScreen({
    Key? key,
    this.initialStatus,
  }) : super(key: key);

  @override
  State<TaskStatusScreen> createState() => _TaskStatusScreenState();
}

class _TaskStatusScreenState extends State<TaskStatusScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    // Default initial index based on passed status: Pending = 0, In Progress = 1, Completed = 2
    int initialIndex = 0;
    if (widget.initialStatus != null) {
      initialIndex = widget.initialStatus!.index;
    }
    _tabController = TabController(length: 3, vsync: this, initialIndex: initialIndex);
    
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        // We can optionally refresh or update query when tabs change
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<TaskProvider>(context, listen: false);
      _searchCtrl.text = provider.searchQuery;
      provider.fetchTasks();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant TaskStatusScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialStatus != null) {
      _tabController.animateTo(widget.initialStatus!.index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final tasks = taskProvider.tasks;
    
    // Sort and count tasks by status *independently of status filters*
    // but applying search and priority filters so counts match the visual lists
    final pendingTasks = tasks.where((t) => t.status == TaskStatus.pending).toList();
    final inProgressTasks = tasks.where((t) => t.status == TaskStatus.in_progress).toList();
    final completedTasks = tasks.where((t) => t.status == TaskStatus.completed).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Header
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Text(
                'Tasks Directory',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

            // Search Bar Widget
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: GlassContainer(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                borderRadius: 14,
                color: Colors.white.withOpacity(0.04),
                borderOpacity: 0.1,
                child: TextField(
                  controller: _searchCtrl,
                  focusNode: _searchFocus,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search tasks...',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                    border: InputBorder.none,
                    icon: const Icon(Icons.search_rounded, color: Colors.white54),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 20),
                            onPressed: () {
                              _searchCtrl.clear();
                              taskProvider.setSearchQuery('');
                            },
                          )
                        : null,
                  ),
                  onChanged: (val) {
                    taskProvider.setSearchQuery(val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Priority Filter Chips row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  const Text(
                    'Priority:',
                    style: TextStyle(color: Colors.white38, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip(
                            label: 'All',
                            isSelected: taskProvider.filterPriority == null,
                            onSelected: () => taskProvider.setFilterPriority(null),
                          ),
                          _buildFilterChip(
                            label: 'High',
                            isSelected: taskProvider.filterPriority == TaskPriority.high,
                            selectedColor: const Color(0xFFFF5252),
                            onSelected: () => taskProvider.setFilterPriority(TaskPriority.high),
                          ),
                          _buildFilterChip(
                            label: 'Medium',
                            isSelected: taskProvider.filterPriority == TaskPriority.medium,
                            selectedColor: const Color(0xFFFFB300),
                            onSelected: () => taskProvider.setFilterPriority(TaskPriority.medium),
                          ),
                          _buildFilterChip(
                            label: 'Low',
                            isSelected: taskProvider.filterPriority == TaskPriority.low,
                            selectedColor: const Color(0xFF00B0FF),
                            onSelected: () => taskProvider.setFilterPriority(TaskPriority.low),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tab Bar
            TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF8C52FF),
              indicatorWeight: 3.0,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white38,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Pending'),
                      const SizedBox(width: 6),
                      _buildCountBadge(pendingTasks.length, Colors.white24),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Active'),
                      const SizedBox(width: 6),
                      _buildCountBadge(inProgressTasks.length, const Color(0xFFFFB300).withOpacity(0.3)),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Done'),
                      const SizedBox(width: 6),
                      _buildCountBadge(completedTasks.length, const Color(0xFF00E676).withOpacity(0.3)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tab Bar View content
            Expanded(
              child: taskProvider.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8C52FF)),
                      ),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildTaskList(pendingTasks, taskProvider, 'No pending tasks'),
                        _buildTaskList(inProgressTasks, taskProvider, 'No tasks in progress'),
                        _buildTaskList(completedTasks, taskProvider, 'No completed tasks'),
                      ],
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Set preset status based on active tab
          TaskStatus presetStatus = TaskStatus.pending;
          if (_tabController.index == 1) {
            presetStatus = TaskStatus.in_progress;
          } else if (_tabController.index == 2) {
            presetStatus = TaskStatus.completed;
          }
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TaskFormScreen(initialStatus: presetStatus),
            ),
          );
        },
        backgroundColor: const Color(0xFF8C52FF),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    Color? selectedColor,
    required VoidCallback onSelected,
  }) {
    final activeBgColor = selectedColor ?? const Color(0xFF8C52FF);
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onSelected(),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.white60,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        backgroundColor: Colors.white.withOpacity(0.04),
        selectedColor: activeBgColor.withOpacity(0.4),
        checkmarkColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: isSelected ? activeBgColor.withOpacity(0.7) : Colors.white.withOpacity(0.08),
            width: 1.0,
          ),
        ),
      ),
    );
  }

  Widget _buildCountBadge(int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        count.toString(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white70,
        ),
      ),
    );
  }

  Widget _buildTaskList(List<Task> list, TaskProvider provider, String emptyMsg) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.task_alt_rounded, size: 48, color: Colors.white12),
            const SizedBox(height: 12),
            Text(
              emptyMsg,
              style: const TextStyle(color: Colors.white38, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final task = list[index];
        return TaskCard(
          task: task,
          onStatusChanged: (newStatus) {
            final updated = task.copyWith(status: newStatus);
            provider.editTask(updated);
          },
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TaskFormScreen(task: task),
              ),
            );
          },
          onDelete: () async {
            final scaffold = ScaffoldMessenger.of(context);
            final success = await provider.removeTask(task.id!);
            if (success) {
              scaffold.showSnackBar(
                const SnackBar(
                  content: Text('Task deleted successfully'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        );
      },
    );
  }
}
