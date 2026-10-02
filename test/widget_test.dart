import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:it_chat/main.dart' as app;
import 'package:it_chat/src/state/app_state.dart';
import 'package:it_chat/src/theme.dart';
import 'package:it_chat/src/ui/home/home_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('restores saved theme preference', () async {
    SharedPreferences.setMockInitialValues({'darkMode': true});
    final state = AppState();
    await state.restoreSession();
    expect(state.darkMode, isTrue);
    expect(state.initializing, isFalse);
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
}
