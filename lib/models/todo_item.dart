import 'package:uuid/uuid.dart';

class TodoItem {
  final String id;
  String title;
  bool isCompleted;
  DateTime? dueDate;
  List<SubTask> subtasks;
  int order;
  bool isRecurring;

  TodoItem({
    String? id,
    required this.title,
    this.isCompleted = false,
    this.dueDate,
    List<SubTask>? subtasks,
    int? order,
    this.isRecurring = false,
  })  : id = id ?? const Uuid().v4(),
        subtasks = subtasks ?? [],
        order = order ?? DateTime.now().millisecondsSinceEpoch;

  double get progress {
    if (subtasks.isEmpty) return isCompleted ? 1.0 : 0.0;
    final completedSubtasks = subtasks.where((task) => task.isCompleted).length;
    return completedSubtasks / subtasks.length;
  }

  @override
  String toString() {
    return 'TodoItem(id: $id, title: $title, isCompleted: $isCompleted, dueDate: $dueDate, isRecurring: $isRecurring)';
  }
}

class SubTask {
  final String id;
  String title;
  bool isCompleted;
  int order;

  SubTask({
    String? id,
    required this.title,
    this.isCompleted = false,
    int? order,
  })  : id = id ?? const Uuid().v4(),
        order = order ?? DateTime.now().millisecondsSinceEpoch;
}
