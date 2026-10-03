import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:it_chat/main.dart' as app;
import 'package:it_chat/src/state/app_state.dart';
import 'package:it_chat/src/state/models.dart';
import 'package:it_chat/src/theme.dart';
import 'package:it_chat/src/ui/auth/email_auth_screen.dart';
import 'package:it_chat/src/ui/chats/chats_screen.dart';
import 'package:it_chat/src/ui/chats/conversation_screen.dart';
import 'package:it_chat/src/ui/home/home_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:it_chat/l10n/generated/app_localizations.dart';

void main() {
  test('restores saved theme preference', () async {
    SharedPreferences.setMockInitialValues(
        {'darkMode': true, 'language': 'Татарский'});
    final state = AppState();
    await state.restoreSession();
    expect(state.darkMode, isTrue);
    expect(state.language, 'Татарский');
    expect(state.initializing, isFalse);
  });

  test('loads regional translations and maps the selected locale', () async {
    expect(lookupAppLocalizations(const Locale('tt')).settings, 'Көйләүләр');
    expect(lookupAppLocalizations(const Locale('ba')).chats, 'Чаттар');
    expect(lookupAppLocalizations(const Locale('udm')).tasks, 'Ужпумъёс');
    final state = AppState();
    await state.setLanguage('Башкирский');
    expect(state.locale.languageCode, 'ba');
  });

  testWidgets('shows Firebase unavailable without platform config',
      (tester) async {
    app.main();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('emailField')), findsOneWidget);
    await tester.enterText(
        find.byKey(const Key('emailField')), 'user@example.com');
    await tester.enterText(find.byKey(const Key('passwordField')), 'password');
    await tester.tap(find.byKey(const Key('authSubmit')));
    await tester.pumpAndSettle();
    expect(find.text('Firebase недоступен на этой платформе'), findsOneWidget);
  });

  testWidgets('auth screen keeps readable colors in dark theme',
      (tester) async {
    final state = AppState()..darkMode = true;
    await tester.pumpWidget(AppStateScope(
      notifier: state,
      child: MaterialApp(
        theme: buildTheme(),
        darkTheme: buildDarkTheme(),
        themeMode: ThemeMode.dark,
        home: const EmailAuthScreen(),
      ),
    ));
    final context = tester.element(find.byType(EmailAuthScreen));
    final scheme = Theme.of(context).colorScheme;
    final logo = tester.widget<RichText>(find.byKey(const Key('authLogo')));
    final subtitle = tester.widget<Text>(find.byKey(const Key('authSubtitle')));
    expect((logo.text as TextSpan).style?.color, scheme.onSurface);
    expect(subtitle.style?.color, scheme.onSurfaceVariant);
  });

  testWidgets('opens burger menu and profile without stories', (tester) async {
    final state = AppState()
      ..isAuthenticated = true
      ..profileComplete = true
      ..username = 'reunionrs'
      ..displayName = 'Илья';
    await tester.pumpWidget(AppStateScope(
      notifier: state,
      child: MaterialApp(theme: buildTheme(), home: const HomeShell()),
    ));

    expect(find.byTooltip('Меню'), findsOneWidget);
    await tester.tap(find.byTooltip('Меню'));
    await tester.pumpAndSettle();
    expect(find.text('Мой профиль'), findsOneWidget);

    await tester.tap(find.text('Мой профиль'));
    await tester.pumpAndSettle();
    expect(find.text('Профиль'), findsOneWidget);
    expect(find.text('Stories'), findsNothing);
    expect(find.text('Firebase Spark · e-mail и пароль · без платных SMS'),
        findsNothing);
  });

  testWidgets('chats hide fixed category tabs on every width', (tester) async {
    final state = AppState();
    await tester.pumpWidget(AppStateScope(
      notifier: state,
      child: MaterialApp(
          theme: buildTheme(), home: const Scaffold(body: ChatsScreen())),
    ));
    await tester.pump();
    expect(find.text('Соединение…'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('Команда'), findsNothing);
    expect(find.text('Проекты'), findsNothing);
    expect(find.text('Личные'), findsNothing);
    tester.view.physicalSize = const Size(1200, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pump();
    expect(find.text('Команда'), findsNothing);
    expect(find.text('Проекты'), findsNothing);
    expect(find.text('Личные'), findsNothing);
  });

  testWidgets('chat streams stay subscribed during fast rebuilds',
      (tester) async {
    final state = _CountingAppState();
    await tester.pumpWidget(AppStateScope(
      notifier: state,
      child: MaterialApp(
          theme: buildTheme(), home: const Scaffold(body: ChatsScreen())),
    ));
    await tester.enterText(find.byType(TextField), 'a');
    await tester.enterText(find.byType(TextField), 'ab');
    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    expect(state.folderSubscriptions, 1);
    expect(state.chatSubscriptions, 1);
  });

  testWidgets('short mobile messages keep content width', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = AppState()
      ..messages.add(
          ChatMessage(author: 'Вы', text: 'Ок', time: '20:34', mine: true));
    await tester.pumpWidget(AppStateScope(
      notifier: state,
      child: MaterialApp(
        theme: buildTheme(),
        home: const ConversationScreen(title: 'Чат'),
      ),
    ));
    await tester.pumpAndSettle();
    final bubble = find
        .ancestor(of: find.text('Ок'), matching: find.byType(Container))
        .first;
    expect(tester.getSize(bubble).width, lessThan(200));
  });

  testWidgets('task board dialog closes without framework assertion',
      (tester) async {
    final state = AppState()
      ..isAuthenticated = true
      ..profileComplete = true
      ..username = 'reunionrs'
      ..displayName = 'Илья';
    await tester.pumpWidget(AppStateScope(
      notifier: state,
      child: MaterialApp(theme: buildTheme(), home: const HomeShell()),
    ));
    await tester.tap(find.byTooltip('Меню'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Задачи'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Создать доску'));
    await tester.pumpAndSettle();
    expect(find.text('Новая доска задач'), findsOneWidget);
    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  test('task creator can delete own task without full board access', () {
    final board = TaskBoard(
      id: 'board',
      title: 'Доска',
      color: Colors.blue,
      memberIds: {'creator'},
      tasks: const [],
      accessByMember: {'creator': BoardAccess.edit},
    );
    final task = BoardTask(
      id: 'task',
      title: 'Задача',
      assignee: 'Автор',
      status: TaskStatus.todo,
      priority: 'Средний',
      createdBy: 'creator',
      imageBase64: '',
    );
    expect(board.canDeleteTask('creator', task), isTrue);
    expect(board.canDeleteTask('another-user', task), isFalse);
  });
}

class _CountingAppState extends AppState {
  int folderSubscriptions = 0;
  int chatSubscriptions = 0;

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> chatFolders() {
    folderSubscriptions++;
    return const Stream.empty();
  }

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> directChats() {
    chatSubscriptions++;
    return const Stream.empty();
  }
}
