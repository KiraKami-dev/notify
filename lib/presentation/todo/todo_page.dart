import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:notify/models/todo_item.dart';
import 'package:notify/data/firebase/firebase_todo.dart';
import 'package:notify/data/local_notification/notification_service.dart';
import 'package:notify/data/local_storage/shared_auth.dart';
import 'package:notify/presentation/widgets/connection_dialog.dart';

class TodoPage extends ConsumerStatefulWidget {
  final String userId;

  const TodoPage({
    super.key,
    required this.userId,
  });

  @override
  ConsumerState<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends ConsumerState<TodoPage> {
  final _todoController = TextEditingController();
  final _subtaskController = TextEditingController();
  final _editController = TextEditingController();
  bool _isReorderEnabled = false;
  bool _isSubtaskReorderEnabled = false;

  @override
  void dispose() {
    _todoController.dispose();
    _subtaskController.dispose();
    _editController.dispose();
    super.dispose();
  }

  Future<bool> _confirmDismiss() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Todo?'),
        content: const Text('Are you sure you want to delete this todo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _reorderTodo(
      List<TodoItem> todos, int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = todos.removeAt(oldIndex);
    todos.insert(newIndex, item);

    // Update order values
    for (int i = 0; i < todos.length; i++) {
      todos[i].order = i;
      await FirebaseTodo.updateTodo(
        userId: widget.userId,
        todo: todos[i],
      );
    }
  }

  Future<void> _reorderSubtask(
      TodoItem todo, int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final subtask = todo.subtasks.removeAt(oldIndex);
    todo.subtasks.insert(newIndex, subtask);

    // Update order values
    for (int i = 0; i < todo.subtasks.length; i++) {
      todo.subtasks[i].order = i;
    }

    await FirebaseTodo.updateTodo(
      userId: widget.userId,
      todo: todo,
    );
  }

  Future<void> _addTodo() async {
    if (_todoController.text.isNotEmpty) {
      final todo = TodoItem(title: _todoController.text);
      await FirebaseTodo.addTodo(
        userId: widget.userId,
        todo: todo,
      );

      // Show quick schedule menu for the new todo
      if (context.mounted) {
        _showQuickScheduleMenu(todo);
      }

      _todoController.clear();
    }
  }

  Future<void> _removeTodo(String id) async {
    await FirebaseTodo.deleteTodo(
      userId: widget.userId,
      todoId: id,
    );
  }

  Future<void> _toggleTodo(TodoItem todo) async {
    todo.isCompleted = !todo.isCompleted;
    await FirebaseTodo.updateTodo(
      userId: widget.userId,
      todo: todo,
    );
  }

  Future<void> _toggleSubtask(TodoItem todo, String subtaskId) async {
    final subtask = todo.subtasks.firstWhere((task) => task.id == subtaskId);
    subtask.isCompleted = !subtask.isCompleted;
    await FirebaseTodo.updateTodo(
      userId: widget.userId,
      todo: todo,
    );
  }

  Future<void> _addSubtask(TodoItem todo) async {
    if (_subtaskController.text.isNotEmpty) {
      todo.subtasks.add(SubTask(title: _subtaskController.text));
      await FirebaseTodo.updateTodo(
        userId: widget.userId,
        todo: todo,
      );
      _subtaskController.clear();
      Navigator.pop(context);
    }
  }

  Future<void> _selectDate(BuildContext context, TodoItem todo) async {
    final DateTime initialDate = todo.dueDate ?? DateTime.now();
    DateTime? selectedDateTime;
    
    await showDialog<DateTime>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => DateTimePickerDialog(
        initialDate: initialDate,
        onDateTimeSelected: (dateTime) async {
          Navigator.of(context).pop();
          selectedDateTime = dateTime;

          if (selectedDateTime != null && context.mounted) {
            todo.dueDate = selectedDateTime;
            await FirebaseTodo.updateTodo(
              userId: widget.userId,
              todo: todo,
            );

            await NotificationService.cancelTaskNotification(todo.id);
            await NotificationService.scheduleTaskNotification(
              taskId: todo.id,
              title: todo.title,
              scheduledTime: todo.dueDate!,
              description: 'Due: ${DateFormat('MMM d, y h:mm a').format(todo.dueDate!)}',
              userId: widget.userId,
            );

            setState(() {});
          }
        },
      ),
    );
  }

  void _showAddSubtaskDialog(TodoItem todo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Subtask'),
        content: TextField(
          controller: _subtaskController,
          decoration: const InputDecoration(
            hintText: 'Enter subtask...',
          ),
          onSubmitted: (_) => _addSubtask(todo),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => _addSubtask(todo),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _editTodo(TodoItem todo) async {
    _editController.text = todo.title;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Todo'),
        content: TextField(
          controller: _editController,
          decoration: const InputDecoration(
            hintText: 'Edit todo...',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (_editController.text.isNotEmpty) {
                todo.title = _editController.text;
                await FirebaseTodo.updateTodo(
                  userId: widget.userId,
                  todo: todo,
                );

                // Update notification for the edited todo
                if (todo.dueDate != null) {
                  await NotificationService.cancelTaskNotification(todo.id);
                  await NotificationService.scheduleTaskNotification(
                    taskId: todo.id,
                    title: todo.title,
                    scheduledTime: todo.dueDate!,
                    description:
                        'Due: ${DateFormat('MMM d, y').format(todo.dueDate!)}',
                    userId: widget.userId,
                  );
                }

                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _editSubtask(TodoItem todo, String subtaskId) async {
    final subtask = todo.subtasks.firstWhere((task) => task.id == subtaskId);
    _editController.text = subtask.title;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Subtask'),
        content: TextField(
          controller: _editController,
          decoration: const InputDecoration(
            hintText: 'Edit subtask...',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (_editController.text.isNotEmpty) {
                subtask.title = _editController.text;
                await FirebaseTodo.updateTodo(
                  userId: widget.userId,
                  todo: todo,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmSubtaskDismiss() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Subtask?'),
        content: const Text('Are you sure you want to delete this subtask?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  void _showQuickScheduleMenu(TodoItem todo) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.today),
              title: const Text('Today'),
              subtitle: const Text('Set reminder for today'),
              onTap: () async {
                Navigator.pop(context);
                final now = DateTime.now();
                final TimeOfDay? pickedTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(now),
                );

                if (pickedTime != null && context.mounted) {
                  final scheduledDateTime = DateTime(
                    now.year,
                    now.month,
                    now.day,
                    pickedTime.hour,
                    pickedTime.minute,
                  );

                  todo.dueDate = scheduledDateTime;
                  await FirebaseTodo.updateTodo(
                    userId: widget.userId,
                    todo: todo,
                  );

                  await NotificationService.cancelTaskNotification(todo.id);
                  await NotificationService.scheduleTaskNotification(
                    taskId: todo.id,
                    title: todo.title,
                    scheduledTime: todo.dueDate!,
                    description: 'Due: ${DateFormat('MMM d, y h:mm a').format(todo.dueDate!)}',
                    userId: widget.userId,
                  );

                  setState(() {});
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.next_plan_outlined),
              title: const Text('Tomorrow'),
              subtitle: const Text('Set reminder for tomorrow'),
              onTap: () async {
                Navigator.pop(context);
                final tomorrow = DateTime.now().add(const Duration(days: 1));
                final TimeOfDay? pickedTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(tomorrow),
                );

                if (pickedTime != null && context.mounted) {
                  final scheduledDateTime = DateTime(
                    tomorrow.year,
                    tomorrow.month,
                    tomorrow.day,
                    pickedTime.hour,
                    pickedTime.minute,
                  );

                  todo.dueDate = scheduledDateTime;
                  await FirebaseTodo.updateTodo(
                    userId: widget.userId,
                    todo: todo,
                  );

                  await NotificationService.cancelTaskNotification(todo.id);
                  await NotificationService.scheduleTaskNotification(
                    taskId: todo.id,
                    title: todo.title,
                    scheduledTime: todo.dueDate!,
                    description: 'Due: ${DateFormat('MMM d, y h:mm a').format(todo.dueDate!)}',
                    userId: widget.userId,
                  );

                  setState(() {});
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.repeat),
              title: const Text('Recurring'),
              subtitle: const Text('Set daily recurring reminder'),
              onTap: () async {
                Navigator.pop(context);
                final now = DateTime.now();
                final TimeOfDay? pickedTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(now),
                );

                if (pickedTime != null && context.mounted) {
                  final scheduledDateTime = DateTime(
                    now.year,
                    now.month,
                    now.day,
                    pickedTime.hour,
                    pickedTime.minute,
                  );

                  todo.dueDate = scheduledDateTime;
                  todo.isRecurring = true;
                  await FirebaseTodo.updateTodo(
                    userId: widget.userId,
                    todo: todo,
                  );

                  await NotificationService.cancelTaskNotification(todo.id);
                  await NotificationService.scheduleTaskNotification(
                    taskId: todo.id,
                    title: todo.title,
                    scheduledTime: todo.dueDate!,
                    description: 'Due: ${DateFormat('MMM d, y h:mm a').format(todo.dueDate!)}',
                    userId: widget.userId,
                  );

                  setState(() {});
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text('Custom Date & Time'),
              subtitle: const Text('Choose your preferred date and time'),
              onTap: () {
                Navigator.pop(context);
                _selectDate(context, todo);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showConnectionModal() {
    showDialog(
      context: context,
      builder: (context) => UserConnectionModal(
        fetch: () {
          setState(() {});
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = ref.watch(getConnectedStatusProvider);
    
    if (!isConnected) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Please connect with your partner to use todos',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _showConnectionModal,
              icon: const Icon(Icons.link),
              label: const Text('Connect Now'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.05),
              Theme.of(context).colorScheme.secondary.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Todo List',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _isReorderEnabled = !_isReorderEnabled;
                        });
                      },
                      icon: Icon(
                        _isReorderEnabled ? Icons.lock_open : Icons.lock_outline,
                        color: _isReorderEnabled
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outline,
                      ),
                      tooltip: _isReorderEnabled ? 'Disable Reorder' : 'Enable Reorder',
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<List<TodoItem>>(
                  stream: FirebaseTodo.streamTodos(widget.userId),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                      );
                    }

                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    final todos = snapshot.data!;

                    if (todos.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.note_add_rounded,
                              size: 64,
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Add your first todo!',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap the button below to get started',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return _isReorderEnabled
                        ? ReorderableListView.builder(
                            buildDefaultDragHandles: false,
                            onReorder: (oldIndex, newIndex) =>
                                _reorderTodo(todos, oldIndex, newIndex),
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            itemCount: todos.length,
                            itemBuilder: (context, index) {
                              final todo = todos[index];
                              return _buildTodoCard(todo, Theme.of(context));
                            },
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            itemCount: todos.length,
                            itemBuilder: (context, index) {
                              final todo = todos[index];
                              return Dismissible(
                                key: ValueKey(todo.id),
                                direction: DismissDirection.horizontal,
                                confirmDismiss: (direction) async {
                                  if (direction == DismissDirection.endToStart) {
                                    return _confirmDismiss();
                                  } else {
                                    _editTodo(todo);
                                    return false;
                                  }
                                },
                                onDismissed: (direction) {
                                  if (direction == DismissDirection.endToStart) {
                                    _removeTodo(todo.id);
                                  }
                                },
                                background: Container(
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.only(left: 24.0),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.edit_outlined,
                                        color: Theme.of(context).colorScheme.onPrimary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Edit',
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onPrimary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                secondaryBackground: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 24.0),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.error,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Delete',
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onError,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.delete_outline,
                                        color: Theme.of(context).colorScheme.onError,
                                      ),
                                    ],
                                  ),
                                ),
                                child: _buildTodoCard(todo, Theme.of(context)),
                              );
                            },
                          );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 0,
                  color: Theme.of(context).colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _todoController,
                            decoration: InputDecoration(
                              hintText: 'Add something sweet to do...',
                              border: InputBorder.none,
                              prefixIcon: Icon(
                                Icons.add_task,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            onSubmitted: (_) => _addTodo(),
                          ),
                        ),
                        IconButton.filled(
                          onPressed: _addTodo,
                          icon: const Icon(Icons.add),
                          style: IconButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
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

  Widget _buildTodoCard(TodoItem todo, ThemeData theme) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          leading: Checkbox(
            value: todo.isCompleted,
            onChanged: (_) => _toggleTodo(todo),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          title: Text(
            todo.title,
            style: TextStyle(
              decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
              color: todo.isCompleted ? theme.colorScheme.outline : null,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (todo.dueDate != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      todo.isRecurring ? Icons.repeat : Icons.calendar_today,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      todo.isRecurring
                          ? '${DateFormat('MMM d, y h:mm a').format(todo.dueDate!)}'
                          : DateFormat('MMM d, y h:mm a').format(todo.dueDate!),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
              if (todo.subtasks.isNotEmpty) ...[
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: todo.progress,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ],
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () async {
                  if (todo.dueDate != null) {
                    await NotificationService.showTaskReminder(
                      title: todo.title,
                      description: 'Due: ${DateFormat('MMM d, y').format(todo.dueDate!)}',
                      userId: widget.userId,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Reminder sent!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please set a due date first!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
              IconButton(
                icon: Icon(
                  todo.isRecurring ? Icons.repeat : Icons.calendar_month,
                  color: todo.isRecurring ? theme.colorScheme.primary : null,
                ),
                onPressed: () => _showQuickScheduleMenu(todo),
              ),
            ],
          ),
          children: [
            if (todo.subtasks.isNotEmpty)
              ExpansionTile(
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Subtasks (${todo.subtasks.where((task) => task.isCompleted).length}/${todo.subtasks.length})',
                      style: theme.textTheme.titleSmall,
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _isSubtaskReorderEnabled = !_isSubtaskReorderEnabled;
                        });
                      },
                      icon: Icon(
                        _isSubtaskReorderEnabled ? Icons.lock_open : Icons.lock_outline,
                        color: _isSubtaskReorderEnabled
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline,
                        size: 20,
                      ),
                      tooltip: _isSubtaskReorderEnabled ? 'Disable Reorder' : 'Enable Reorder',
                    ),
                  ],
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _isSubtaskReorderEnabled
                        ? ReorderableListView(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            onReorder: (oldIndex, newIndex) =>
                                _reorderSubtask(todo, oldIndex, newIndex),
                            children: [
                              for (final subtask in todo.subtasks)
                                ReorderableDragStartListener(
                                  key: ValueKey(subtask.id),
                                  index: todo.subtasks.indexOf(subtask),
                                  child: CheckboxListTile(
                                    value: subtask.isCompleted,
                                    onChanged: (_) => _toggleSubtask(todo, subtask.id),
                                    title: Text(
                                      subtask.title,
                                      style: TextStyle(
                                        decoration: subtask.isCompleted
                                            ? TextDecoration.lineThrough
                                            : null,
                                        color: subtask.isCompleted
                                            ? theme.colorScheme.outline
                                            : null,
                                      ),
                                    ),
                                    controlAffinity: ListTileControlAffinity.leading,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                            ],
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: todo.subtasks.length,
                            itemBuilder: (context, index) {
                              final subtask = todo.subtasks[index];
                              return Dismissible(
                                key: ValueKey(subtask.id),
                                direction: DismissDirection.horizontal,
                                confirmDismiss: (direction) async {
                                  if (direction == DismissDirection.endToStart) {
                                    return _confirmSubtaskDismiss();
                                  } else {
                                    _editSubtask(todo, subtask.id);
                                    return false;
                                  }
                                },
                                onDismissed: (direction) {
                                  if (direction == DismissDirection.endToStart) {
                                    todo.subtasks.removeWhere((task) => task.id == subtask.id);
                                    FirebaseTodo.updateTodo(
                                      userId: widget.userId,
                                      todo: todo,
                                    );
                                  }
                                },
                                background: Container(
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.only(left: 24.0),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.edit_outlined,
                                        color: theme.colorScheme.onPrimary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Edit',
                                        style: TextStyle(
                                          color: theme.colorScheme.onPrimary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                secondaryBackground: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 24.0),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.error,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Delete',
                                        style: TextStyle(
                                          color: theme.colorScheme.onError,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.delete_outline,
                                        color: theme.colorScheme.onError,
                                      ),
                                    ],
                                  ),
                                ),
                                child: CheckboxListTile(
                                  value: subtask.isCompleted,
                                  onChanged: (_) => _toggleSubtask(todo, subtask.id),
                                  title: Text(
                                    subtask.title,
                                    style: TextStyle(
                                      decoration: subtask.isCompleted
                                          ? TextDecoration.lineThrough
                                          : null,
                                      color: subtask.isCompleted
                                          ? theme.colorScheme.outline
                                          : null,
                                    ),
                                  ),
                                  controlAffinity: ListTileControlAffinity.leading,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: OutlinedButton.icon(
                onPressed: () => _showAddSubtaskDialog(todo),
                icon: const Icon(Icons.add),
                label: const Text('Add Subtask'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DateTimePickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final Function(DateTime) onDateTimeSelected;

  const DateTimePickerDialog({
    super.key,
    required this.initialDate,
    required this.onDateTimeSelected,
  });

  @override
  State<DateTimePickerDialog> createState() => _DateTimePickerDialogState();
}

class _DateTimePickerDialogState extends State<DateTimePickerDialog> {
  late DateTime selectedDate;
  late TimeOfDay selectedTime;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialDate;
    selectedTime = TimeOfDay.fromDateTime(widget.initialDate);
  }

  void _updateDateTime() {
    final DateTime newDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );
    widget.onDateTimeSelected(newDateTime);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Date and Time',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Text(
                      'Date',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() {
                            selectedDate = DateTime(
                              picked.year,
                              picked.month,
                              picked.day,
                              selectedTime.hour,
                              selectedTime.minute,
                            );
                          });
                        }
                      },
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        DateFormat('MMM d, y').format(selectedDate),
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      'Time',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (picked != null) {
                          setState(() {
                            selectedTime = picked;
                            selectedDate = DateTime(
                              selectedDate.year,
                              selectedDate.month,
                              selectedDate.day,
                              picked.hour,
                              picked.minute,
                            );
                          });
                        }
                      },
                      icon: const Icon(Icons.access_time),
                      label: Text(
                        selectedTime.format(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _updateDateTime,
                  child: const Text('Set'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
