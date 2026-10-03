import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../../state/models.dart';
import '../../theme.dart';
import '../boards/kanban_screen.dart';
import '../contacts/user_profile_dialog.dart';
import '../shared/widgets.dart';

class GroupMembersScreen extends StatefulWidget {
  const GroupMembersScreen({
    super.key,
    required this.chatId,
    this.embedded = false,
    this.onClose,
  });
  final String chatId;
  final bool embedded;
  final VoidCallback? onClose;

  @override
  State<GroupMembersScreen> createState() => _GroupMembersScreenState();
}

class _GroupMembersScreenState extends State<GroupMembersScreen> {
  int section = 0;
  bool uploadingAvatar = false;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: state.groupChat(widget.chatId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          const error = Center(child: Text('Не удалось загрузить группу'));
          return widget.embedded ? error : const Scaffold(body: error);
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          const loading = Center(child: CircularProgressIndicator());
          return widget.embedded ? loading : const Scaffold(body: loading);
        }
        final data = snapshot.data!.data() ?? const {};
        final title = (data['title'] as String?) ?? 'Группа';
        final isAdmin = data['createdBy'] == state.currentUid;
        final content = Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Column(children: [
              _GroupHeader(
                title: title,
                memberCount: (data['memberIds'] as List?)?.length ?? 0,
                avatarBase64: (data['avatarBase64'] as String?) ?? '',
                onClose: widget.onClose,
                selected: section,
                canEditAvatar: isAdmin && !uploadingAvatar,
                onAvatar: () => _pickAvatar(state),
                onSection: (value) => setState(() => section = value),
              ),
              Expanded(
                child: IndexedStack(index: section, children: [
                  _MembersTab(chatId: widget.chatId, data: data),
                  _MembersTab(
                    chatId: widget.chatId,
                    data: data,
                    rolesOnly: true,
                  ),
                  _TasksTab(chatId: widget.chatId, data: data),
                ]),
              ),
            ]),
          ),
        );
        if (widget.embedded) return Material(child: content);
        return Scaffold(
          appBar: AppBar(title: const Text('Информация')),
          body: content,
        );
      },
    );
  }

  Future<void> _pickAvatar(AppState state) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    final bytes = result?.files.single.bytes;
    if (!mounted || bytes == null) return;
    if (bytes.length > 500 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Изображение должно быть до 500 КБ')),
      );
      return;
    }
    setState(() => uploadingAvatar = true);
    try {
      await state.updateGroupAvatar(widget.chatId, base64Encode(bytes));
    } on FirebaseException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось сохранить: ${error.code}')),
        );
      }
    } finally {
      if (mounted) setState(() => uploadingAvatar = false);
    }
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({
    required this.title,
    required this.memberCount,
    required this.avatarBase64,
    this.onClose,
    required this.selected,
    required this.canEditAvatar,
    required this.onAvatar,
    required this.onSection,
  });

  final String title;
  final int memberCount;
  final String avatarBase64;
  final VoidCallback? onClose;
  final int selected;
  final bool canEditAvatar;
  final VoidCallback onAvatar;
  final ValueChanged<int> onSection;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: scheme.surfaceContainerLow,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      child: Column(children: [
        if (onClose != null)
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              tooltip: 'Закрыть',
              onPressed: onClose,
              icon: const Icon(Icons.close),
            ),
          ),
        Stack(clipBehavior: Clip.none, children: [
          UserAvatar(name: title, avatarBase64: avatarBase64, radius: 48),
          if (canEditAvatar)
            Positioned(
              right: -8,
              bottom: -6,
              child: IconButton.filled(
                tooltip: 'Сменить аватар группы',
                onPressed: onAvatar,
                icon: const Icon(Icons.photo_camera_outlined, size: 19),
              ),
            ),
        ]),
        const SizedBox(height: 12),
        Text(title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 3),
        Text('$memberCount участников',
            style: TextStyle(color: scheme.onSurfaceVariant)),
        const SizedBox(height: 18),
        Row(children: [
          Expanded(
            child: _HeaderAction(
              icon: Icons.people_rounded,
              label: 'Участники',
              selected: selected == 0,
              onTap: () => onSection(0),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _HeaderAction(
              icon: Icons.admin_panel_settings_outlined,
              label: 'Роли',
              selected: selected == 1,
              onTap: () => onSection(1),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _HeaderAction(
              icon: Icons.task_alt_rounded,
              label: 'Задачи',
              selected: selected == 2,
              onTap: () => onSection(2),
            ),
          ),
        ]),
      ]),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction(
      {required this.icon,
      required this.label,
      required this.selected,
      required this.onTap});
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: selected
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Column(children: [
              Icon(icon),
              const SizedBox(height: 5),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12)),
            ]),
          ),
        ),
      );
}

class _MembersTab extends StatelessWidget {
  const _MembersTab({
    required this.chatId,
    required this.data,
    this.rolesOnly = false,
  });
  final String chatId;
  final Map<String, dynamic> data;
  final bool rolesOnly;

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
            final isCreator = data['createdBy'] == uid;
            final role =
                roleMap[uid]?.toString() ?? (isCreator ? 'admin' : 'member');
            final access = BoardAccess.values.firstWhere(
              (item) => item.name == accessMap[uid],
              orElse: () => isCreator ? BoardAccess.full : BoardAccess.read,
            );
            return ListTile(
              onTap: () => showUserProfileDialog(
                context,
                uid: uid,
                fallbackName: name,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 6),
              leading: UserAvatar(
                name: name,
                avatarBase64: (profile?['avatarBase64'] as String?) ?? '',
              ),
              title: Text(name,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('${roles[role] ?? role} · ${access.label}'),
              trailing: rolesOnly && isAdmin && uid != state.currentUid
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
                  : rolesOnly
                      ? const Icon(Icons.chevron_right)
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
    return StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
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
        final docs = snapshot.data!;
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
              try {
                await state.createGroupBoard(
                  chatId,
                  controller.text,
                  List<String>.from(data['memberIds'] ?? const <String>[]),
                  Map<String, dynamic>.from(
                      (data['access'] as Map?) ?? const {}),
                );
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              } on FirebaseException catch (error) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text('Не удалось создать доску: ${error.code}'),
                    ),
                  );
                }
              }
            },
            child: const Text('Создать'),
          ),
        ],
      ),
    );
  }
}
