import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import '../../state/models.dart';
import '../../theme.dart';
import '../shared/widgets.dart';
import 'kanban_screen.dart';

class BoardsScreen extends StatelessWidget {
  const BoardsScreen({super.key, this.onMenuPressed});
  final VoidCallback? onMenuPressed;
  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    return SafeArea(
        child: Column(children: [
      SectionTitle('Задачи',
          leading: onMenuPressed == null
              ? null
              : IconButton(
                  tooltip: 'Меню',
                  onPressed: onMenuPressed,
                  icon: const Icon(Icons.menu)),
          action: IconButton(
              tooltip: 'Создать доску',
              onPressed: () => _createBoard(context, state),
              icon: const Icon(Icons.add_box_outlined, color: brandBlue))),
      Expanded(
          child: state.boards.isEmpty
              ? const EmptyState(
                  icon: Icons.view_kanban_outlined,
                  title: 'Досок пока нет',
                  subtitle: 'Создайте первую доску задач')
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                  itemCount: state.boards.length,
                  itemBuilder: (context, index) {
                    final board = state.boards[index];
                    final members = state.members
                        .where((m) => board.memberIds.contains(m.id))
                        .toList();
                    return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                            contentPadding: const EdgeInsets.all(14),
                            leading: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                    color: board.color.withOpacity(.1),
                                    borderRadius: BorderRadius.circular(14)),
                                child: Icon(Icons.view_kanban_outlined,
                                    color: board.color)),
                            title: Text(board.title,
                                style: const TextStyle(
                                    fontSize: 17, fontWeight: FontWeight.w800)),
                            subtitle: Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Row(children: [
                                  for (final member in members.take(4))
                                    Align(
                                        widthFactor: .75,
                                        child: InitialsAvatar(member.initials,
                                            radius: 14)),
                                  if (members.length > 4)
                                    Text(' +${members.length - 4}'),
                                  const Spacer(),
                                  Text('${board.tasks.length} задач',
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant))
                                ])),
                            trailing:
                                Row(mainAxisSize: MainAxisSize.min, children: [
                              if (board.hasFullAccess(state.currentUid))
                                IconButton(
                                  tooltip: 'Удалить доску',
                                  color: Theme.of(context).colorScheme.error,
                                  icon:
                                      const Icon(Icons.delete_outline_rounded),
                                  onPressed: () =>
                                      _confirmDelete(context, state, board),
                                ),
                              const Icon(Icons.chevron_right),
                            ]),
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        KanbanScreen(board: board)))));
                  }))
    ]));
  }

  void _createBoard(BuildContext context, AppState state) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Новая доска задач'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Название'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Отмена')),
          FilledButton(
            onPressed: () async {
              if (controller.text.trim().length < 2) return;
              await state.createBoard(controller.text);
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Создать'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, AppState state, TaskBoard board) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Удалить доску?'),
        content: Text('Доска «${board.title}» и все её задачи будут удалены.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed == true) await state.deleteBoard(board);
  }
}
