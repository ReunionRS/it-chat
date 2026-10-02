import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../../state/models.dart';
import '../../theme.dart';
import '../boards/kanban_screen.dart';
import '../shared/widgets.dart';

class GroupMembersScreen extends StatelessWidget {
  const GroupMembersScreen({super.key, required this.chatId});
  final String chatId;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: state.groupChat(chatId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Scaffold(
              body: Center(child: Text('Не удалось загрузить группу')));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        final data = snapshot.data!.data() ?? const {};
        final title = (data['title'] as String?) ?? 'Группа';
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title),
                  Text(
                      '${(data['memberIds'] as List?)?.length ?? 0} участников',
                      style: const TextStyle(fontSize: 12)),
                ],
              ),
              bottom: const TabBar(tabs: [
                Tab(icon: Icon(Icons.people_outline), text: 'Участники'),
                Tab(icon: Icon(Icons.task_alt_outlined), text: 'Задачи'),
              ]),
            ),
            body: TabBarView(children: [
              _MembersTab(chatId: chatId, data: data),
              _TasksTab(chatId: chatId, data: data),
            ]),
          ),
        );
      },
    );
  }
}

class _MembersTab extends StatelessWidget {
  const _MembersTab({required this.chatId, required this.data});
  final String chatId;
  final Map<String, dynamic> data;

  static const roles = {
    'admin': 'Администратор',
    'manager': 'Менеджер',
    'member': 'Участник',
  };

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final memberIds = List<String>.from(data['memberIds'] ?? const <String>[]);
    final memberNames =
        Map<String, dynamic>.from((data['memberNames'] as Map?) ?? const {});
    final roleMap =
        Map<String, dynamic>.from((data['roles'] as Map?) ?? const {});
    final accessMap =
        Map<String, dynamic>.from((data['access'] as Map?) ?? const {});
    final isAdmin = data['createdBy'] == state.currentUid;
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: memberIds.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final uid = memberIds[index];
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: state.userProfile(uid),
          builder: (context, profileSnapshot) {
            final profile = profileSnapshot.data?.data();
            final name = (profile?['displayName'] as String?) ??
                memberNames[uid]?.toString() ??
                'Пользователь';
            final role = roleMap[uid]?.toString() ?? 'member';
            final access = BoardAccess.values.firstWhere(
              (item) => item.name == accessMap[uid],
              orElse: () => BoardAccess.read,
            );
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 6),
              leading: UserAvatar(
                name: name,
                avatarBase64: (profile?['avatarBase64'] as String?) ?? '',
              ),
              title: Text(name,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('${roles[role] ?? role} · ${access.label}'),
              trailing: isAdmin && uid != state.currentUid
                  ? PopupMenuButton<String>(
                      tooltip: 'Изменить роль и доступ',
                      onSelected: (value) {
                        final parts = value.split(':');
                        state.updateGroupMember(
                          chatId,
                          uid,
                          parts[0],
                          BoardAccess.values
                              .firstWhere((item) => item.name == parts[1]),
                        );
                      },
                      itemBuilder: (_) => [
                        for (final roleEntry in roles.entries)
                          for (final level in BoardAccess.values)
                            PopupMenuItem(
                              value: '${roleEntry.key}:${level.name}',
                              child:
                                  Text('${roleEntry.value} · ${level.label}'),
                            ),
                      ],
                    )
                  : null,
            );
          },
        );
      },
    );
  }
}

class _TasksTab extends StatelessWidget {
  const _TasksTab({required this.chatId, required this.data});
  final String chatId;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: state.groupBoards(chatId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
              child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Не удалось загрузить доски. Проверьте правила Firestore.',
              textAlign: TextAlign.center,
            ),
          ));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;
        return Scaffold(
          body: docs.isEmpty
              ? const EmptyState(
                  icon: Icons.task_alt_outlined,
                  title: 'Досок пока нет',
                  subtitle: 'Создайте доску задач для этой группы',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final boardData = doc.data();
                    final rawAccess = Map<String, dynamic>.from(
                        (boardData['access'] as Map?) ?? const {});
                    final memberNames = Map<String, String>.fromEntries(
                      Map<String, dynamic>.from(
                              (data['memberNames'] as Map?) ?? const {})
                          .entries
                          .map((entry) =>
                              MapEntry(entry.key, entry.value.toString())),
                    );
                    final board = TaskBoard(
                      id: doc.id,
                      title: (boardData['title'] as String?) ?? 'Доска',
                      color: brandBlue,
                      memberIds: Set<String>.from(
                          boardData['memberIds'] ?? const <String>[]),
                      tasks: [],
                      accessByMember: rawAccess.map((key, value) => MapEntry(
                          key,
                          BoardAccess.values.firstWhere(
                              (item) => item.name == value,
                              orElse: () => BoardAccess.read))),
                    );
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.view_kanban_outlined,
                            color: brandBlue),
                        title: Text(board.title),
                        subtitle: Text(
                            board.accessByMember[state.currentUid]?.label ??
                                'Чтение'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => KanbanScreen(
                                  board: board, memberNames: memberNames)),
                        ),
                      ),
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _createBoard(context, state),
            icon: const Icon(Icons.add),
            label: const Text('Создать доску'),
          ),
        );
      },
    );
  }

  void _createBoard(BuildContext context, AppState state) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Доска задач группы'),
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
              await state.createGroupBoard(
                chatId,
                controller.text,
                List<String>.from(data['memberIds'] ?? const <String>[]),
                Map<String, dynamic>.from((data['access'] as Map?) ?? const {}),
              );
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Создать'),
          ),
        ],
      ),
    );
  }
}
