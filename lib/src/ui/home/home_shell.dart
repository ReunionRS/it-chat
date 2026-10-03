import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../../state/models.dart';
import '../../theme.dart';
import '../boards/boards_screen.dart';
import '../chats/chats_screen.dart';
import '../chats/conversation_screen.dart';
import '../chats/group_members_screen.dart';
import '../contacts/contacts_screen.dart';
import '../contacts/user_profile_dialog.dart';
import '../profile/profile_screen.dart';
import '../settings/settings_screen.dart';
import '../shared/widgets.dart';
import '../../../l10n/generated/app_localizations.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  int index = 0;
  String? selectedChat;
  String? selectedDirectChatId;
  String? selectedPeerUid;
  bool showContactInfo = true;

  void selectPage(int value) {
    Navigator.of(context).maybePop();
    setState(() => index = value);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, size) {
          final desktop = size.maxWidth >= 900;
          final pages = <Widget>[
            desktop ? _desktopChats() : _mobileChats(),
            ContactsScreen(
              onMenuPressed: () => scaffoldKey.currentState?.openDrawer(),
              onChat: (contact) => openContact(contact, desktop),
            ),
            BoardsScreen(
                onMenuPressed: () => scaffoldKey.currentState?.openDrawer()),
            SettingsScreen(
                onMenuPressed: () => scaffoldKey.currentState?.openDrawer()),
            ProfileScreen(onBack: () => selectPage(0)),
          ];
          return Scaffold(
            key: scaffoldKey,
            drawer: _AppMenu(
              selectedIndex: index,
              onSelected: selectPage,
              onCreateGroup: createGroup,
            ),
            body: IndexedStack(index: index, children: pages),
          );
        },
      );

  Widget _mobileChats() => ChatsScreen(
        onMenuPressed: () => scaffoldKey.currentState?.openDrawer(),
      );

  Future<void> openContact(Contact contact, bool desktop) async {
    final state = AppStateScope.of(context);
    try {
      final chatId = await state.createDirectChat(contact);
      if (!mounted) return;
      if (desktop) {
        setState(() {
          index = 0;
          selectedChat = contact.name;
          selectedDirectChatId = chatId;
          selectedPeerUid = contact.uid;
          showContactInfo = true;
        });
      } else {
        await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ConversationScreen(
            title: contact.name,
            directChatId: chatId,
            peerUid: contact.uid,
          ),
        ));
      }
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.code == 'permission-denied'
            ? 'Опубликуйте обновлённые правила Firestore'
            : 'Не удалось открыть чат'),
      ));
    }
  }

  Future<void> createGroup() async {
    Navigator.of(context).maybePop();
    final state = AppStateScope.of(context);
    final title = TextEditingController();
    final selected = <String>{};
    final contactsFuture = state.loadContacts();
    final result = await showDialog<(String, List<Contact>)>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Создать группу'),
          content: SizedBox(
            width: 440,
            height: 430,
            child: Column(children: [
              TextField(
                controller: title,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Название группы'),
              ),
              const SizedBox(height: 14),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Добавьте участников',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: FutureBuilder<List<Contact>>(
                  future: contactsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text(
                          'Не удалось загрузить контакты',
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final contacts = snapshot.data!;
                    if (contacts.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.person_add_alt_1_outlined,
                                size: 42),
                            const SizedBox(height: 12),
                            const Text(
                              'Сначала добавьте пользователей\nв контакты',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(dialogContext);
                                setState(() => index = 1);
                              },
                              child: const Text('Перейти в контакты'),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: contacts.length,
                      itemBuilder: (context, i) {
                        final contact = contacts[i];
                        return CheckboxListTile(
                          value: selected.contains(contact.uid),
                          onChanged: (value) => setDialogState(() =>
                              value == true
                                  ? selected.add(contact.uid)
                                  : selected.remove(contact.uid)),
                          secondary: UserAvatar(
                            name: contact.name,
                            avatarBase64: contact.avatarBase64,
                          ),
                          title: Text(contact.name),
                          subtitle: Text('@${contact.username}'),
                        );
                      },
                    );
                  },
                ),
              ),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Отмена')),
            FilledButton(
              onPressed: () async {
                final contacts = await contactsFuture;
                if (!dialogContext.mounted ||
                    title.text.trim().length < 2 ||
                    selected.isEmpty) {
                  return;
                }
                Navigator.pop(
                  dialogContext,
                  (
                    title.text.trim(),
                    contacts
                        .where((contact) => selected.contains(contact.uid))
                        .toList()
                  ),
                );
              },
              child: const Text('Создать'),
            ),
          ],
        ),
      ),
    );
    title.dispose();
    if (result == null || !mounted) return;
    try {
      final chatId = await state.createGroupChat(result.$1, result.$2);
      if (!mounted) return;
      if (MediaQuery.sizeOf(context).width >= 900) {
        setState(() {
          index = 0;
          selectedChat = result.$1;
          selectedDirectChatId = chatId;
          selectedPeerUid = '';
          showContactInfo = true;
        });
      } else {
        await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ConversationScreen(
            title: result.$1,
            directChatId: chatId,
            peerUid: '',
          ),
        ));
      }
    } on FirebaseException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('Не удалось создать группу. Проверьте правила Firestore.'),
        ));
      }
    }
  }

  Widget _desktopChats() {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 400,
          child: ChatsScreen(
            onMenuPressed: () => scaffoldKey.currentState?.openDrawer(),
            onDirectChatSelected: (title, chatId, peerUid) => setState(() {
              selectedChat = title;
              selectedDirectChatId = chatId;
              selectedPeerUid = peerUid;
              showContactInfo = true;
            }),
            onChatSelected: (title) => setState(() {
              selectedChat = title;
              selectedDirectChatId = null;
              selectedPeerUid = null;
              showContactInfo = false;
            }),
          ),
        ),
        VerticalDivider(width: 1, color: scheme.outlineVariant),
        Expanded(
          child: selectedChat == null
              ? Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Text('Выберите, кому хотели бы написать'),
                  ),
                )
              : ConversationScreen(
                  title: selectedChat!,
                  directChatId: selectedDirectChatId,
                  peerUid: selectedPeerUid,
                ),
        ),
        if (selectedChat != null &&
            selectedDirectChatId != null &&
            showContactInfo) ...[
          VerticalDivider(width: 1, color: scheme.outlineVariant),
          SizedBox(
            width: 340,
            child: selectedPeerUid?.isNotEmpty == true
                ? UserProfilePanel(
                    key: ValueKey(selectedPeerUid),
                    uid: selectedPeerUid!,
                    fallbackName: selectedChat!,
                    onClose: () => setState(() => showContactInfo = false),
                  )
                : GroupMembersScreen(
                    key: ValueKey(selectedDirectChatId),
                    chatId: selectedDirectChatId!,
                    embedded: true,
                    onClose: () => setState(() => showContactInfo = false),
                  ),
          ),
        ],
      ],
    );
  }
}

class _AppMenu extends StatelessWidget {
  const _AppMenu({
    required this.selectedIndex,
    required this.onSelected,
    required this.onCreateGroup,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onCreateGroup;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final strings = AppLocalizations.of(context) ??
        lookupAppLocalizations(const Locale('ru'));
    final scheme = Theme.of(context).colorScheme;
    final avatar = state.avatarBase64.isEmpty
        ? null
        : MemoryImage(base64Decode(state.avatarBase64));
    return Drawer(
      width: 330,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            InkWell(
              onTap: () => onSelected(4),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(22, 22, 20, 20),
                color: scheme.surfaceContainerLow,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: brandBlue.withOpacity(.14),
                      backgroundImage: avatar,
                      child: avatar == null
                          ? Text(
                              state.username.isEmpty
                                  ? '@'
                                  : state.username[0].toUpperCase(),
                              style: const TextStyle(
                                color: brandBlue,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      state.displayName.isEmpty
                          ? state.username
                          : state.displayName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '@${state.username}',
                      style: TextStyle(color: scheme.primary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            _MenuTile(
              icon: Icons.account_circle_rounded,
              title: strings.myProfile,
              selected: selectedIndex == 4,
              onTap: () => onSelected(4),
            ),
            _MenuTile(
              icon: Icons.forum_rounded,
              title: strings.chats,
              selected: selectedIndex == 0,
              onTap: () => onSelected(0),
            ),
            _MenuTile(
              icon: Icons.group_add_rounded,
              title: strings.createGroup,
              selected: false,
              onTap: onCreateGroup,
            ),
            _MenuTile(
              icon: Icons.contacts_rounded,
              title: strings.contacts,
              selected: selectedIndex == 1,
              onTap: () => onSelected(1),
            ),
            _MenuTile(
              icon: Icons.task_alt_rounded,
              title: strings.tasks,
              selected: selectedIndex == 2,
              onTap: () => onSelected(2),
            ),
            _MenuTile(
              icon: Icons.tune_rounded,
              title: strings.settings,
              selected: selectedIndex == 3,
              onTap: () => onSelected(3),
            ),
            const Divider(height: 18),
            SwitchListTile(
              value: state.darkMode,
              onChanged: state.toggleTheme,
              secondary: Icon(
                state.darkMode
                    ? Icons.dark_mode_outlined
                    : Icons.light_mode_outlined,
              ),
              title: Text(strings.darkTheme),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: Text(
                strings.signOut,
                style: const TextStyle(color: Colors.redAccent),
              ),
              onTap: state.signOut,
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        selected: selected,
        leading: Icon(icon),
        title: Text(title),
        onTap: onTap,
      );
}
