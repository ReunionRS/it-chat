import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../services/notification_service.dart';
import '../../../l10n/generated/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, this.onMenuPressed});
  final VoidCallback? onMenuPressed;
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notifications = false;
  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final strings = AppLocalizations.of(context) ??
        lookupAppLocalizations(const Locale('ru'));
    return SafeArea(
        child: ListView(padding: const EdgeInsets.all(20), children: [
      Row(children: [
        if (widget.onMenuPressed != null) ...[
          IconButton(
              tooltip: 'Меню',
              onPressed: widget.onMenuPressed,
              icon: const Icon(Icons.menu)),
          const SizedBox(width: 6),
        ],
        Text(strings.settings,
            style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface)),
      ]),
      const SizedBox(height: 5),
      Text('@${appState.username}', style: const TextStyle(color: Colors.grey)),
      const SizedBox(height: 16),
      Card(
          elevation: 0,
          child: Column(children: [
            SwitchListTile(
                value: notifications,
                onChanged: (v) async {
                  if (!v) {
                    setState(() => notifications = false);
                    return;
                  }
                  final state = AppStateScope.of(context);
                  if (!state.firebaseReady) {
                    setState(() => notifications = true);
                    return;
                  }
                  try {
                    final enabled = await NotificationService.enable();
                    if (!context.mounted) return;
                    setState(() => notifications = enabled);
                  } catch (_) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content:
                            Text('Не удалось подключить push-уведомления')));
                  }
                },
                secondary:
                    const Icon(Icons.notifications_outlined, color: brandBlue),
                title: Text(strings.notifications)),
            const Divider(height: 1),
            SwitchListTile(
                value: appState.darkMode,
                onChanged: appState.toggleTheme,
                secondary:
                    const Icon(Icons.dark_mode_outlined, color: brandBlue),
                title: Text(strings.darkTheme)),
            const Divider(height: 1),
            ListTile(
              onTap: () => _selectLanguage(context, appState),
              leading: const Icon(Icons.translate_rounded, color: brandBlue),
              title: Text(strings.language),
              subtitle: Text(_languageLabel(strings, appState.language)),
              trailing: const Icon(Icons.chevron_right),
            ),
          ])),
      const SizedBox(height: 12),
      Card(
          elevation: 0,
          child: Column(children: [
            ListTile(
                leading: const Icon(Icons.help_outline, color: brandBlue),
                title: Text(strings.help),
                trailing: const Icon(Icons.chevron_right))
          ])),
      const SizedBox(height: 20),
      OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              minimumSize: const Size.fromHeight(50)),
          onPressed: appState.signOut,
          icon: const Icon(Icons.logout),
          label: Text(strings.signOut)),
    ]));
  }

  Future<void> _selectLanguage(BuildContext context, AppState appState) async {
    const languages = [
      'Русский',
      'Английский',
      'Удмуртский',
      'Татарский',
      'Башкирский',
    ];
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                  (AppLocalizations.of(context) ??
                          lookupAppLocalizations(const Locale('ru')))
                      .chooseLanguage,
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
            for (final language in languages)
              ListTile(
                leading: Icon(
                  language == appState.language
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: language == appState.language ? brandBlue : null,
                ),
                title: Text(_languageLabel(
                    AppLocalizations.of(context) ??
                        lookupAppLocalizations(const Locale('ru')),
                    language)),
                onTap: () => Navigator.pop(sheetContext, language),
              ),
          ],
        ),
      ),
    );
    if (selected != null) await appState.setLanguage(selected);
  }

  String _languageLabel(AppLocalizations strings, String language) =>
      switch (language) {
        'Английский' => strings.english,
        'Удмуртский' => strings.udmurt,
        'Татарский' => strings.tatar,
        'Башкирский' => strings.bashkir,
        _ => strings.russian,
      };
}
