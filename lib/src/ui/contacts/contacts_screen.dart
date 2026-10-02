import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../state/app_state.dart';
import '../../state/models.dart';
import '../../theme.dart';
import '../shared/widgets.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key, this.onMenuPressed, this.onChat});
  final VoidCallback? onMenuPressed;
  final Future<void> Function(Contact contact)? onChat;
  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final controller = TextEditingController();
  List<Contact> results = const [];
  bool loading = false;
  String? error;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> search() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      results = await AppStateScope.of(context).searchContacts(controller.text);
    } on FirebaseException catch (e) {
      error = e.code == 'permission-denied'
          ? 'Нет доступа к поиску контактов. Опубликуйте правила Firestore.'
          : 'Не удалось выполнить поиск контактов';
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
          child: Column(children: [
        SectionTitle('Контакты',
            leading: widget.onMenuPressed == null
                ? null
                : IconButton(
                    tooltip: 'Меню',
                    onPressed: widget.onMenuPressed,
                    icon: const Icon(Icons.menu))),
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
                controller: controller,
                onSubmitted: (_) => search(),
                decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Поиск по @username',
                    suffixIcon: IconButton(
                        onPressed: search,
                        icon: const Icon(Icons.arrow_forward))))),
        const SizedBox(height: 12),
        Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                    ? EmptyState(
                        icon: Icons.error_outline,
                        title: 'Поиск недоступен',
                        subtitle: error!)
                    : results.isEmpty
                        ? const EmptyState(
                            icon: Icons.people_outline,
                            title: 'Найдите коллег',
                            subtitle: 'Введите @username в строке поиска')
                        : ListView.separated(
                            itemCount: results.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1, indent: 72),
                            itemBuilder: (_, index) {
                              final contact = results[index];
                              return ListTile(
                                  leading: UserAvatar(
                                      name: contact.name,
                                      avatarBase64: contact.avatarBase64),
                                  title: Text(contact.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700)),
                                  subtitle: Text('@${contact.username}'),
                                  trailing: IconButton(
                                      tooltip: 'Написать',
                                      onPressed: widget.onChat == null
                                          ? null
                                          : () => widget.onChat!(contact),
                                      icon: const Icon(
                                          Icons.chat_bubble_outline,
                                          color: brandBlue)));
                            }))
      ]));
}
