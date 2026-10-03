import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../../state/models.dart';
import '../../theme.dart';
import '../shared/widgets.dart';

class KanbanScreen extends StatelessWidget {
  const KanbanScreen(
      {super.key, required this.board, this.memberNames = const {}});
  final TaskBoard board;
  final Map<String, String> memberNames;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final canEdit = board.canEdit(state.currentUid);
    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(board.title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          Text('${board.memberIds.length} участников',
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ]),
        actions: [
          IconButton(
              tooltip: 'Изменить фон доски',
              onPressed:
                  canEdit ? () => _changeBackground(context, state) : null,
              icon: const Icon(Icons.wallpaper_rounded, color: brandBlue)),
          IconButton(
              onPressed: canEdit ? () => _showAddTask(context, state) : null,
              icon: const Icon(Icons.add_circle_outline, color: brandBlue)),
        ],
      ),
      body: _BoardCanvas(
        boardId: board.id,
        state: state,
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: state.boardTasks(board.id),
          builder: (context, snapshot) {
            if (snapshot.hasError) return _BoardError(error: snapshot.error);
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final tasks = snapshot.data?.docs.map((doc) {
                  final data = doc.data();
                  return BoardTask(
                    id: doc.id,
                    title: (data['title'] as String?) ?? 'Без названия',
                    assignee: (data['assignee'] as String?) ?? 'Не назначен',
                    status: TaskStatus.values.firstWhere(
                      (value) => value.name == data['status'],
                      orElse: () => TaskStatus.todo,
                    ),
                    priority: (data['priority'] as String?) ?? 'Средний',
                    createdBy: (data['createdBy'] as String?) ?? '',
                    imageBase64: (data['imageBase64'] as String?) ?? '',
                    deadline: (data['deadline'] as Timestamp?)?.toDate(),
                    assigneeIds: List<String>.from(
                        data['assigneeIds'] ?? const <String>[]),
                    checklist: ((data['checklist'] as List?) ?? const [])
                        .whereType<Map>()
                        .map((item) => TaskChecklistItem(
                              id: item['id']?.toString() ?? '',
                              title: item['title']?.toString() ?? '',
                              done: item['done'] == true,
                            ))
                        .toList(),
                  );
                }).toList() ??
                const <BoardTask>[];
            if (tasks.isEmpty) {
              return const EmptyState(
                  icon: Icons.task_alt,
                  title: 'Задач пока нет',
                  subtitle: 'Добавьте первую задачу на эту доску');
            }
            return LayoutBuilder(builder: (context, constraints) {
              final width = constraints.maxWidth < 700
                  ? 290.0
                  : (constraints.maxWidth - 48) / 3;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: TaskStatus.values
                      .map((status) => SizedBox(
                            width: width,
                            child: _TaskColumn(
                              status: status,
                              board: board,
                              tasks: tasks,
                              state: state,
                              canEdit: canEdit,
                            ),
                          ))
                      .toList(),
                ),
              );
            });
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: canEdit ? () => _showAddTask(context, state) : null,
          icon: const Icon(Icons.add),
          label: const Text('Новая задача')),
    );
  }

  Future<void> _changeBackground(BuildContext context, AppState state) async {
    final value = await _pickTaskImage(context);
    if (value != null) await state.setBoardBackground(board, value);
  }

  Future<void> _showAddTask(BuildContext context, AppState state) async {
    final title = TextEditingController();
    final checklistItem = TextEditingController();
    final checklist = <String>[];
    DateTime? deadline;
    var imageBase64 = '';
    final availableMembers = <String, String>{
      for (final member in state.members)
        if (board.memberIds.contains(member.id)) member.id: member.name,
      ...memberNames,
    };
    final currentUid = state.currentUid;
    if (currentUid != null && !availableMembers.containsKey(currentUid)) {
      availableMembers[currentUid] =
          state.displayName.isEmpty ? state.username : state.displayName;
    }
    if (availableMembers.isEmpty) return;
    final assigneeIds = <String>{availableMembers.keys.first};
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (_, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.viewInsetsOf(sheetContext).bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                const Expanded(
                    child: Text('Новая задача',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w800))),
                IconButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: const Icon(Icons.close)),
              ]),
              const SizedBox(height: 12),
              TextField(
                  controller: title,
                  autofocus: true,
                  decoration:
                      const InputDecoration(labelText: 'Название задачи')),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.image_outlined),
                label: Text(imageBase64.isEmpty
                    ? 'Добавить изображение'
                    : 'Изображение добавлено'),
                onPressed: () async {
                  final value = await _pickTaskImage(sheetContext);
                  if (value != null) {
                    setSheetState(() => imageBase64 = value);
                  }
                },
              ),
              if (imageBase64.isNotEmpty) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(base64Decode(imageBase64),
                      height: 120, fit: BoxFit.cover),
                ),
              ],
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.event_outlined),
                label: Text(deadline == null
                    ? 'Добавить дедлайн'
                    : 'Дедлайн: ${_formatDeadline(deadline!)}'),
                onPressed: () async {
                  final value = await _pickDeadline(sheetContext, deadline);
                  if (value != null) setSheetState(() => deadline = value);
                },
              ),
              const SizedBox(height: 12),
              const Text('Исполнители',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: availableMembers.entries
                    .map((member) => FilterChip(
                          selected: assigneeIds.contains(member.key),
                          label: Text(member.value),
                          onSelected: (selected) => setSheetState(() => selected
                              ? assigneeIds.add(member.key)
                              : assigneeIds.remove(member.key)),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: checklistItem,
                    decoration:
                        const InputDecoration(labelText: 'Пункт to-do листа'),
                    onSubmitted: (_) => _appendChecklistItem(
                        checklistItem, checklist, setSheetState),
                  ),
                ),
                IconButton(
                  tooltip: 'Добавить пункт',
                  onPressed: () => _appendChecklistItem(
                      checklistItem, checklist, setSheetState),
                  icon: const Icon(Icons.playlist_add_rounded),
                ),
              ]),
              if (checklist.isNotEmpty)
                ...checklist.asMap().entries.map((entry) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.check_box_outline_blank),
                      title: Text(entry.value),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () =>
                            setSheetState(() => checklist.removeAt(entry.key)),
                      ),
                    )),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () async {
                  if (title.text.trim().isEmpty) return;
                  if (assigneeIds.isEmpty) return;
                  await state.addBoardTask(
                    board,
                    title.text,
                    assigneeIds.toList(),
                    assigneeIds.map((id) => availableMembers[id]!).toList(),
                    checklist,
                    deadline,
                    imageBase64,
                  );
                  if (sheetContext.mounted) Navigator.pop(sheetContext);
                },
                child: const Text('Добавить задачу'),
              ),
            ],
          ),
        ),
      ),
    );
    title.dispose();
    checklistItem.dispose();
  }

  void _appendChecklistItem(TextEditingController controller,
      List<String> checklist, StateSetter setSheetState) {
    final value = controller.text.trim();
    if (value.isEmpty) return;
    setSheetState(() => checklist.add(value));
    controller.clear();
  }
}

class _TaskColumn extends StatelessWidget {
  const _TaskColumn(
      {required this.status,
      required this.board,
      required this.tasks,
      required this.state,
      required this.canEdit});
  final TaskStatus status;
  final TaskBoard board;
  final List<BoardTask> tasks;
  final AppState state;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    final columnTasks = tasks.where((task) => task.status == status).toList();
    return DragTarget<BoardTask>(
      onAcceptWithDetails: canEdit
          ? (details) => state.moveBoardTask(board, details.data, status)
          : null,
      builder: (_, __, ___) => Container(
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withOpacity(
                Theme.of(context).brightness == Brightness.light ? .55 : .82),
            borderRadius: BorderRadius.circular(16)),
        child: Column(children: [
          Row(children: [
            Container(
                width: 9,
                height: 9,
                decoration:
                    BoxDecoration(color: status.color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Expanded(
                child: Text(status.label,
                    style: const TextStyle(fontWeight: FontWeight.w800))),
            Text('${columnTasks.length}',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ]),
          const SizedBox(height: 10),
          if (columnTasks.isEmpty)
            Container(
                height: 90,
                alignment: Alignment.center,
                child: Text('Перетащите сюда',
                    style: TextStyle(
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant))),
          ...columnTasks.map((task) => canEdit
              ? Draggable<BoardTask>(
                  data: task,
                  feedback: Material(
                      color: Colors.transparent,
                      child: SizedBox(
                          width: 250,
                          child: _TaskCard(
                              task: task, board: board, state: state))),
                  childWhenDragging: Opacity(
                      opacity: .35,
                      child: _TaskCard(task: task, board: board, state: state)),
                  child: MouseRegion(
                      cursor: SystemMouseCursors.grab,
                      child: _TaskCard(task: task, board: board, state: state)))
              : _TaskCard(task: task, board: board, state: state)),
        ]),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard(
      {required this.task, required this.board, required this.state});
  final BoardTask task;
  final TaskBoard board;
  final AppState state;
  @override
  Widget build(BuildContext context) => Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface.withOpacity(
          Theme.of(context).brightness == Brightness.light ? .72 : .92),
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showDetails(context),
          child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task.title,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    if (task.imageBase64.isNotEmpty) ...[
                      const SizedBox(height: 9),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(base64Decode(task.imageBase64),
                            width: double.infinity,
                            height: 120,
                            fit: BoxFit.cover),
                      ),
                    ],
                    if (task.checklist.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value:
                            task.checklist.where((item) => item.done).length /
                                task.checklist.length,
                        minHeight: 5,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${task.checklist.where((item) => item.done).length}/${task.checklist.length} выполнено',
                        style: TextStyle(
                            fontSize: 11,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ],
                    if (task.deadline != null) ...[
                      const SizedBox(height: 9),
                      Row(children: [
                        Icon(Icons.schedule_rounded,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 5),
                        Text(_formatDeadline(task.deadline!),
                            style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.primary)),
                      ]),
                    ],
                    const SizedBox(height: 12),
                    Row(children: [
                      Icon(Icons.person_outline,
                          size: 16,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Expanded(
                          child: Text(task.assignee,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant))),
                      Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8)),
                          child: Text(task.priority,
                              style: const TextStyle(fontSize: 10))),
                    ])
                  ]))));

  Future<void> _showDetails(BuildContext context) async {
    final canEdit = board.canEdit(state.currentUid);
    final canDelete = board.canDeleteTask(state.currentUid, task);
    final checklistItem = TextEditingController();
    final visibleChecklist = [...task.checklist];
    var deadline = task.deadline;
    var imageBase64 = task.imageBase64;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (_, setSheetState) => SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
                20, 20, 20, MediaQuery.viewInsetsOf(sheetContext).bottom + 20),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                Expanded(
                  child: Text(task.title,
                      style: const TextStyle(
                          fontSize: 21, fontWeight: FontWeight.w800)),
                ),
                if (canDelete)
                  IconButton(
                    tooltip: 'Удалить задачу',
                    color: Theme.of(context).colorScheme.error,
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: () async {
                      await state.deleteBoardTask(board, task);
                      if (sheetContext.mounted) Navigator.pop(sheetContext);
                    },
                  ),
                IconButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  icon: const Icon(Icons.close),
                ),
              ]),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.groups_rounded),
                title: Text(task.assignee),
                subtitle: const Text('Исполнители'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_outlined),
                title: Text(deadline == null
                    ? 'Дедлайн не задан'
                    : _formatDeadline(deadline!)),
                subtitle: const Text('Дата и время дедлайна'),
                trailing: canEdit ? const Icon(Icons.edit_outlined) : null,
                onTap: canEdit
                    ? () async {
                        final value =
                            await _pickDeadline(sheetContext, deadline);
                        if (value == null) return;
                        await state.setTaskDeadline(board, task, value);
                        setSheetState(() => deadline = value);
                      }
                    : null,
              ),
              if (imageBase64.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.memory(base64Decode(imageBase64),
                      width: double.infinity, height: 220, fit: BoxFit.cover),
                ),
              if (canEdit)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.image_outlined),
                  title: Text(imageBase64.isEmpty
                      ? 'Добавить изображение'
                      : 'Заменить изображение'),
                  onTap: () async {
                    final value = await _pickTaskImage(sheetContext);
                    if (value == null) return;
                    await state.setTaskImage(board, task, value);
                    setSheetState(() => imageBase64 = value);
                  },
                ),
              if (visibleChecklist.isNotEmpty) ...[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('To-do лист',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                ),
                const SizedBox(height: 6),
                ...visibleChecklist.map((item) => CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: item.done,
                      onChanged: canEdit
                          ? (_) async {
                              await state.toggleTaskChecklist(
                                  board, task, item);
                              final index = visibleChecklist.indexWhere(
                                  (current) => current.id == item.id);
                              if (index >= 0) {
                                setSheetState(() => visibleChecklist[index] =
                                    TaskChecklistItem(
                                        id: item.id,
                                        title: item.title,
                                        done: !item.done));
                              }
                            }
                          : null,
                      title: Text(item.title),
                    )),
              ],
              if (canEdit) ...[
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: checklistItem,
                      decoration:
                          const InputDecoration(labelText: 'Новый пункт to-do'),
                      onSubmitted: (_) async {
                        if (checklistItem.text.trim().isEmpty) return;
                        final item = await state.addTaskChecklistItem(
                            board, task, checklistItem.text);
                        if (item != null) {
                          setSheetState(() {
                            visibleChecklist.add(item);
                            checklistItem.clear();
                          });
                        }
                      },
                    ),
                  ),
                  IconButton(
                    tooltip: 'Добавить пункт',
                    icon: const Icon(Icons.playlist_add_rounded),
                    onPressed: () async {
                      if (checklistItem.text.trim().isEmpty) return;
                      final item = await state.addTaskChecklistItem(
                          board, task, checklistItem.text);
                      if (item != null) {
                        setSheetState(() {
                          visibleChecklist.add(item);
                          checklistItem.clear();
                        });
                      }
                    },
                  ),
                ]),
              ],
            ]),
          ),
        ),
      ),
    );
    checklistItem.dispose();
  }
}

class _BoardCanvas extends StatelessWidget {
  const _BoardCanvas(
      {required this.boardId, required this.state, required this.child});
  final String boardId;
  final AppState state;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: state.boardDocument(boardId),
        builder: (context, snapshot) {
          final image =
              (snapshot.data?.data()?['backgroundBase64'] as String?) ?? '';
          return Stack(fit: StackFit.expand, children: [
            if (image.isNotEmpty)
              Image.memory(base64Decode(image), fit: BoxFit.cover),
            if (image.isNotEmpty)
              ColoredBox(
                  color: Theme.of(context).colorScheme.surface.withOpacity(
                      Theme.of(context).brightness == Brightness.light
                          ? .14
                          : .32)),
            child,
          ]);
        },
      );
}

Future<DateTime?> _pickDeadline(BuildContext context, DateTime? current) async {
  final now = DateTime.now();
  final date = await showDatePicker(
    context: context,
    initialDate: current ?? now,
    firstDate: DateTime(now.year, now.month, now.day),
    lastDate: DateTime(now.year + 10),
  );
  if (date == null || !context.mounted) return null;
  final time = await showTimePicker(
    context: context,
    initialTime: current == null
        ? TimeOfDay.fromDateTime(now.add(const Duration(hours: 1)))
        : TimeOfDay.fromDateTime(current),
  );
  if (time == null) return null;
  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}

String _formatDeadline(DateTime value) {
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(value.day)}.${two(value.month)}.${value.year} '
      '${two(value.hour)}:${two(value.minute)}';
}

Future<String?> _pickTaskImage(BuildContext context) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.image,
    allowMultiple: false,
    withData: true,
  );
  final bytes = result?.files.single.bytes;
  if (bytes == null || !context.mounted) return null;
  if (bytes.length > 500 * 1024) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Изображение должно быть до 500 КБ')),
    );
    return null;
  }
  return base64Encode(bytes);
}

class _BoardError extends StatelessWidget {
  const _BoardError({required this.error});
  final Object? error;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, size: 52, color: Colors.redAccent),
            const SizedBox(height: 12),
            const Text('Не удалось загрузить задачи',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              error.toString().contains('permission-denied')
                  ? 'Опубликуйте обновлённые правила Firestore для коллекции задач.'
                  : 'Проверьте подключение и попробуйте снова.',
              textAlign: TextAlign.center,
            ),
          ]),
        ),
      );
}
