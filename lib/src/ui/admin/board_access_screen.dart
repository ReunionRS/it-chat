import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import '../../state/models.dart';
import '../../theme.dart';
import '../shared/widgets.dart';

class BoardAccessScreen extends StatelessWidget {
  const BoardAccessScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    return Scaffold(
      appBar: AppBar(
          title: const Text('Доступ к доскам',
              style: TextStyle(fontWeight: FontWeight.w800))),
      body: ListenableBuilder(
          listenable: state,
          builder: (_, __) =>
              ListView(padding: const EdgeInsets.all(16), children: [
                const Text(
                    'Администратор определяет, какие участники видят каждую доску и могут работать с её задачами.',
                    style: TextStyle(color: Colors.black54, height: 1.4)),
                const SizedBox(height: 14),
                ...state.boards.map((board) => Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ExpansionTile(
                      leading: CircleAvatar(
                          backgroundColor: board.color.withOpacity(.12),
                          child: Icon(Icons.view_kanban_outlined,
                              color: board.color)),
                      title: Text(board.title,
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text('${board.memberIds.length} участников'),
                      children: state.members
                          .map((member) => CheckboxListTile(
                              value: board.memberIds.contains(member.id),
                              onChanged: member.id == 'me'
                                  ? null
                                  : (_) =>
                                      state.toggleBoardAccess(board, member.id),
                              secondary:
                                  InitialsAvatar(member.initials, radius: 17),
                              title: Text(member.name),
                              subtitle: Text(member.role.label),
                              activeColor: brandBlue))
                          .toList(),
                    ))),
              ])),
    );
  }
}
