enum TaskStatus {
  pending,
  in_progress,
  completed,
}

enum TaskPriority {
  low,
  medium,
  high,
}

class Task {
  final int? id;
  final String title;
  final String description;
  final DateTime dueDate;
  final TaskStatus status;
  final TaskPriority priority;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Task({
    this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    this.status = TaskStatus.pending,
    this.priority = TaskPriority.medium,
    this.createdAt,
    this.updatedAt,
  });

  // Convert a String to TaskStatus
  static TaskStatus parseStatus(String statusStr) {
    switch (statusStr.toLowerCase()) {
      case 'in_progress':
      case 'inprogress':
      case 'in-progress':
        return TaskStatus.in_progress;
      case 'completed':
      case 'done':
        return TaskStatus.completed;
      case 'pending':
      default:
        return TaskStatus.pending;
    }
  }

  // Convert a TaskStatus to String formatted for Spring Boot Backend
  static String statusToString(TaskStatus status) {
    switch (status) {
      case TaskStatus.in_progress:
        return 'IN_PROGRESS';
      case TaskStatus.completed:
        return 'COMPLETED';
      case TaskStatus.pending:
      default:
        return 'PENDING';
    }
  }

  // Convert a String to TaskPriority
  static TaskPriority parsePriority(String priorityStr) {
    switch (priorityStr.toLowerCase()) {
      case 'high':
        return TaskPriority.high;
      case 'low':
        return TaskPriority.low;
      case 'medium':
      default:
        return TaskPriority.medium;
    }
  }

  // Convert a TaskPriority to String formatted for Spring Boot Backend
  static String priorityToString(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return 'HIGH';
      case TaskPriority.low:
        return 'LOW';
      case TaskPriority.medium:
      default:
        return 'MEDIUM';
    }
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      dueDate: json['dueDate'] != null 
          ? DateTime.parse(json['dueDate']) 
          : DateTime.now(),
      status: parseStatus(json['status'] ?? 'PENDING'),
      priority: parsePriority(json['priority'] ?? 'MEDIUM'),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      // Format as YYYY-MM-DD
      'dueDate': "${dueDate.year.toString().padLeft(4, '0')}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')}",
      'status': statusToString(status),
      'priority': priorityToString(priority),
    };
  }

  Task copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? dueDate,
    TaskStatus? status,
    TaskPriority? priority,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
