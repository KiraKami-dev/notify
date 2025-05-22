import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:notify/models/todo_item.dart';

class TodoPage extends ConsumerStatefulWidget {
  const TodoPage({super.key});

  @override
  ConsumerState<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends ConsumerState<TodoPage> {
  final List<TodoItem> _todos = [];
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

  void _reorderTodo(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = _todos.removeAt(oldIndex);
      _todos.insert(newIndex, item);
      
      // Update order values
      for (int i = 0; i < _todos.length; i++) {
        _todos[i].order = i;
      }
    });
  }

  void _reorderSubtask(TodoItem todo, int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final subtask = todo.subtasks.removeAt(oldIndex);
      todo.subtasks.insert(newIndex, subtask);
      
      // Update order values
      for (int i = 0; i < todo.subtasks.length; i++) {
        todo.subtasks[i].order = i;
      }
    });
  }

  void _addTodo() {
    if (_todoController.text.isNotEmpty) {
      setState(() {
        _todos.add(TodoItem(title: _todoController.text));
        _todoController.clear();
      });
    }
  }

  void _removeTodo(String id) {
    setState(() {
      _todos.removeWhere((todo) => todo.id == id);
    });
  }

  void _toggleTodo(String id) {
    setState(() {
      final todo = _todos.firstWhere((todo) => todo.id == id);
      todo.isCompleted = !todo.isCompleted;
    });
  }

  void _toggleSubtask(String todoId, String subtaskId) {
    setState(() {
      final todo = _todos.firstWhere((todo) => todo.id == todoId);
      final subtask = todo.subtasks.firstWhere((task) => task.id == subtaskId);
      subtask.isCompleted = !subtask.isCompleted;
    });
  }

  void _addSubtask(String todoId) {
    if (_subtaskController.text.isNotEmpty) {
      setState(() {
        final todo = _todos.firstWhere((todo) => todo.id == todoId);
        todo.subtasks.add(SubTask(title: _subtaskController.text));
        _subtaskController.clear();
      });
      Navigator.pop(context);
    }
  }

  Future<void> _selectDate(BuildContext context, TodoItem todo) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: todo.dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Theme.of(context).colorScheme.primary,
                  onPrimary: Theme.of(context).colorScheme.onPrimary,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        todo.dueDate = picked;
      });
    }
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
          onSubmitted: (_) => _addSubtask(todo.id),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => _addSubtask(todo.id),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _editTodo(String id) {
    final todo = _todos.firstWhere((todo) => todo.id == id);
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
            onPressed: () {
              if (_editController.text.isNotEmpty) {
                setState(() {
                  todo.title = _editController.text;
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editSubtask(String todoId, String subtaskId) {
    final todo = _todos.firstWhere((todo) => todo.id == todoId);
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
            onPressed: () {
              if (_editController.text.isNotEmpty) {
                setState(() {
                  subtask.title = _editController.text;
                });
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
              onTap: () {
                setState(() {
                  todo.dueDate = DateTime.now();
                  todo.isRecurring = false;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.next_plan_outlined),
              title: const Text('Tomorrow'),
              onTap: () {
                setState(() {
                  todo.dueDate = DateTime.now().add(const Duration(days: 1));
                  todo.isRecurring = false;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.repeat),
              title: const Text('Recurring'),
              onTap: () {
                setState(() {
                  todo.isRecurring = true;
                  todo.dueDate = DateTime.now();
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text('Custom Date'),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withOpacity(0.05),
              theme.colorScheme.secondary.withOpacity(0.05),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        
                        const SizedBox(width: 12),
                        Text(
                          'Todo List',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _isReorderEnabled = !_isReorderEnabled;
                        });
                      },
                      icon: Icon(
                        _isReorderEnabled ? Icons.lock_open : Icons.lock_outline,
                        color: _isReorderEnabled ? theme.colorScheme.primary : theme.colorScheme.outline,
                      ),
                      tooltip: _isReorderEnabled ? 'Disable Reorder' : 'Enable Reorder',
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _todos.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.note_add_rounded,
                              size: 64,
                              color: theme.colorScheme.primary.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Add your first todo!',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap the button below to get started',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _isReorderEnabled
                        ? ReorderableListView.builder(
                            buildDefaultDragHandles: false,
                            onReorder: _reorderTodo,
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            itemCount: _todos.length,
                            itemBuilder: (context, index) {
                              final todo = _todos[index];
                              return Card(
                                key: ValueKey(todo.id),
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
                                  child: ReorderableDragStartListener(
                                    index: index,
                                    child: ExpansionTile(
                                      leading: Checkbox(
                                        value: todo.isCompleted,
                                        onChanged: (_) => _toggleTodo(todo.id),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                      title: Text(
                                        todo.title,
                                        style: TextStyle(
                                          decoration: todo.isCompleted
                                              ? TextDecoration.lineThrough
                                              : null,
                                          color: todo.isCompleted
                                              ? theme.colorScheme.outline
                                              : null,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                                    ? 'Recurring - ${DateFormat('MMM d, y').format(todo.dueDate!)}'
                                                    : DateFormat('MMM d, y').format(todo.dueDate!),
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
                                              backgroundColor: theme
                                                  .colorScheme.primary
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                            ),
                                          ],
                                        ],
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.notifications_outlined),
                                            onPressed: () {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text('Notification feature coming soon!'),
                                                  behavior: SnackBarBehavior.floating,
                                                ),
                                              );
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
                                                    color: _isSubtaskReorderEnabled ? theme.colorScheme.primary : theme.colorScheme.outline,
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
                                                                onChanged: (_) =>
                                                                    _toggleSubtask(
                                                                        todo.id,
                                                                        subtask.id),
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
                                                                controlAffinity:
                                                                    ListTileControlAffinity
                                                                        .leading,
                                                                contentPadding:
                                                                    EdgeInsets.zero,
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
                                                                _editSubtask(todo.id, subtask.id);
                                                                return false;
                                                              }
                                                            },
                                                            onDismissed: (direction) {
                                                              if (direction == DismissDirection.endToStart) {
                                                                setState(() {
                                                                  todo.subtasks.removeWhere((task) => task.id == subtask.id);
                                                                });
                                                              }
                                                            },
                                                            background: Container(
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
                                                            secondaryBackground: Container(
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
                                                            child: CheckboxListTile(
                                                              value: subtask.isCompleted,
                                                              onChanged: (_) =>
                                                                  _toggleSubtask(
                                                                      todo.id,
                                                                      subtask.id),
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
                                                              controlAffinity:
                                                                  ListTileControlAffinity
                                                                      .leading,
                                                              contentPadding:
                                                                  EdgeInsets.zero,
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
                                            onPressed: () =>
                                                _showAddSubtaskDialog(todo),
                                            icon: const Icon(Icons.add),
                                            label: const Text('Add Subtask'),
                                            style: OutlinedButton.styleFrom(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            itemCount: _todos.length,
                            itemBuilder: (context, index) {
                              final todo = _todos[index];
                              return Dismissible(
                                key: ValueKey(todo.id),
                                direction: DismissDirection.horizontal,
                                confirmDismiss: (direction) async {
                                  if (direction == DismissDirection.endToStart) {
                                    return _confirmDismiss();
                                  } else {
                                    _editTodo(todo.id);
                                    return false;
                                  }
                                },
                                onDismissed: (direction) {
                                  if (direction == DismissDirection.endToStart) {
                                    _removeTodo(todo.id);
                                  }
                                },
                                background: Container(
                                  alignment: Alignment.centerRight,
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
                                  alignment: Alignment.centerLeft,
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
                                child: Card(
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
                                        onChanged: (_) => _toggleTodo(todo.id),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                      title: Text(
                                        todo.title,
                                        style: TextStyle(
                                          decoration: todo.isCompleted
                                              ? TextDecoration.lineThrough
                                              : null,
                                          color: todo.isCompleted
                                              ? theme.colorScheme.outline
                                              : null,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                                    ? 'Recurring - ${DateFormat('MMM d, y').format(todo.dueDate!)}'
                                                    : DateFormat('MMM d, y').format(todo.dueDate!),
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
                                              backgroundColor: theme
                                                  .colorScheme.primary
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                            ),
                                          ],
                                        ],
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.notifications_outlined),
                                            onPressed: () {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text('Notification feature coming soon!'),
                                                  behavior: SnackBarBehavior.floating,
                                                ),
                                              );
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
                                                    color: _isSubtaskReorderEnabled ? theme.colorScheme.primary : theme.colorScheme.outline,
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
                                                                onChanged: (_) =>
                                                                    _toggleSubtask(
                                                                        todo.id,
                                                                        subtask.id),
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
                                                                controlAffinity:
                                                                    ListTileControlAffinity
                                                                        .leading,
                                                                contentPadding:
                                                                    EdgeInsets.zero,
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
                                                                _editSubtask(todo.id, subtask.id);
                                                                return false;
                                                              }
                                                            },
                                                            onDismissed: (direction) {
                                                              if (direction == DismissDirection.endToStart) {
                                                                setState(() {
                                                                  todo.subtasks.removeWhere((task) => task.id == subtask.id);
                                                                });
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
                                                              onChanged: (_) =>
                                                                  _toggleSubtask(
                                                                      todo.id,
                                                                      subtask.id),
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
                                                              controlAffinity:
                                                                  ListTileControlAffinity
                                                                      .leading,
                                                              contentPadding:
                                                                  EdgeInsets.zero,
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
                                            onPressed: () =>
                                                _showAddSubtaskDialog(todo),
                                            icon: const Icon(Icons.add),
                                            label: const Text('Add Subtask'),
                                            style: OutlinedButton.styleFrom(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 0,
                  color: theme.colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: theme.colorScheme.outline.withOpacity(0.2),
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
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            onSubmitted: (_) => _addTodo(),
                          ),
                        ),
                        IconButton.filled(
                          onPressed: _addTodo,
                          icon: const Icon(Icons.add),
                          style: IconButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
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
