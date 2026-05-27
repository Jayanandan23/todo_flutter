import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../widgets/glass_container.dart';

class TaskFormScreen extends StatefulWidget {
  final Task? task;
  final DateTime? initialDate;
  final TaskStatus? initialStatus;

  const TaskFormScreen({
    Key? key,
    this.task,
    this.initialDate,
    this.initialStatus,
  }) : super(key: key);

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late DateTime _selectedDate;
  late TaskStatus _selectedStatus;
  late TaskPriority _selectedPriority;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.task?.title ?? '');
    _descCtrl = TextEditingController(text: widget.task?.description ?? '');
    _selectedDate = widget.task?.dueDate ?? widget.initialDate ?? DateTime.now();
    _selectedStatus = widget.task?.status ?? widget.initialStatus ?? TaskStatus.pending;
    _selectedPriority = widget.task?.priority ?? TaskPriority.medium;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _presentDatePicker() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF8C52FF),
              onPrimary: Colors.white,
              surface: Color(0xFF151026),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF1C1337),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  void _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    
    final taskData = Task(
      id: widget.task?.id,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      dueDate: _selectedDate,
      status: _selectedStatus,
      priority: _selectedPriority,
      createdAt: widget.task?.createdAt,
    );

    bool success;
    if (_isEditing) {
      success = await taskProvider.editTask(taskData);
    } else {
      success = await taskProvider.addTask(taskData);
    }

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Task updated' : 'Task created'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(taskProvider.errorMessage ?? 'Operation failed'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _deleteTask() async {
    if (!_isEditing) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1337),
        title: const Text('Delete Task', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to delete this task?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      final success = await taskProvider.removeTask(widget.task!.id!);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Task deleted successfully'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(taskProvider.errorMessage ?? 'Deletion failed'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final formattedDate = DateFormat('EEE, MMM dd, yyyy').format(_selectedDate);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F0C1B),
              Color(0xFF151026),
              Color(0xFF1C1337),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom Header Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Text(
                      _isEditing ? 'Edit Task' : 'New Task',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    _isEditing
                        ? IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                            onPressed: _deleteTask,
                          )
                        : const SizedBox(width: 48), // Keep title centered
                  ],
                ),
              ),

              // Form inputs
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Task Title Field
                        const Text('Title', style: TextStyle(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _titleCtrl,
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                          decoration: InputDecoration(
                            hintText: 'What needs to be done?',
                            hintStyle: const TextStyle(color: Colors.white24),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.04),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF8C52FF)),
                              borderRadius: BorderRadius.all(Radius.circular(12)),
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Please enter a task title';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Task Description Field
                        const Text('Description', style: TextStyle(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _descCtrl,
                          maxLines: 4,
                          style: const TextStyle(color: Colors.white, fontSize: 15),
                          decoration: InputDecoration(
                            hintText: 'Add details here...',
                            hintStyle: const TextStyle(color: Colors.white24),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.04),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF8C52FF)),
                              borderRadius: BorderRadius.all(Radius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Due Date Picker Field
                        const Text('Due Date', style: TextStyle(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _presentDatePicker,
                          borderRadius: BorderRadius.circular(12),
                          child: GlassContainer(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            borderRadius: 12,
                            color: Colors.white.withOpacity(0.04),
                            borderOpacity: 0.08,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_month_rounded, color: Color(0xFF8C52FF)),
                                    const SizedBox(width: 12),
                                    Text(
                                      formattedDate,
                                      style: const TextStyle(color: Colors.white, fontSize: 15),
                                    ),
                                  ],
                                ),
                                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 16),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Priority Selector
                        const Text('Priority Level', style: TextStyle(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Row(
                          children: TaskPriority.values.map((priority) {
                            final isSelected = _selectedPriority == priority;
                            Color activeColor;
                            String label;
                            switch (priority) {
                              case TaskPriority.high:
                                label = 'High';
                                activeColor = const Color(0xFFFF5252);
                                break;
                              case TaskPriority.medium:
                                label = 'Medium';
                                activeColor = const Color(0xFFFFB300);
                                break;
                              case TaskPriority.low:
                                label = 'Low';
                                activeColor = const Color(0xFF00B0FF);
                                break;
                            }

                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                child: ChoiceChip(
                                  label: Text(label),
                                  selected: isSelected,
                                  onSelected: (_) {
                                    setState(() {
                                      _selectedPriority = priority;
                                    });
                                  },
                                  labelStyle: TextStyle(
                                    color: isSelected ? Colors.white : Colors.white60,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 13,
                                  ),
                                  backgroundColor: Colors.white.withOpacity(0.03),
                                  selectedColor: activeColor.withOpacity(0.35),
                                  checkmarkColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    side: BorderSide(
                                      color: isSelected 
                                          ? activeColor.withOpacity(0.7) 
                                          : Colors.white.withOpacity(0.08),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),

                        // Status Selector
                        const Text('Task Status', style: TextStyle(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Row(
                          children: TaskStatus.values.map((status) {
                            final isSelected = _selectedStatus == status;
                            Color activeColor;
                            String label;
                            switch (status) {
                              case TaskStatus.completed:
                                label = 'Completed';
                                activeColor = const Color(0xFF00E676);
                                break;
                              case TaskStatus.in_progress:
                                label = 'Active';
                                activeColor = const Color(0xFFFFB300);
                                break;
                              case TaskStatus.pending:
                                label = 'Pending';
                                activeColor = Colors.white70;
                                break;
                            }

                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                child: ChoiceChip(
                                  label: Text(label),
                                  selected: isSelected,
                                  onSelected: (_) {
                                    setState(() {
                                      _selectedStatus = status;
                                    });
                                  },
                                  labelStyle: TextStyle(
                                    color: isSelected ? Colors.white : Colors.white60,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 12,
                                  ),
                                  backgroundColor: Colors.white.withOpacity(0.03),
                                  selectedColor: activeColor.withOpacity(0.25),
                                  checkmarkColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    side: BorderSide(
                                      color: isSelected 
                                          ? activeColor.withOpacity(0.6) 
                                          : Colors.white.withOpacity(0.08),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 40),

                        // Save Button
                        ElevatedButton(
                          onPressed: taskProvider.isLoading ? null : _saveTask,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            shadowColor: Colors.transparent,
                          ).copyWith(
                            elevation: WidgetStateProperty.all(0),
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF8C52FF), Color(0xFF6200EE)],
                                begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Container(
                              alignment: Alignment.center,
                              constraints: const BoxConstraints(minHeight: 52),
                              child: taskProvider.isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Text(
                                      _isEditing ? 'Save Changes' : 'Create Task',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
