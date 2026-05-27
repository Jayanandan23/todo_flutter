import 'task.dart';

class TaskStats {
  final int totalCount;
  final int pendingCount;
  final int inProgressCount;
  final int completedCount;

  TaskStats({
    required this.totalCount,
    required this.pendingCount,
    required this.inProgressCount,
    required this.completedCount,
  });

  factory TaskStats.empty() {
    return TaskStats(
      totalCount: 0,
      pendingCount: 0,
      inProgressCount: 0,
      completedCount: 0,
    );
  }

  factory TaskStats.fromTasks(List<Task> tasks) {
    int pending = 0;
    int inProgress = 0;
    int completed = 0;

    for (var task in tasks) {
      switch (task.status) {
        case TaskStatus.pending:
          pending++;
          break;
        case TaskStatus.in_progress:
          inProgress++;
          break;
        case TaskStatus.completed:
          completed++;
          break;
      }
    }

    return TaskStats(
      totalCount: tasks.length,
      pendingCount: pending,
      inProgressCount: inProgress,
      completedCount: completed,
    );
  }

  factory TaskStats.fromJson(Map<String, dynamic> json) {
    return TaskStats(
      totalCount: json['totalCount'] ?? 0,
      pendingCount: json['pendingCount'] ?? 0,
      inProgressCount: json['inProgressCount'] ?? 0,
      completedCount: json['completedCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalCount': totalCount,
      'pendingCount': pendingCount,
      'inProgressCount': inProgressCount,
      'completedCount': completedCount,
    };
  }
}
