import 'package:flutter/material.dart';

enum TeamRole { admin, lead, developer, designer, manager }

extension TeamRoleLabel on TeamRole {
  String get label => switch (this) {
        TeamRole.admin => 'Админ',
        TeamRole.lead => 'Team Lead',
        TeamRole.developer => 'Разработчик',
        TeamRole.designer => 'Дизайнер',
        TeamRole.manager => 'Менеджер'
      };
  Color get color => switch (this) {
        TeamRole.admin => const Color(0xFF087BEE),
        TeamRole.lead => const Color(0xFF316FEA),
        TeamRole.developer => const Color(0xFF2E9B68),
        TeamRole.designer => const Color(0xFF8753C7),
        TeamRole.manager => const Color(0xFFE68120)
      };
}

class Member {
  Member(
      {required this.id,
      required this.name,
      required this.role,
      required this.initials});
  final String id, initials;
  String name;
  TeamRole role;
}

class Contact {
  const Contact(
      {required this.uid,
      required this.username,
      required this.name,
      this.avatarBase64 = ''});
  final String uid, username, name;
  final String avatarBase64;
}

class ChatSummary {
  ChatSummary(
      {required this.title,
      required this.preview,
      required this.time,
      required this.initials,
      this.unread = 0});
  final String title, time, initials;
  String preview;
  int unread;
}

class ChatMessage {
  ChatMessage(
      {required this.author,
      required this.text,
      required this.time,
      this.mine = false,
      this.attachment});
  final String author, text, time;
  final bool mine;
  final String? attachment;
}

enum TaskStatus { todo, doing, done }

enum BoardAccess { read, edit, full }

extension BoardAccessLabel on BoardAccess {
  String get label => switch (this) {
        BoardAccess.read => 'Чтение',
        BoardAccess.edit => 'Редактирование',
        BoardAccess.full => 'Полный доступ',
      };
}

extension TaskStatusLabel on TaskStatus {
  String get label => switch (this) {
        TaskStatus.todo => 'К выполнению',
        TaskStatus.doing => 'В работе',
        TaskStatus.done => 'Готово'
      };
  Color get color => switch (this) {
        TaskStatus.todo => const Color(0xFFE75B5B),
        TaskStatus.doing => const Color(0xFF397FEF),
        TaskStatus.done => const Color(0xFF2E9B68)
      };
}

class BoardTask {
  BoardTask(
      {required this.id,
      required this.title,
      required this.assignee,
      required this.status,
      required this.priority});
  final String id, title, assignee, priority;
  TaskStatus status;
}

class TaskBoard {
  TaskBoard(
      {required this.id,
      required this.title,
      required this.color,
      required this.memberIds,
      required this.tasks,
      Map<String, BoardAccess>? accessByMember})
      : accessByMember = accessByMember ?? {};
  final String id, title;
  final Color color;
  final Set<String> memberIds;
  final List<BoardTask> tasks;
  final Map<String, BoardAccess> accessByMember;

  bool canEdit(String? uid) =>
      uid != null &&
      (accessByMember[uid] == BoardAccess.edit ||
          accessByMember[uid] == BoardAccess.full);
}
