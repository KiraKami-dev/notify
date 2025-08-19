import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:notify/models/todo_item.dart';
import 'package:notify/core/services/logger.dart';

class FirebaseTodo {
  static Future<void> addTodo({
    required String userId,
    required TodoItem todo,
  }) async {
    try {
      AppLogger.debug('Adding todo for user: $userId');
      AppLogger.debug('Todo data: ${todo.toString()}');
      
      final todosRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('todos')
          .doc(todo.id);

      final todoData = {
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
      };

      AppLogger.debug('Firebase todo data to be saved: $todoData');
      await todosRef.set(todoData);
      AppLogger.info('Todo successfully added to Firebase');
    } catch (e) {
      AppLogger.error('Error adding todo to Firebase', error: e);
      rethrow;
    }
  }

  static Future<void> updateTodo({
    required String userId,
    required TodoItem todo,
  }) async {
    try {
      AppLogger.debug('Updating todo for user: $userId');
      AppLogger.debug('Todo data: ${todo.toString()}');
      
      final todosRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('todos')
          .doc(todo.id);

      final todoData = {
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
      };

      AppLogger.debug('Firebase todo data to be updated: $todoData');
      await todosRef.update(todoData);
      AppLogger.info('Todo successfully updated in Firebase');
    } catch (e) {
      AppLogger.error('Error updating todo in Firebase', error: e);
      rethrow;
    }
  }

  static Future<void> deleteTodo({
    required String userId,
    required String todoId,
  }) async {
    try {
      AppLogger.debug('Deleting todo for user: $userId, todoId: $todoId');
      final todosRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('todos')
          .doc(todoId);

      await todosRef.delete();
      AppLogger.info('Todo successfully deleted from Firebase');
    } catch (e) {
      AppLogger.error('Error deleting todo from Firebase', error: e);
      rethrow;
    }
  }

  static Stream<List<TodoItem>> streamTodos(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('todos')
        .orderBy('order')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
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
          }).toList();
        });
  }
}
