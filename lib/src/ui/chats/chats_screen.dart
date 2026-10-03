import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../shared/widgets.dart';
import 'conversation_screen.dart';
import '../../../l10n/generated/app_localizations.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({
    super.key,
    this.onChatSelected,
    this.onDirectChatSelected,
    this.onMenuPressed,
  });
  final ValueChanged<String>? onChatSelected;
  final void Function(String title, String chatId, String peerUid)?
      onDirectChatSelected;
  final VoidCallback? onMenuPressed;
  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  final search = TextEditingController();
  Stream<QuerySnapshot<Map<String, dynamic>>>? foldersStream;
  Stream<QuerySnapshot<Map<String, dynamic>>>? chatsStream;
  String query = '';
  String? selectedFolderId;
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final strings = AppLocalizations.of(context) ??
        lookupAppLocalizations(const Locale('ru'));
    foldersStream ??= state.chatFolders();
    chatsStream ??= state.directChats();
    final chats = state.chats
        .where((c) => c.title.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return SafeArea(
        child: Column(children: [
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: chatsStream,
        builder: (context, snapshot) {
          final connected = snapshot.hasData &&
              !snapshot.data!.metadata.isFromCache &&
              !snapshot.hasError;
          final title = connected
              ? strings.chats
              : snapshot.hasData
                  ? strings.updating
                  : strings.connecting;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SectionTitle(title,
                  leading: widget.onMenuPressed == null
                      ? null
                      : IconButton(
                          tooltip: 'Меню',
                          onPressed: widget.onMenuPressed,
                          icon: const Icon(Icons.menu))),
              if (!connected)
                LinearProgressIndicator(
                  minHeight: 2,
                  value: snapshot.hasData ? .7 : .3,
                ),
            ],
          );
        },
      ),
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
              controller: search,
              onChanged: (v) => setState(() => query = v),
              decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: strings.searchChats,
                  isDense: true))),
      const SizedBox(height: 10),
      Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: foldersStream,
              builder: (context, foldersSnapshot) {
                final folders = (foldersSnapshot.data?.docs ?? const [])
                    .map((doc) => _ChatFolder(
                          id: doc.id,
                          name: (doc.data()['name'] as String?) ?? 'Папка',
                          chatIds: Set<String>.from(
                              doc.data()['chatIds'] ?? const <String>[]),
                        ))
                    .toList();
                final activeFolder = folders
                    .where((folder) => folder.id == selectedFolderId)
                    .firstOrNull;
                return Column(children: [
                  if (folders.isNotEmpty) ...[
                    SizedBox(
                      height: 38,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: const Text('Все'),
                              selected: selectedFolderId == null,
                              onSelected: (_) =>
                                  setState(() => selectedFolderId = null),
                            ),
                          ),
                          for (final folder in folders)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(folder.name),
                                selected: selectedFolderId == folder.id,
                                onSelected: (_) => setState(
                                    () => selectedFolderId = folder.id),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Expanded(
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: chatsStream,
                        builder: (context, snapshot) {
                          var directChats = (snapshot.data?.docs ?? [])
                              .map((doc) {
                                final data = doc.data();
                                final names = Map<String, dynamic>.from(
                                    (data['memberNames'] as Map?) ?? const {});
                                final memberIds = List<String>.from(
                                    data['memberIds'] ?? const <String>[]);
                                final peerUid = memberIds.firstWhere(
                                    (uid) => uid != state.currentUid,
                                    orElse: () => '');
                                names.remove(state.currentUid);
                                final isGroup = data['type'] == 'group';
                                final title = isGroup
                                    ? (data['title'] as String?) ?? 'Группа'
                                    : names.values.isEmpty
                                        ? 'Личный чат'
                                        : names.values.first.toString();
                                return _DirectChatEntry(
                                  id: doc.id,
                                  peerUid: isGroup ? '' : peerUid,
                                  avatarBase64:
                                      (data['avatarBase64'] as String?) ?? '',
                                  title: title,
                                  preview: (data['lastMessage'] as String?) ??
                                      'Начните переписку',
                                  updatedAt: data['updatedAt'] as Timestamp?,
                                  unread: ((data['unreadCounts']
                                                  as Map?)?[state.currentUid]
                                              as num?)
                                          ?.toInt() ??
                                      0,
                                );
                              })
                              .where((chat) => chat.title
                                  .toLowerCase()
                                  .contains(query.toLowerCase()))
                              .toList()
                            ..sort((a, b) => (b
                                        .updatedAt?.millisecondsSinceEpoch ??
                                    0)
                                .compareTo(
                                    a.updatedAt?.millisecondsSinceEpoch ?? 0));
                          if (activeFolder != null) {
                            directChats = directChats
                                .where((chat) =>
                                    activeFolder.chatIds.contains(chat.id))
                                .toList();
                          }
                          if (snapshot.connectionState ==
                                  ConnectionState.waiting &&
                              chats.isEmpty) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return const EmptyState(
                              icon: Icons.error_outline,
                              title: 'Не удалось загрузить чаты',
                              subtitle: 'Проверьте правила Firestore',
                            );
                          }
                          if (directChats.isEmpty && chats.isEmpty) {
                            return EmptyState(
                              icon: Icons.forum_outlined,
                              title: strings.noChats,
                              subtitle: strings.findContact,
                            );
                          }
                          return ListView(
                            children: [
                              for (final direct in directChats) ...[
                                ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 18, vertical: 5),
                                  leading: _ChatAvatar(
                                    uid: direct.peerUid,
                                    name: direct.title,
                                    avatarBase64: direct.avatarBase64,
                                  ),
                                  title: Text(direct.title,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700)),
                                  subtitle: Text(direct.preview,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(_chatTime(direct.updatedAt),
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant)),
                                      if (direct.unread > 0)
                                        Container(
                                          margin: const EdgeInsets.only(top: 4),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 7, vertical: 2),
                                          decoration: const BoxDecoration(
                                            color: brandBlue,
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(10)),
                                          ),
                                          child: Text('${direct.unread}',
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11)),
                                        ),
                                    ],
                                  ),
                                  onTap: () => widget.onDirectChatSelected !=
                                          null
                                      ? widget.onDirectChatSelected!(
                                          direct.title,
                                          direct.id,
                                          direct.peerUid)
                                      : Navigator.of(context)
                                          .push(MaterialPageRoute(
                                          builder: (_) => ConversationScreen(
                                            title: direct.title,
                                            directChatId: direct.id,
                                            peerUid: direct.peerUid,
                                          ),
                                        )),
                                  onLongPress: () =>
                                      _showFolderPicker(state, direct, folders),
                                ),
                                const Divider(height: 1, indent: 78),
                              ],
                              for (final chat in chats)
                                Dismissible(
                                  key: ValueKey(chat.title),
                                  direction: DismissDirection.startToEnd,
                                  confirmDismiss: (_) async {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                '${chat.title}: участники и аватар группы')));
                                    return false;
                                  },
                                  background: Container(
                                      color: brandBlue,
                                      alignment: Alignment.centerLeft,
                                      padding: const EdgeInsets.only(left: 24),
                                      child: const Icon(Icons.group_outlined,
                                          color: Colors.white)),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 18, vertical: 5),
                                    leading: InitialsAvatar(chat.initials),
                                    title: Text(chat.title,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700)),
                                    subtitle: Text(chat.preview,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                    trailing: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(chat.time,
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.black45)),
                                          if (chat.unread > 0)
                                            Container(
                                                margin: const EdgeInsets.only(
                                                    top: 5),
                                                width: 22,
                                                height: 22,
                                                decoration: const BoxDecoration(
                                                    color: brandBlue,
                                                    shape: BoxShape.circle),
                                                alignment: Alignment.center,
                                                child: Text('${chat.unread}',
                                                    style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w700)))
                                        ]),
                                    onTap: () => widget.onChatSelected != null
                                        ? widget.onChatSelected!(chat.title)
                                        : Navigator.of(context).push(
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    ConversationScreen(
                                                        title: chat.title))),
                                  ),
                                ),
                            ],
                          );
                        }),
                  ),
                ]);
              }))
    ]));
  }

  Future<void> _showFolderPicker(
      AppState state, _DirectChatEntry chat, List<_ChatFolder> folders) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const ListTile(
            title: Text('Добавить в папку',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
          for (final folder in folders)
            ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: Text(folder.name),
              trailing: folder.chatIds.contains(chat.id)
                  ? const Icon(Icons.check, color: brandBlue)
                  : null,
              onTap: folder.chatIds.contains(chat.id)
                  ? null
                  : () async {
                      await state.addChatToFolder(folder.id, chat.id);
                      if (sheetContext.mounted) Navigator.pop(sheetContext);
                    },
            ),
          ListTile(
            leading:
                const Icon(Icons.create_new_folder_outlined, color: brandBlue),
            title: const Text('Новая папка'),
            onTap: () {
              Navigator.pop(sheetContext);
              _createFolder(state, chat.id);
            },
          ),
        ]),
      ),
    );
  }

  Future<void> _createFolder(AppState state, String chatId) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Новая папка'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 30,
          decoration: const InputDecoration(hintText: 'Название папки'),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              Navigator.pop(dialogContext, value.trim());
            }
          },
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Отмена')),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(dialogContext, controller.text.trim());
              }
            },
            child: const Text('Создать'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name != null) await state.createChatFolder(name, chatId);
  }

  String _chatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _ChatFolder {
  const _ChatFolder(
      {required this.id, required this.name, required this.chatIds});
  final String id;
  final String name;
  final Set<String> chatIds;
}

class _DirectChatEntry {
  const _DirectChatEntry({
    required this.id,
    required this.peerUid,
    required this.avatarBase64,
    required this.title,
    required this.preview,
    required this.updatedAt,
    required this.unread,
  });

  final String id;
  final String peerUid;
  final String avatarBase64;
  final String title;
  final String preview;
  final Timestamp? updatedAt;
  final int unread;
}

class _ChatAvatar extends StatelessWidget {
  const _ChatAvatar({
    required this.uid,
    required this.name,
    this.avatarBase64 = '',
  });
  final String uid;
  final String name;
  final String avatarBase64;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    if (uid.isEmpty) {
      return UserAvatar(name: name, avatarBase64: avatarBase64);
    }
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: state.userProfile(uid),
      builder: (context, snapshot) => UserAvatar(
        name: name,
        avatarBase64: (snapshot.data?.data()?['avatarBase64'] as String?) ?? '',
      ),
    );
  }
}
