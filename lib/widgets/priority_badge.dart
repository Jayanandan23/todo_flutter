import 'package:flutter/material.dart';
import '../models/task.dart';

class PriorityBadge extends StatelessWidget {
  final TaskPriority priority;

  const PriorityBadge({
    Key? key,
    required this.priority,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color labelColor;
    Color bgColor;
    String text;

    switch (priority) {
      case TaskPriority.high:
        text = 'High';
        labelColor = const Color(0xFFFF5252);
        bgColor = const Color(0xFFFF5252).withOpacity(0.12);
        break;
      case TaskPriority.medium:
        text = 'Medium';
        labelColor = const Color(0xFFFFB300);
        bgColor = const Color(0xFFFFB300).withOpacity(0.12);
        break;
      case TaskPriority.low:
        text = 'Low';
        labelColor = const Color(0xFF00B0FF);
        bgColor = const Color(0xFF00B0FF).withOpacity(0.12);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: labelColor.withOpacity(0.3), width: 1.0),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: labelColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
