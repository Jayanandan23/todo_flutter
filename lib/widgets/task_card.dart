import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import 'glass_container.dart';
import 'priority_badge.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final Function(TaskStatus) onStatusChanged;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const TaskCard({
    Key? key,
    required this.task,
    required this.onStatusChanged,
    required this.onTap,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final isCompleted = task.status == TaskStatus.completed;
    final isInProgress = task.status == TaskStatus.in_progress;
    
    // Status color
    Color statusColor;
    IconData statusIcon;
    switch (task.status) {
      case TaskStatus.completed:
        statusColor = const Color(0xFF00E676); // Lime/Green
        statusIcon = Icons.check_circle_rounded;
        break;
      case TaskStatus.in_progress:
        statusColor = const Color(0xFFFFB300); // Amber
        statusIcon = Icons.pending_rounded;
        break;
      case TaskStatus.pending:
        statusColor = Colors.white38;
        statusIcon = Icons.radio_button_unchecked_rounded;
        break;
    }

    return Dismissible(
      key: Key('task_${task.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.delete_sweep_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: GlassContainer(
          padding: const EdgeInsets.all(14),
          color: isCompleted 
              ? Colors.white.withOpacity(0.02)
              : isInProgress 
                  ? const Color(0xFFFFB300).withOpacity(0.03)
                  : Colors.white.withOpacity(0.06),
          borderOpacity: isCompleted ? 0.05 : 0.12,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status circular button
                GestureDetector(
                  onTap: () {
                    // Cycle status: pending -> in_progress -> completed -> pending
                    TaskStatus nextStatus;
                    switch (task.status) {
                      case TaskStatus.pending:
                        nextStatus = TaskStatus.in_progress;
                        break;
                      case TaskStatus.in_progress:
                        nextStatus = TaskStatus.completed;
                        break;
                      case TaskStatus.completed:
                        nextStatus = TaskStatus.pending;
                        break;
                    }
                    onStatusChanged(nextStatus);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      statusIcon,
                      color: statusColor,
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Task content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isCompleted ? Colors.white38 : Colors.white,
                          decoration: isCompleted 
                              ? TextDecoration.lineThrough 
                              : TextDecoration.none,
                          decorationColor: Colors.white30,
                        ),
                      ),
                      if (task.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          task.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: isCompleted ? Colors.white24 : Colors.white60,
                            height: 1.3,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Due Date row
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_month_rounded,
                                size: 14,
                                color: isCompleted ? Colors.white24 : Colors.white38,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                dateFormat.format(task.dueDate),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isCompleted ? Colors.white24 : Colors.white54,
                                ),
                              ),
                            ],
                          ),
                          // Priority Badge
                          PriorityBadge(priority: task.priority),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
