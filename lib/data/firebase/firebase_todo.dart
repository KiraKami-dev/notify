import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:notify/models/todo_item.dart';

class FirebaseTodo {
  static Future<void> addTodo({
    required String userId,
    required TodoItem todo,
  }) async {
    final todosRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('todos')
        .doc(todo.id);

    await todosRef.set({
      'id': todo.id,
      'title': todo.title,
      'isCompleted': todo.isCompleted,
      'dueDate': todo.dueDate != null ? Timestamp.fromDate(todo.dueDate!) : null,
      'order': todo.order,
      'isRecurring': todo.isRecurring,
      'subtasks': todo.subtasks.map((subtask) => {
        'id': subtask.id,
        'title': subtask.title,
        'isCompleted': subtask.isCompleted,
        'order': subtask.order,
      }).toList(),
    });
  }

  static Future<void> updateTodo({
    required String userId,
    required TodoItem todo,
  }) async {
    final todosRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('todos')
        .doc(todo.id);

    await todosRef.update({
      'title': todo.title,
      'isCompleted': todo.isCompleted,
      'dueDate': todo.dueDate != null ? Timestamp.fromDate(todo.dueDate!) : null,
      'order': todo.order,
      'isRecurring': todo.isRecurring,
      'subtasks': todo.subtasks.map((subtask) => {
        'id': subtask.id,
        'title': subtask.title,
        'isCompleted': subtask.isCompleted,
        'order': subtask.order,
      }).toList(),
    });
  }

  static Future<void> deleteTodo({
    required String userId,
    required String todoId,
  }) async {
    final todosRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('todos')
        .doc(todoId);

    await todosRef.delete();
  }

  static Stream<List<TodoItem>> streamTodos(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('todos')
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return TodoItem(
                id: data['id'] as String,
                title: data['title'] as String,
                isCompleted: data['isCompleted'] as bool,
                dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
                order: data['order'] as int,
                isRecurring: data['isRecurring'] as bool,
                subtasks: (data['subtasks'] as List<dynamic>).map((subtask) => SubTask(
                  id: subtask['id'] as String,
                  title: subtask['title'] as String,
                  isCompleted: subtask['isCompleted'] as bool,
                  order: subtask['order'] as int,
                )).toList(),
              );
            }).toList());
  }
}
