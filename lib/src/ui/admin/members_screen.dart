import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import '../../state/models.dart';
import '../../theme.dart';
import '../shared/widgets.dart';
import 'board_access_screen.dart';

class MembersScreen extends StatelessWidget {
  const MembersScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    return Scaffold(
      appBar: AppBar(
          title: const Text('Участники и роли',
              style: TextStyle(fontWeight: FontWeight.w800)),
          actions: [
            IconButton(
                tooltip: 'Доступы к доскам',
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const BoardAccessScreen())),
                icon: const Icon(Icons.dashboard_customize_outlined,
                    color: brandBlue))
          ]),
      body: ListenableBuilder(
          listenable: state,
          builder: (_, __) =>
              ListView(padding: const EdgeInsets.all(16), children: [
                const TextField(
                    decoration: InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Поиск по участникам...')),
                const SizedBox(height: 14),
                ...state.members.map((member) => Card(
                    elevation: 0,
                    color: Colors.white,
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: InitialsAvatar(member.initials),
                      title: Text(member.name,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(member.id == 'me'
                          ? 'Вы · ${member.role.label}'
                          : member.role.label),
                      trailing: member.id == 'me'
                          ? const Icon(Icons.verified_user, color: brandBlue)
                          : PopupMenuButton<TeamRole>(
                              initialValue: member.role,
                              onSelected: (role) =>
                                  state.updateRole(member, role),
                              itemBuilder: (_) => TeamRole.values
                                  .map((role) => PopupMenuItem(
                                      value: role,
                                      child: Row(children: [
                                        Icon(Icons.circle,
                                            size: 10, color: role.color),
                                        const SizedBox(width: 8),
                                        Text(role.label)
                                      ])))
                                  .toList(),
                              child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                      color: member.role.color.withOpacity(.1),
                                      borderRadius: BorderRadius.circular(12)),
                                  child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(member.role.label,
                                            style: TextStyle(
                                                color: member.role.color,
                                                fontWeight: FontWeight.w700)),
                                        const SizedBox(width: 4),
                                        Icon(Icons.expand_more,
                                            size: 18, color: member.role.color)
                                      ]))),
                    ))),
              ])),
    );
  }
}
