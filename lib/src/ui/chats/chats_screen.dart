import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../shared/widgets.dart';
import 'conversation_screen.dart';

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
  String query = '';
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final chats = state.chats
        .where((c) => c.title.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return SafeArea(
        child: Column(children: [
      SectionTitle('Чаты',
          leading: widget.onMenuPressed == null
              ? null
              : IconButton(
                  tooltip: 'Меню',
                  onPressed: widget.onMenuPressed,
                  icon: const Icon(Icons.menu))),
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
              controller: search,
              onChanged: (v) => setState(() => query = v),
              decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Поиск по чатам',
                  isDense: true))),
      const SizedBox(height: 10),
      SizedBox(
          height: 38,
          child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: ['Все', 'Команда', 'Проекты', 'Личные']
                  .map((e) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(label: Text(e), selected: e == 'Все')))
                  .toList())),
      const SizedBox(height: 8),
      Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: state.directChats(),
              builder: (context, snapshot) {
                final directChats = (snapshot.data?.docs ?? [])
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
                        title: title,
                        preview: (data['lastMessage'] as String?) ??
                            'Начните переписку',
                        updatedAt: data['updatedAt'] as Timestamp?,
                        unread: ((data['unreadCounts']
                                    as Map?)?[state.currentUid] as num?)
                                ?.toInt() ??
                            0,
                      );
                    })
                    .where((chat) =>
                        chat.title.toLowerCase().contains(query.toLowerCase()))
                    .toList()
                  ..sort((a, b) => (b.updatedAt?.millisecondsSinceEpoch ?? 0)
                      .compareTo(a.updatedAt?.millisecondsSinceEpoch ?? 0));
                if (snapshot.connectionState == ConnectionState.waiting &&
                    chats.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const EmptyState(
                    icon: Icons.error_outline,
                    title: 'Не удалось загрузить чаты',
                    subtitle: 'Проверьте правила Firestore',
                  );
                }
                if (directChats.isEmpty && chats.isEmpty) {
                  return const EmptyState(
                    icon: Icons.forum_outlined,
                    title: 'Чатов пока нет',
                    subtitle: 'Найдите контакт и начните переписку',
                  );
                }
                return ListView(
                  children: [
                    for (final direct in directChats) ...[
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 5),
                        leading: _ChatAvatar(
                            uid: direct.peerUid, name: direct.title),
                        title: Text(direct.title,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(direct.preview,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
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
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10)),
                                ),
                                child: Text('${direct.unread}',
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 11)),
                              ),
                          ],
                        ),
                        onTap: () => widget.onDirectChatSelected != null
                            ? widget.onDirectChatSelected!(
                                direct.title, direct.id, direct.peerUid)
                            : Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => ConversationScreen(
                                  title: direct.title,
                                  directChatId: direct.id,
                                  peerUid: direct.peerUid,
                                ),
                              )),
                      ),
                      const Divider(height: 1, indent: 78),
                    ],
                    for (final chat in chats)
                      Dismissible(
                        key: ValueKey(chat.title),
                        direction: DismissDirection.startToEnd,
                        confirmDismiss: (_) async {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
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
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(chat.preview,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(chat.time,
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.black45)),
                                if (chat.unread > 0)
                                  Container(
                                      margin: const EdgeInsets.only(top: 5),
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
                                              fontWeight: FontWeight.w700)))
                              ]),
                          onTap: () => widget.onChatSelected != null
                              ? widget.onChatSelected!(chat.title)
                              : Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) =>
                                      ConversationScreen(title: chat.title))),
                        ),
                      ),
                  ],
                );
              }))
    ]));
  }

  String _chatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _DirectChatEntry {
  const _DirectChatEntry({
    required this.id,
    required this.peerUid,
    required this.title,
    required this.preview,
    required this.updatedAt,
    required this.unread,
  });

  final String id;
  final String peerUid;
  final String title;
  final String preview;
  final Timestamp? updatedAt;
  final int unread;
}

class _ChatAvatar extends StatelessWidget {
  const _ChatAvatar({required this.uid, required this.name});
  final String uid;
  final String name;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    if (uid.isEmpty) return UserAvatar(name: name);
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: state.userProfile(uid),
      builder: (context, snapshot) => UserAvatar(
        name: name,
        avatarBase64: (snapshot.data?.data()?['avatarBase64'] as String?) ?? '',
      ),
    );
  }
}
