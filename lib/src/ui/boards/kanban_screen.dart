import 'package:cloud_firestore/cloud_firestore.dart';
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
              style: const TextStyle(fontSize: 12, color: Colors.black45)),
        ]),
        actions: [
          IconButton(
              onPressed: canEdit ? () => _showAddTask(context, state) : null,
              icon: const Icon(Icons.add_circle_outline, color: brandBlue)),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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
      floatingActionButton: FloatingActionButton.extended(
          onPressed: canEdit ? () => _showAddTask(context, state) : null,
          icon: const Icon(Icons.add),
          label: const Text('Новая задача')),
    );
  }

  void _showAddTask(BuildContext context, AppState state) {
    final title = TextEditingController();
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
    var assigneeId = availableMembers.keys.first;
    showModalBottomSheet(
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
              DropdownButtonFormField<String>(
                value: assigneeId,
                decoration: const InputDecoration(labelText: 'Исполнитель'),
                items: availableMembers.entries
                    .map((member) => DropdownMenuItem(
                        value: member.key, child: Text(member.value)))
                    .toList(),
                onChanged: (value) => setSheetState(() => assigneeId = value!),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () async {
                  if (title.text.trim().isEmpty) return;
                  await state.addBoardTask(board, title.text, assigneeId,
                      availableMembers[assigneeId]!);
                  if (sheetContext.mounted) Navigator.pop(sheetContext);
                },
                child: const Text('Добавить задачу'),
              ),
            ],
          ),
        ),
      ),
    );
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
            color: status.color.withOpacity(.06),
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
                style: const TextStyle(color: Colors.black45)),
          ]),
          const SizedBox(height: 10),
          if (columnTasks.isEmpty)
            Container(
                height: 90,
                alignment: Alignment.center,
                child: const Text('Перетащите сюда',
                    style: TextStyle(color: Colors.black38))),
          ...columnTasks.map((task) => canEdit
              ? LongPressDraggable<BoardTask>(
                  data: task,
                  feedback: Material(
                      color: Colors.transparent,
                      child: SizedBox(width: 250, child: _TaskCard(task))),
                  childWhenDragging:
                      Opacity(opacity: .35, child: _TaskCard(task)),
                  child: _TaskCard(task))
              : _TaskCard(task)),
        ]),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard(this.task);
  final BoardTask task;
  @override
  Widget build(BuildContext context) => Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
          padding: const EdgeInsets.all(12),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(task.title,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Row(children: [
              const Icon(Icons.person_outline, size: 16, color: Colors.black45),
              const SizedBox(width: 4),
              Expanded(
                  child: Text(task.assignee,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.black54))),
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                      color: canvas, borderRadius: BorderRadius.circular(8)),
                  child: Text(task.priority,
                      style: const TextStyle(fontSize: 10))),
            ])
          ])));
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
