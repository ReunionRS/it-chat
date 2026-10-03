import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class AppState extends ChangeNotifier {
  AppState({this.firebaseReady = false})
      : members = [],
        chats = [],
        messages = [],
        boards = [];

  final bool firebaseReady;
  bool isAuthenticated = false;
  bool initializing = false;
  bool profileComplete = false;
  bool darkMode = false;
  String language = 'Русский';
  bool busy = false;
  String email = '';
  String username = '';
  String displayName = '';
  String bio = '';
  String avatarBase64 = '';
  String? error;
  String? teamId;
  final List<Member> members;
  final List<ChatSummary> chats;
  final List<ChatMessage> messages;
  final List<TaskBoard> boards;
  Timer? _presenceTimer;

  String? get currentUid =>
      firebaseReady ? FirebaseAuth.instance.currentUser?.uid : null;

  Future<void> restoreSession() async {
    initializing = true;
    notifyListeners();
    try {
      await _restoreTheme();
      if (!firebaseReady) return;
      if (kIsWeb) {
        await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
      }
      final user = await FirebaseAuth.instance.authStateChanges().first;
      if (user != null && user.emailVerified) await _finishAuth(user);
    } on FirebaseException catch (e) {
      error = _firebaseMessage(e);
    } finally {
      initializing = false;
      notifyListeners();
    }
  }

  Future<bool> signIn(String value, String password) async {
    if (!firebaseReady) {
      error = 'Firebase недоступен на этой платформе';
      notifyListeners();
      return false;
    }
    return _auth(() => FirebaseAuth.instance
        .signInWithEmailAndPassword(email: value, password: password));
  }

  Future<bool> register(String value, String password) async {
    if (!firebaseReady) {
      error = 'Firebase недоступен на этой платформе';
      notifyListeners();
      return false;
    }
    busy = true;
    error = null;
    notifyListeners();
    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: value, password: password);
      await credential.user!.sendEmailVerification();
      email = value;
      return true;
    } on FirebaseAuthException catch (e) {
      error = _authMessage(e.code);
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<bool> confirmEmail() async {
    if (!firebaseReady) {
      error = 'Firebase недоступен на этой платформе';
      notifyListeners();
      return false;
    }
    try {
      await FirebaseAuth.instance.currentUser?.reload();
      final user = FirebaseAuth.instance.currentUser;
      if (user?.emailVerified != true) {
        error = 'Сначала откройте ссылку из письма';
        notifyListeners();
        return false;
      }
      return await _finishAuth(user!);
    } on FirebaseException catch (e) {
      error = _firebaseMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> _auth(Future<UserCredential> Function() action) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      final credential = await action();
      return _finishAuth(credential.user!);
    } on FirebaseAuthException catch (e) {
      error = _authMessage(e.code);
      return false;
    } on FirebaseException catch (e) {
      error = _firebaseMessage(e);
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<bool> _finishAuth(User user) async {
    if (!user.emailVerified) {
      error = 'Подтвердите e-mail по ссылке из письма';
      return false;
    }
    email = user.email ?? '';
    teamId = user.uid;
    final db = FirebaseFirestore.instance;
    final userDocument = await db.collection('users').doc(user.uid).get();
    final userData = userDocument.data();
    username = (userData?['username'] as String?) ?? '';
    displayName = (userData?['displayName'] as String?) ?? '';
    bio = (userData?['bio'] as String?) ?? '';
    avatarBase64 = (userData?['avatarBase64'] as String?) ?? '';
    profileComplete = username.isNotEmpty;
    final name = displayName.isNotEmpty
        ? displayName
        : user.displayName?.trim().isNotEmpty == true
            ? user.displayName!.trim()
            : email.split('@').first;
    displayName = name;
    final initials = name.characters.take(2).toString().toUpperCase();
    members
      ..clear()
      ..add(Member(
          id: user.uid, name: name, role: TeamRole.admin, initials: initials));
    final team = db.collection('teams').doc(teamId);
    final batch = db.batch();
    batch.set(
        db.collection('users').doc(user.uid),
        {
          'email': email,
          'displayName': name,
          'updatedAt': FieldValue.serverTimestamp()
        },
        SetOptions(merge: true));
    batch.set(
        team,
        {
          'name': 'IT Chat',
          'ownerId': user.uid,
          'updatedAt': FieldValue.serverTimestamp()
        },
        SetOptions(merge: true));
    batch.set(
        team.collection('members').doc(user.uid),
        {
          'name': name,
          'role': 'admin',
          'joinedAt': FieldValue.serverTimestamp()
        },
        SetOptions(merge: true));
    try {
      await batch.commit();
    } on FirebaseException catch (exception) {
      if (exception.code != 'permission-denied') rethrow;
      // Вход не должен сбрасываться из-за необязательной старой team-схемы.
      await db.collection('users').doc(user.uid).set(
        {
          'email': email,
          'displayName': name,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }
    try {
      await _loadBoards();
    } on FirebaseException catch (exception) {
      if (exception.code != 'permission-denied') rethrow;
      boards.clear();
    }
    isAuthenticated = true;
    _startPresence();
    notifyListeners();
    return true;
  }

  Future<bool> saveUsername(String value) async {
    final user = FirebaseAuth.instance.currentUser;
    final normalized = value.trim().toLowerCase().replaceFirst('@', '');
    if (user == null || !RegExp(r'^[a-z0-9_]{5,32}$').hasMatch(normalized)) {
      error = 'От 5 до 32 символов: латиница, цифры и _';
      notifyListeners();
      return false;
    }
    busy = true;
    error = null;
    notifyListeners();
    try {
      final db = FirebaseFirestore.instance;
      await db.runTransaction((transaction) async {
        final usernameRef = db.collection('usernames').doc(normalized);
        if ((await transaction.get(usernameRef)).exists) {
          throw FirebaseException(
              plugin: 'cloud_firestore', code: 'username-taken');
        }
        transaction.set(usernameRef, {'uid': user.uid});
        transaction.set(
            db.collection('users').doc(user.uid),
            {
              'username': normalized,
              'email': user.email,
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true));
      });
      username = normalized;
      profileComplete = true;
      return true;
    } on FirebaseException catch (e) {
      error = e.code == 'username-taken'
          ? 'Этот @username уже занят'
          : 'Не удалось сохранить @username';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<List<Contact>> searchContacts(String value) async {
    final normalized = value.trim().toLowerCase().replaceFirst('@', '');
    if (normalized.isEmpty) return [];
    final result = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: normalized)
        .where('username', isLessThan: '$normalized\uf8ff')
        .limit(20)
        .get();
    return result.docs
        .where((doc) => doc.id != FirebaseAuth.instance.currentUser?.uid)
        .map((doc) => Contact(
              uid: doc.id,
              username: doc.data()['username'] as String,
              name: (doc.data()['displayName'] as String?) ??
                  doc.data()['username'] as String,
              avatarBase64: (doc.data()['avatarBase64'] as String?) ?? '',
              bio: (doc.data()['bio'] as String?) ?? '',
              email: (doc.data()['email'] as String?) ?? '',
            ))
        .toList();
  }

  Future<String> createDirectChat(Contact contact) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Пользователь не авторизован');
    final ids = [user.uid, contact.uid]..sort();
    final chatId = ids.join('_');
    final ref =
        FirebaseFirestore.instance.collection('directChats').doc(chatId);
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final existing = await transaction.get(ref);
      if (!existing.exists) {
        transaction.set(ref, {
          'type': 'direct',
          'memberIds': ids,
          'memberNames': {
            user.uid: displayName.isEmpty ? username : displayName,
            contact.uid: contact.name,
          },
          'updatedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
          'unreadCounts': {user.uid: 0, contact.uid: 0},
        });
      }
    });
    return chatId;
  }

  Future<List<Contact>> loadContacts() async {
    final uid = currentUid;
    if (uid == null) return const [];
    final result = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('contacts')
        .orderBy('displayName')
        .limit(50)
        .get();
    return result.docs
        .where((doc) => doc.data()['username'] != null)
        .map((doc) => Contact(
              uid: (doc.data()['uid'] as String?) ?? doc.id,
              username: doc.data()['username'] as String,
              name: (doc.data()['displayName'] as String?) ??
                  doc.data()['username'] as String,
              avatarBase64: (doc.data()['avatarBase64'] as String?) ?? '',
              bio: (doc.data()['bio'] as String?) ?? '',
              email: (doc.data()['email'] as String?) ?? '',
            ))
        .toList();
  }

  Stream<List<Contact>> savedContacts() {
    final uid = currentUid;
    if (uid == null) return Stream.value(const []);
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('contacts')
        .orderBy('displayName')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Contact(
                  uid: (doc.data()['uid'] as String?) ?? doc.id,
                  username: (doc.data()['username'] as String?) ?? '',
                  name: (doc.data()['displayName'] as String?) ??
                      (doc.data()['username'] as String?) ??
                      'Контакт',
                  avatarBase64: (doc.data()['avatarBase64'] as String?) ?? '',
                ))
            .toList());
  }

  DocumentReference<Map<String, dynamic>> _contactRef(String contactUid) {
    final uid = currentUid;
    if (uid == null) throw StateError('Пользователь не авторизован');
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('contacts')
        .doc(contactUid);
  }

  Future<bool> isContact(String contactUid) async =>
      (await _contactRef(contactUid).get()).exists;

  Future<void> addContact(Contact contact) async {
    await _contactRef(contact.uid).set({
      'uid': contact.uid,
      'username': contact.username,
      'displayName': contact.name,
      'avatarBase64': contact.avatarBase64,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeContact(String contactUid) async {
    await _contactRef(contactUid).delete();
  }

  Future<void> renameContact(String contactUid, String name) async {
    final clean = name.trim();
    if (clean.isEmpty) return;
    await _contactRef(contactUid).update({'displayName': clean});
  }

  DocumentReference<Map<String, dynamic>> _blockedRef(String contactUid) {
    final uid = currentUid;
    if (uid == null) throw StateError('Пользователь не авторизован');
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('blockedContacts')
        .doc(contactUid);
  }

  Future<bool> isBlocked(String contactUid) async =>
      (await _blockedRef(contactUid).get()).exists;

  Future<void> blockContact(Contact contact) async {
    final batch = FirebaseFirestore.instance.batch();
    batch.set(_blockedRef(contact.uid), {
      'uid': contact.uid,
      'blockedAt': FieldValue.serverTimestamp(),
    });
    batch.delete(_contactRef(contact.uid));
    await batch.commit();
  }

  Future<void> unblockContact(String contactUid) async {
    await _blockedRef(contactUid).delete();
  }

  Future<String> createGroupChat(String title, List<Contact> contacts) async {
    final user = FirebaseAuth.instance.currentUser;
    final cleanTitle = title.trim();
    if (user == null || cleanTitle.length < 2 || contacts.isEmpty) {
      throw ArgumentError('Укажите название и выберите участников');
    }
    final ref = FirebaseFirestore.instance.collection('directChats').doc();
    final memberIds = [user.uid, ...contacts.map((contact) => contact.uid)];
    final memberNames = <String, String>{
      user.uid: displayName.isEmpty ? username : displayName,
      for (final contact in contacts) contact.uid: contact.name,
    };
    await ref.set({
      'type': 'group',
      'title': cleanTitle,
      'memberIds': memberIds,
      'memberNames': memberNames,
      'unreadCounts': {for (final uid in memberIds) uid: 0},
      'createdBy': user.uid,
      'roles': {user.uid: 'admin', for (final c in contacts) c.uid: 'member'},
      'access': {user.uid: 'full', for (final c in contacts) c.uid: 'read'},
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> groupChat(String chatId) =>
      FirebaseFirestore.instance
          .collection('directChats')
          .doc(chatId)
          .snapshots();

  Future<void> updateGroupMember(
      String chatId, String uid, String role, BoardAccess access) async {
    await FirebaseFirestore.instance
        .collection('directChats')
        .doc(chatId)
        .update({'roles.$uid': role, 'access.$uid': access.name});
  }

  Future<void> updateGroupAvatar(String chatId, String avatarBase64) async {
    await FirebaseFirestore.instance
        .collection('directChats')
        .doc(chatId)
        .update({'avatarBase64': avatarBase64});
  }

  Future<void> _loadBoards() async {
    final uid = currentUid;
    if (uid == null) return;
    final result = await FirebaseFirestore.instance
        .collection('taskBoards')
        .where('memberIds', arrayContains: uid)
        .get();
    boards
      ..clear()
      ..addAll(result.docs.map((doc) {
        final data = doc.data();
        final rawAccess = Map<String, dynamic>.from(
            (data['access'] as Map?) ?? const <String, dynamic>{});
        return TaskBoard(
          id: doc.id,
          title: (data['title'] as String?) ?? 'Доска задач',
          color: const Color(0xFF087BEE),
          memberIds: Set<String>.from(data['memberIds'] ?? const <String>[]),
          tasks: [],
          accessByMember: rawAccess.map((key, value) => MapEntry(
              key,
              BoardAccess.values.firstWhere((item) => item.name == value,
                  orElse: () => BoardAccess.read))),
        );
      }));
  }

  Future<void> createBoard(String title) async {
    final uid = currentUid;
    final clean = title.trim();
    if (uid == null || clean.length < 2) return;
    final ref = FirebaseFirestore.instance.collection('taskBoards').doc();
    await ref.set({
      'title': clean,
      'ownerId': uid,
      'memberIds': [uid],
      'access': {uid: 'full'},
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    boards.insert(
      0,
      TaskBoard(
        id: ref.id,
        title: clean,
        color: const Color(0xFF087BEE),
        memberIds: {uid},
        tasks: [],
        accessByMember: {uid: BoardAccess.full},
      ),
    );
    notifyListeners();
  }

  Future<void> deleteBoard(TaskBoard board) async {
    final uid = currentUid;
    if (!board.hasFullAccess(uid)) return;
    final boardRef =
        FirebaseFirestore.instance.collection('taskBoards').doc(board.id);
    final tasks = await boardRef.collection('tasks').get();
    final batch = FirebaseFirestore.instance.batch();
    for (final task in tasks.docs) {
      batch.delete(task.reference);
    }
    batch.delete(boardRef);
    await batch.commit();
    boards.removeWhere((item) => item.id == board.id);
    notifyListeners();
  }

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> groupBoards(
      String groupId) {
    final uid = currentUid;
    if (uid == null) return Stream.value(const []);
    return FirebaseFirestore.instance
        .collection('taskBoards')
        .where('memberIds', arrayContains: uid)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .where((doc) => doc.data()['groupId'] == groupId)
            .toList());
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> boardTasks(String boardId) =>
      FirebaseFirestore.instance
          .collection('taskBoards')
          .doc(boardId)
          .collection('tasks')
          .orderBy('createdAt')
          .snapshots();

  Stream<DocumentSnapshot<Map<String, dynamic>>> boardDocument(
          String boardId) =>
      FirebaseFirestore.instance
          .collection('taskBoards')
          .doc(boardId)
          .snapshots();

  Future<void> setBoardBackground(
      TaskBoard board, String backgroundBase64) async {
    final uid = currentUid;
    if (!board.canEdit(uid)) return;
    await FirebaseFirestore.instance
        .collection('taskBoards')
        .doc(board.id)
        .update({
      'backgroundBase64': backgroundBase64,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addBoardTask(
    TaskBoard board,
    String title,
    List<String> assigneeIds,
    List<String> assigneeNames,
    List<String> checklist,
    DateTime? deadline,
    String imageBase64,
  ) async {
    final uid = currentUid;
    final clean = title.trim();
    if (uid == null || clean.isEmpty || !board.canEdit(uid)) return;
    await FirebaseFirestore.instance
        .collection('taskBoards')
        .doc(board.id)
        .collection('tasks')
        .add({
      'title': clean,
      'assigneeIds': assigneeIds,
      'assigneeNames': assigneeNames,
      'assignee':
          assigneeNames.isEmpty ? 'Не назначен' : assigneeNames.join(', '),
      'checklist': [
        for (var index = 0; index < checklist.length; index++)
          {
            'id': '${DateTime.now().microsecondsSinceEpoch}_$index',
            'title': checklist[index],
            'done': false
          }
      ],
      'status': TaskStatus.todo.name,
      'priority': 'Средний',
      'deadline': deadline == null ? null : Timestamp.fromDate(deadline),
      'imageBase64': imageBase64,
      'createdBy': uid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> toggleTaskChecklist(
      TaskBoard board, BoardTask task, TaskChecklistItem item) async {
    final uid = currentUid;
    if (uid == null || !board.canEdit(uid)) return;
    final taskRef = FirebaseFirestore.instance
        .collection('taskBoards')
        .doc(board.id)
        .collection('tasks')
        .doc(task.id);
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(taskRef);
      final checklist = List<Map<String, dynamic>>.from(
          (snapshot.data()?['checklist'] as List?) ?? const []);
      for (final current in checklist) {
        if (current['id'] == item.id) current['done'] = current['done'] != true;
      }
      transaction.update(taskRef, {
        'checklist': checklist,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<TaskChecklistItem?> addTaskChecklistItem(
      TaskBoard board, BoardTask task, String title) async {
    final uid = currentUid;
    final clean = title.trim();
    if (uid == null || clean.isEmpty || !board.canEdit(uid)) return null;
    final item = TaskChecklistItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(), title: clean);
    await FirebaseFirestore.instance
        .collection('taskBoards')
        .doc(board.id)
        .collection('tasks')
        .doc(task.id)
        .update({
      'checklist': FieldValue.arrayUnion([
        {
          'id': item.id,
          'title': item.title,
          'done': false,
        }
      ]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return item;
  }

  Future<void> setTaskDeadline(
      TaskBoard board, BoardTask task, DateTime deadline) async {
    final uid = currentUid;
    if (uid == null || !board.canEdit(uid)) return;
    await FirebaseFirestore.instance
        .collection('taskBoards')
        .doc(board.id)
        .collection('tasks')
        .doc(task.id)
        .update({
      'deadline': Timestamp.fromDate(deadline),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setTaskImage(
      TaskBoard board, BoardTask task, String imageBase64) async {
    final uid = currentUid;
    if (uid == null || !board.canEdit(uid)) return;
    await FirebaseFirestore.instance
        .collection('taskBoards')
        .doc(board.id)
        .collection('tasks')
        .doc(task.id)
        .update({
      'imageBase64': imageBase64,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteBoardTask(TaskBoard board, BoardTask task) async {
    final uid = currentUid;
    if (!board.canDeleteTask(uid, task)) return;
    await FirebaseFirestore.instance
        .collection('taskBoards')
        .doc(board.id)
        .collection('tasks')
        .doc(task.id)
        .delete();
  }

  Future<void> moveBoardTask(
      TaskBoard board, BoardTask task, TaskStatus status) async {
    final uid = currentUid;
    if (uid == null || !board.canEdit(uid) || task.status == status) return;
    await FirebaseFirestore.instance
        .collection('taskBoards')
        .doc(board.id)
        .collection('tasks')
        .doc(task.id)
        .update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> createGroupBoard(
    String groupId,
    String title,
    List<String> memberIds,
    Map<String, dynamic> groupAccess,
  ) async {
    final uid = currentUid;
    final clean = title.trim();
    if (uid == null || clean.length < 2) return;
    final access = <String, String>{
      for (final memberId in memberIds)
        memberId: groupAccess[memberId]?.toString() ?? 'read',
      uid: 'full',
    };
    final ref = FirebaseFirestore.instance.collection('taskBoards').doc();
    await ref.set({
      'groupId': groupId,
      'title': clean,
      'ownerId': uid,
      'memberIds': memberIds,
      'access': access,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> directMessages(String chatId) =>
      FirebaseFirestore.instance
          .collection('directChats')
          .doc(chatId)
          .collection('messages')
          .orderBy('createdAt')
          .snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> directChats() {
    final uid = currentUid;
    if (uid == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('directChats')
        .where('memberIds', arrayContains: uid)
        .snapshots(includeMetadataChanges: true);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> chatFolders() {
    final uid = currentUid;
    if (uid == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('chatFolders')
        .orderBy('createdAt')
        .snapshots();
  }

  Future<void> createChatFolder(String name, String chatId) async {
    final uid = currentUid;
    final clean = name.trim();
    if (uid == null || clean.isEmpty || clean.length > 30) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('chatFolders')
        .add({
      'name': clean,
      'chatIds': [chatId],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addChatToFolder(String folderId, String chatId) async {
    final uid = currentUid;
    if (uid == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('chatFolders')
        .doc(folderId)
        .update({
      'chatIds': FieldValue.arrayUnion([chatId])
    });
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> userProfile(String uid) =>
      FirebaseFirestore.instance.collection('users').doc(uid).snapshots();

  Stream<DocumentSnapshot<Map<String, dynamic>>> presence(String uid) =>
      FirebaseFirestore.instance.collection('presence').doc(uid).snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> typingUsers(String chatId) =>
      FirebaseFirestore.instance
          .collection('directChats')
          .doc(chatId)
          .collection('typing')
          .snapshots();

  Future<void> sendDirectMessage(String chatId, String value) async {
    final clean = value.trim();
    final user = FirebaseAuth.instance.currentUser;
    if (clean.isEmpty || user == null) return;
    final chat =
        FirebaseFirestore.instance.collection('directChats').doc(chatId);
    await chat.collection('messages').add({
      'authorId': user.uid,
      'authorName': displayName.isEmpty ? username : displayName,
      'text': clean,
      'readBy': [user.uid],
      'createdAt': FieldValue.serverTimestamp(),
    });
    final chatData = await chat.get();
    final members =
        List<String>.from(chatData.data()?['memberIds'] ?? const []);
    final update = <String, Object?>{
      'lastMessage': clean,
      'lastAuthorId': user.uid,
      'updatedAt': FieldValue.serverTimestamp(),
      'unreadCounts.${user.uid}': 0,
    };
    for (final uid in members.where((uid) => uid != user.uid)) {
      update['unreadCounts.$uid'] = FieldValue.increment(1);
    }
    await chat.update(update);
    await setTyping(chatId, false);
  }

  Future<void> markDirectChatRead(String chatId) async {
    final uid = currentUid;
    if (uid == null) return;
    final chat =
        FirebaseFirestore.instance.collection('directChats').doc(chatId);
    await chat.update({'unreadCounts.$uid': 0});
    final all = await chat.collection('messages').get();
    final batch = FirebaseFirestore.instance.batch();
    var changed = false;
    for (final doc in all.docs) {
      final readBy = List<String>.from(doc.data()['readBy'] ?? const []);
      if (!readBy.contains(uid)) {
        batch.update(doc.reference, {
          'readBy': FieldValue.arrayUnion([uid])
        });
        changed = true;
      }
    }
    if (changed) await batch.commit();
  }

  void _startPresence() {
    _presenceTimer?.cancel();
    _writePresence(true);
    _presenceTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _writePresence(true),
    );
  }

  Future<void> _writePresence(bool online) async {
    final uid = currentUid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance.collection('presence').doc(uid).set({
        'online': online,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException {
      // Presence is optional while updated rules are being published.
    }
  }

  Future<void> setTyping(String chatId, bool active) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final ref = FirebaseFirestore.instance
        .collection('directChats')
        .doc(chatId)
        .collection('typing')
        .doc(user.uid);
    if (!active) {
      await ref.delete();
      return;
    }
    await ref.set({
      'uid': user.uid,
      'name': displayName.isEmpty ? username : displayName,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  void toggleTheme(bool value) {
    darkMode = value;
    notifyListeners();
    unawaited(_saveTheme(value));
  }

  Future<void> _saveTheme(bool value) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool('darkMode', value);
    } catch (_) {
      // Theme persistence is optional on unsupported test platforms.
    }
  }

  Future<void> setLanguage(String value) async {
    language = value;
    notifyListeners();
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString('language', value);
    } catch (_) {
      // Language persistence is optional on unsupported test platforms.
    }
  }

  Future<void> _restoreTheme() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      darkMode = preferences.getBool('darkMode') ?? false;
      language = preferences.getString('language') ?? 'Русский';
    } catch (_) {
      darkMode = false;
      language = 'Русский';
    }
  }

  Future<bool> saveProfile({
    required String name,
    required String about,
    String? avatar,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    final cleanName = name.trim();
    final cleanBio = about.trim();
    if (user == null || cleanName.length < 2 || cleanName.length > 50) {
      error = 'Имя должно содержать от 2 до 50 символов';
      notifyListeners();
      return false;
    }
    if (cleanBio.length > 160) {
      error = 'Описание не должно превышать 160 символов';
      notifyListeners();
      return false;
    }
    busy = true;
    error = null;
    notifyListeners();
    try {
      final update = <String, Object?>{
        'displayName': cleanName,
        'bio': cleanBio,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (avatar != null) update['avatarBase64'] = avatar;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(update, SetOptions(merge: true));
      await user.updateDisplayName(cleanName);
      displayName = cleanName;
      bio = cleanBio;
      if (avatar != null) avatarBase64 = avatar;
      if (members.isNotEmpty) members.first.name = cleanName;
      return true;
    } on FirebaseException catch (e) {
      error = _firebaseMessage(e);
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _presenceTimer?.cancel();
    if (firebaseReady) {
      await _writePresence(false);
      await FirebaseAuth.instance.signOut();
    }
    isAuthenticated = false;
    profileComplete = false;
    displayName = '';
    bio = '';
    avatarBase64 = '';
    notifyListeners();
  }

  @override
  void dispose() {
    _presenceTimer?.cancel();
    super.dispose();
  }

  void sendMessage(String value) {
    if (value.trim().isEmpty) return;
    messages.add(ChatMessage(
        author: 'Вы', text: value.trim(), time: 'сейчас', mine: true));
    notifyListeners();
    if (firebaseReady && teamId != null) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      unawaited(FirebaseFirestore.instance
          .collection('teams')
          .doc(teamId)
          .collection('chats')
          .doc('development')
          .collection('messages')
          .add({
        'authorId': uid,
        'text': value.trim(),
        'createdAt': FieldValue.serverTimestamp()
      }));
    }
  }

  Future<void> createChat(String title) async {
    final clean = title.trim();
    if (clean.isEmpty || teamId == null) return;
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('teams')
        .doc(teamId)
        .collection('chats')
        .add({
      'title': clean,
      'createdBy': uid,
      'memberIds': [uid],
      'createdAt': FieldValue.serverTimestamp(),
    });
    chats.insert(
        0,
        ChatSummary(
            title: clean,
            preview: 'Чат создан',
            time: 'сейчас',
            initials: clean.characters.take(2).toString().toUpperCase()));
    notifyListeners();
  }

  void updateRole(Member member, TeamRole role) {
    member.role = role;
    notifyListeners();
  }

  void toggleBoardAccess(TaskBoard board, String memberId) {
    board.memberIds.contains(memberId)
        ? board.memberIds.remove(memberId)
        : board.memberIds.add(memberId);
    notifyListeners();
  }

  String _authMessage(String code) => switch (code) {
        'invalid-credential' ||
        'wrong-password' ||
        'user-not-found' =>
          'Неверный e-mail или пароль',
        'email-already-in-use' => 'Этот e-mail уже зарегистрирован',
        'weak-password' => 'Используйте более надёжный пароль',
        'operation-not-allowed' =>
          'Включите Email/Password в Firebase Authentication',
        _ => 'Ошибка Firebase: $code',
      };

  String _firebaseMessage(FirebaseException exception) =>
      switch (exception.code) {
        'permission-denied' =>
          'Нет доступа к Firestore. Опубликуйте правила Firestore из проекта.',
        'unavailable' ||
        'failed-precondition' =>
          'Firebase временно недоступен. Проверьте подключение и настройки проекта.',
        _ => 'Ошибка Firebase: ${exception.code}',
      };
}

class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope(
      {super.key, required super.notifier, required super.child});
  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppStateScope>()!.notifier!;
}
