import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../../state/models.dart';
import '../../theme.dart';
import '../admin/members_screen.dart';
import '../shared/widgets.dart';
import 'group_members_screen.dart';

class ConversationScreen extends StatefulWidget {
  const ConversationScreen({
    super.key,
    required this.title,
    this.directChatId,
    this.peerUid,
  });

  final String title;
  final String? directChatId;
  final String? peerUid;

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final input = TextEditingController();
  Timer? typingTimer;
  bool typingSent = false;
  late AppState appState;

  bool get isDirect => widget.directChatId != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    appState = AppStateScope.of(context);
  }

  @override
  void dispose() {
    typingTimer?.cancel();
    if (isDirect && typingSent) {
      unawaited(appState.setTyping(widget.directChatId!, false));
    }
    input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(children: [
          if (isDirect && widget.peerUid?.isNotEmpty == true)
            _PeerAvatar(uid: widget.peerUid!, name: widget.title)
          else
            InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: isDirect
                  ? () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              GroupMembersScreen(chatId: widget.directChatId!)))
                  : null,
              child: InitialsAvatar(
                widget.title.characters.take(2).toString().toUpperCase(),
                radius: 19,
              ),
            ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.title,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            if (isDirect)
              _PeerStatus(
                chatId: widget.directChatId!,
                peerUid: widget.peerUid,
                state: state,
              )
            else
              Text('Групповой чат',
                  style:
                      TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
          ])
        ]),
        actions: isDirect
            ? widget.peerUid?.isNotEmpty == true
                ? null
                : [
                    IconButton(
                      tooltip: 'Участники группы',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => GroupMembersScreen(
                                chatId: widget.directChatId!)),
                      ),
                      icon: const Icon(Icons.group_outlined),
                    )
                  ]
            : [
                IconButton(
                    tooltip: 'Участники и роли',
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const MembersScreen())),
                    icon: const Icon(Icons.group_outlined, color: brandBlue))
              ],
      ),
      body: Column(children: [
        Expanded(
          child: isDirect
              ? _DirectMessages(chatId: widget.directChatId!, state: state)
              : _LocalMessages(messages: state.messages),
        ),
        SafeArea(
          top: false,
          child: Container(
            color: scheme.surface,
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Row(children: [
              IconButton(
                  onPressed: () {},
                  icon:
                      Icon(Icons.attach_file, color: scheme.onSurfaceVariant)),
              Expanded(
                child: TextField(
                  controller: input,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged:
                      isDirect ? (value) => _onTyping(state, value) : null,
                  onSubmitted: (_) => _send(state),
                  decoration: const InputDecoration(
                    hintText: 'Написать сообщение...',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton.filled(
                  tooltip: 'Отправить',
                  onPressed: () => _send(state),
                  icon: const Icon(Icons.arrow_upward))
            ]),
          ),
        ),
      ]),
    );
  }

  void _onTyping(AppState state, String value) {
    typingTimer?.cancel();
    if (value.trim().isEmpty) {
      typingSent = false;
      unawaited(state.setTyping(widget.directChatId!, false));
      return;
    }
    if (!typingSent) {
      typingSent = true;
      unawaited(state.setTyping(widget.directChatId!, true));
    }
    typingTimer = Timer(const Duration(seconds: 2), () {
      typingSent = false;
      state.setTyping(widget.directChatId!, false);
    });
  }

  Future<void> _send(AppState state) async {
    final text = input.text;
    if (text.trim().isEmpty) return;
    input.clear();
    typingTimer?.cancel();
    typingSent = false;
    if (isDirect) {
      await state.sendDirectMessage(widget.directChatId!, text);
    } else {
      state.sendMessage(text);
    }
  }
}

class _PeerAvatar extends StatelessWidget {
  const _PeerAvatar({required this.uid, required this.name});
  final String uid;
  final String name;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: state.userProfile(uid),
      builder: (context, snapshot) => UserAvatar(
        name: name,
        radius: 19,
        avatarBase64: (snapshot.data?.data()?['avatarBase64'] as String?) ?? '',
      ),
    );
  }
}

class _PeerStatus extends StatefulWidget {
  const _PeerStatus({
    required this.chatId,
    required this.peerUid,
    required this.state,
  });
  final String chatId;
  final String? peerUid;
  final AppState state;

  @override
  State<_PeerStatus> createState() => _PeerStatusState();
}

class _PeerStatusState extends State<_PeerStatus> {
  Timer? refreshTimer;

  @override
  void initState() {
    super.initState();
    refreshTimer = Timer.periodic(
        const Duration(seconds: 15), (_) => mounted ? setState(() {}) : null);
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: widget.state.typingUsers(widget.chatId),
        builder: (context, snapshot) {
          final users = snapshot.data?.docs
                  .where((doc) => doc.id != widget.state.currentUid)
                  .toList() ??
              const [];
          if (users.isNotEmpty) {
            return _text(
                '${users.first.data()['name'] ?? 'Собеседник'} печатает…',
                true);
          }
          if (widget.peerUid?.isNotEmpty != true) {
            return _text('групповой чат', false);
          }
          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: widget.state.presence(widget.peerUid!),
            builder: (context, presenceSnapshot) {
              final data = presenceSnapshot.data?.data();
              final lastSeen = data?['lastSeen'] as Timestamp?;
              final fresh = lastSeen != null &&
                  DateTime.now().difference(lastSeen.toDate()).inSeconds < 75;
              final online = data?['online'] == true && fresh;
              return _text(online ? 'в сети' : _lastSeenText(lastSeen), online);
            },
          );
        },
      );

  Widget _text(String text, bool active) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: Text(
          text,
          key: ValueKey(text),
          style: TextStyle(
            fontSize: 12,
            color: active
                ? brandBlue
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );

  String _lastSeenText(Timestamp? timestamp) {
    if (timestamp == null) return 'не в сети';
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inMinutes < 1) return 'был(а) только что';
    if (difference.inMinutes < 60) {
      return 'был(а) ${difference.inMinutes} мин. назад';
    }
    if (difference.inHours < 24) {
      return 'был(а) ${difference.inHours} ч. назад';
    }
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'был(а) в ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    return 'был(а) ${date.day}.${date.month.toString().padLeft(2, '0')}';
  }
}

class _DirectMessages extends StatelessWidget {
  const _DirectMessages({required this.chatId, required this.state});

  final String chatId;
  final AppState state;

  @override
  Widget build(BuildContext context) =>
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: state.directMessages(chatId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const EmptyState(
              icon: Icons.error_outline,
              title: 'Не удалось загрузить сообщения',
              subtitle: 'Проверьте опубликованные правила Firestore',
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          unawaited(state.markDirectChatRead(chatId));
          if (docs.isEmpty) {
            return const EmptyState(
              icon: Icons.waving_hand_outlined,
              title: 'Начните переписку',
              subtitle: 'Отправьте первое сообщение',
            );
          }
          return ListView.builder(
            reverse: true,
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[docs.length - 1 - index];
              final data = doc.data();
              return _AnimatedMessage(
                key: ValueKey(doc.id),
                mine: data['authorId'] == state.currentUid,
                author: (data['authorName'] as String?) ?? '',
                text: (data['text'] as String?) ?? '',
                time: _formatTime(data['createdAt'] as Timestamp?),
                read: List<String>.from(data['readBy'] ?? const []).length > 1,
              );
            },
          );
        },
      );

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return 'сейчас';
    final date = timestamp.toDate();
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _LocalMessages extends StatelessWidget {
  const _LocalMessages({required this.messages});
  final List<ChatMessage> messages;

  @override
  Widget build(BuildContext context) => ListView.builder(
        reverse: true,
        padding: const EdgeInsets.all(16),
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[messages.length - 1 - index];
          return _AnimatedMessage(
            mine: message.mine,
            author: message.author,
            text: message.text,
            time: message.time,
            read: false,
          );
        },
      );
}

class _AnimatedMessage extends StatelessWidget {
  const _AnimatedMessage({
    super.key,
    required this.mine,
    required this.author,
    required this.text,
    required this.time,
    required this.read,
  });

  final bool mine;
  final String author;
  final String text;
  final String time;
  final bool read;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 10 * (1 - value)),
          child: child,
        ),
      ),
      child: Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.fromLTRB(13, 10, 11, 7),
          constraints: const BoxConstraints(maxWidth: 420),
          decoration: BoxDecoration(
            color:
                mine ? scheme.primaryContainer : scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!mine && author.isNotEmpty) ...[
                Text(author,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: brandBlue)),
                const SizedBox(height: 3),
              ],
              Text(text),
              const SizedBox(height: 3),
              Align(
                alignment: Alignment.bottomRight,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(time,
                      style: TextStyle(
                          fontSize: 10, color: scheme.onSurfaceVariant)),
                  if (mine) ...[
                    const SizedBox(width: 3),
                    Icon(read ? Icons.done_all : Icons.done,
                        size: 15,
                        color: read ? brandBlue : scheme.onSurfaceVariant),
                  ],
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
