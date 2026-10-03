import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../l10n/generated/app_localizations.dart';
import 'state/app_state.dart';
import 'theme.dart';
import 'localization_fallback.dart';
import 'ui/auth/email_auth_screen.dart';
import 'ui/auth/username_screen.dart';
import 'ui/home/home_shell.dart';

class ItChatApp extends StatefulWidget {
  const ItChatApp({super.key, this.firebaseReady = false});
  final bool firebaseReady;
  @override
  State<ItChatApp> createState() => _ItChatAppState();
}

class _ItChatAppState extends State<ItChatApp> {
  late final AppState state;
  @override
  void initState() {
    super.initState();
    state = AppState(firebaseReady: widget.firebaseReady);
    state.restoreSession();
  }

  @override
  Widget build(BuildContext context) => AppStateScope(
        notifier: state,
        child: ListenableBuilder(
          listenable: state,
          builder: (_, __) => MaterialApp(
              title: 'IT Chat',
              debugShowCheckedModeBanner: false,
              theme: buildTheme(),
              darkTheme: buildDarkTheme(),
              themeMode: state.darkMode ? ThemeMode.dark : ThemeMode.light,
              locale: state.locale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                AdditionalMaterialLocalizationsDelegate(),
                AdditionalCupertinoLocalizationsDelegate(),
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: state.initializing
                  ? const Scaffold(
                      body: Center(child: CircularProgressIndicator()))
                  : !state.isAuthenticated
                      ? const EmailAuthScreen()
                      : state.profileComplete
                          ? const HomeShell()
                          : const UsernameScreen()),
        ),
      );
}
