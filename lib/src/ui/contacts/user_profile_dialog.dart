import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../../state/models.dart';
import '../../theme.dart';
import '../shared/widgets.dart';

Future<void> showUserProfileDialog(
  BuildContext context, {
  required String uid,
  required String fallbackName,
}) =>
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        child: UserProfilePanel(
          uid: uid,
          fallbackName: fallbackName,
          onClose: () => Navigator.pop(dialogContext),
        ),
      ),
    );

class UserProfilePanel extends StatefulWidget {
  const UserProfilePanel({
    super.key,
    required this.uid,
    required this.fallbackName,
    this.onClose,
  });
  final String uid;
  final String fallbackName;
  final VoidCallback? onClose;

  @override
  State<UserProfilePanel> createState() => _UserProfilePanelState();
}

class _UserProfilePanelState extends State<UserProfilePanel> {
  bool saved = false;
  bool blocked = false;
  bool loading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (loading) _loadState();
  }

  Future<void> _loadState() async {
    final state = AppStateScope.of(context);
    final isSaved = await state.isContact(widget.uid);
    var isBlocked = false;
    try {
      isBlocked = await state.isBlocked(widget.uid);
    } on FirebaseException {
      // Новая коллекция станет доступна после публикации firestore.rules.
    }
    if (mounted) {
      setState(() {
        saved = isSaved;
        blocked = isBlocked;
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: state.userProfile(widget.uid),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? const <String, dynamic>{};
        final name = (data['displayName'] as String?)?.trim();
        final displayName =
            name?.isNotEmpty == true ? name! : widget.fallbackName;
        final username = (data['username'] as String?)?.trim() ?? '';
        final bio = (data['bio'] as String?)?.trim() ?? '';
        final email = (data['email'] as String?)?.trim() ?? '';
        final contact = Contact(
          uid: widget.uid,
          username: username,
          name: displayName,
          avatarBase64: (data['avatarBase64'] as String?) ?? '',
          bio: bio,
          email: email,
        );
        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 510),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 12, 12, 24),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Column(children: [
                  if (widget.onClose != null)
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        tooltip: 'Закрыть',
                        onPressed: widget.onClose,
                        icon: const Icon(Icons.close),
                      ),
                    ),
                  UserAvatar(
                    name: displayName,
                    avatarBase64: contact.avatarBase64,
                    radius: 52,
                  ),
                  const SizedBox(height: 12),
                  Text(displayName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800)),
                  if (username.isNotEmpty)
                    Text('@$username',
                        style: const TextStyle(color: brandBlue)),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  if (bio.isNotEmpty)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.info_outline),
                      title: Text(bio),
                      subtitle: const Text('О себе'),
                    ),
                  if (email.isNotEmpty)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.alternate_email),
                      title: Text(email),
                      subtitle: const Text('E-mail'),
                    ),
                  const Divider(height: 28),
                  if (loading)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(),
                    )
                  else ...[
                    if (!saved && !blocked)
                      _action(
                        Icons.person_add_alt_1_rounded,
                        'Добавить контакт',
                        () async {
                          if (!await _run(() => state.addContact(contact))) {
                            return;
                          }
                          if (mounted) setState(() => saved = true);
                        },
                      ),
                    if (saved) ...[
                      _action(Icons.edit_outlined, 'Изменить контакт',
                          () => _rename(state, displayName)),
                      _action(
                        Icons.person_remove_outlined,
                        'Удалить контакт',
                        () async {
                          if (!await _run(
                              () => state.removeContact(widget.uid))) {
                            return;
                          }
                          if (mounted) setState(() => saved = false);
                        },
                      ),
                    ],
                    _action(
                      blocked ? Icons.back_hand_outlined : Icons.block,
                      blocked ? 'Разблокировать' : 'Заблокировать',
                      () async {
                        final success = await _run(() => blocked
                            ? state.unblockContact(widget.uid)
                            : state.blockContact(contact));
                        if (!success) {
                          return;
                        }
                        if (mounted) {
                          setState(() {
                            blocked = !blocked;
                            if (blocked) saved = false;
                          });
                        }
                      },
                      destructive: !blocked,
                    ),
                  ],
                ]),
              ),
            ]),
          ),
        );
      },
    );
  }

  Widget _action(IconData icon, String label, VoidCallback onTap,
      {bool destructive = false}) {
    final color = destructive ? Theme.of(context).colorScheme.error : null;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(color: color)),
      onTap: onTap,
    );
  }

  Future<void> _rename(AppState state, String currentName) async {
    final controller = TextEditingController(text: currentName);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Изменить контакт'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 50,
          decoration: const InputDecoration(labelText: 'Имя контакта'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена')),
          FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Сохранить')),
        ],
      ),
    );
    controller.dispose();
    if (name?.trim().isNotEmpty == true) {
      await _run(() => state.renameContact(widget.uid, name!));
    }
  }

  Future<bool> _run(Future<void> Function() action) async {
    try {
      await action();
      return true;
    } on FirebaseException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(error.code == 'permission-denied'
              ? 'Опубликуйте обновлённые правила Firestore'
              : 'Не удалось выполнить действие'),
        ));
      }
      return false;
    }
  }
}
