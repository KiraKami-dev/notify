import 'package:uuid/uuid.dart';

class TodoItem {
  final String id;
  String title;
  bool isCompleted;
  DateTime? dueDate;
  List<SubTask> subtasks;
  bool isImportant;

  TodoItem({
    String? id,
    required this.title,
    this.isCompleted = false,
    this.dueDate,
    List<SubTask>? subtasks,
    this.isImportant = false,
  })  : id = id ?? const Uuid().v4(),
        subtasks = subtasks ?? [];

  double get progress {
    if (subtasks.isEmpty) return isCompleted ? 1.0 : 0.0;
    final completedSubtasks = subtasks.where((task) => task.isCompleted).length;
    return completedSubtasks / subtasks.length;
  }
}

class SubTask {
  final String id;
  String title;
  bool isCompleted;

  SubTask({
    String? id,
    required this.title,
    this.isCompleted = false,
  }) : id = id ?? const Uuid().v4();
} 