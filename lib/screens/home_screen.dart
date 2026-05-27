import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../widgets/stats_card.dart';
import '../widgets/task_card.dart';
import '../widgets/glass_container.dart';
import 'task_form_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(int, TaskStatus?)? onNavigateToTab;

  const HomeScreen({
    Key? key,
    this.onNavigateToTab,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TaskProvider>(context, listen: false).refreshAll();
    });
  }

  Future<void> _onRefresh() async {
    await Provider.of<TaskProvider>(context, listen: false).refreshAll();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context);
    
    final username = authProvider.currentUser?.username ?? 'User';
    final today = DateTime.now();
    final todayStr = DateFormat('EEEE, d MMMM').format(today);
    
    // Extract today's tasks
    final todayTasks = taskProvider.tasks.where((t) => 
      t.dueDate.year == today.year &&
      t.dueDate.month == today.month &&
      t.dueDate.day == today.day
    ).toList();

    // Re-calculate statistics for today
    int total = todayTasks.length;
    int pending = todayTasks.where((t) => t.status == TaskStatus.pending).length;
    int inProgress = todayTasks.where((t) => t.status == TaskStatus.in_progress).length;
    int completed = todayTasks.where((t) => t.status == TaskStatus.completed).length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: const Color(0xFF8C52FF),
          backgroundColor: const Color(0xFF151026),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Area
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, $username',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          todayStr,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 24),
                      tooltip: 'Logout',
                      onPressed: () {
                        // Confirm logout
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: const Color(0xFF1C1337),
                            title: const Text('Logout', style: TextStyle(color: Colors.white)),
                            content: const Text('Are you sure you want to sign out?', style: TextStyle(color: Colors.white70)),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  authProvider.logout();
                                  Navigator.pushReplacementNamed(context, '/login');
                                },
                                child: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Statistics Title
                const Text(
                  "Today's Overview",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),

                // Statistics Cards
                Row(
                  children: [
                    StatsCard(
                      title: 'Pending',
                      count: pending.toString(),
                      icon: Icons.radio_button_unchecked_rounded,
                      color: Colors.white60,
                      onTap: () => widget.onNavigateToTab?.call(1, TaskStatus.pending),
                    ),
                    const SizedBox(width: 10),
                    StatsCard(
                      title: 'In Progress',
                      count: inProgress.toString(),
                      icon: Icons.pending_rounded,
                      color: const Color(0xFFFFB300),
                      onTap: () => widget.onNavigateToTab?.call(1, TaskStatus.in_progress),
                    ),
                    const SizedBox(width: 10),
                    StatsCard(
                      title: 'Completed',
                      count: completed.toString(),
                      icon: Icons.check_circle_rounded,
                      color: const Color(0xFF00E676),
                      onTap: () => widget.onNavigateToTab?.call(1, TaskStatus.completed),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // "Today's Tasks" header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          "Today's Tasks",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8C52FF).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            total.toString(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFC0A2FF),
                            ),
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () => widget.onNavigateToTab?.call(1, null),
                      child: const Text(
                        'View All',
                        style: TextStyle(color: Color(0xFF8C52FF)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Today's Task List
                if (taskProvider.isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40.0),
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8C52FF)),
                      ),
                    ),
                  )
                else if (todayTasks.isEmpty)
                  GlassContainer(
                    padding: const EdgeInsets.all(24),
                    borderRadius: 16,
                    color: Colors.white.withOpacity(0.02),
                    borderOpacity: 0.08,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(
                          Icons.playlist_add_check_rounded,
                          size: 48,
                          color: Colors.white30,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "All caught up for today!",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Create a task or take a break.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white38,
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const TaskFormScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Add Today\'s Task'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF8C52FF),
                            side: const BorderSide(color: Color(0xFF8C52FF)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: todayTasks.length,
                    itemBuilder: (context, index) {
                      final task = todayTasks[index];
                      return TaskCard(
                        task: task,
                        onStatusChanged: (newStatus) {
                          final updated = task.copyWith(status: newStatus);
                          taskProvider.editTask(updated);
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
                          final success = await taskProvider.removeTask(task.id!);
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
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
