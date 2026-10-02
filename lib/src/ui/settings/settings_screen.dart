import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, this.onMenuPressed});
  final VoidCallback? onMenuPressed;
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notifications = false, compact = false;
  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
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
        Text('Настройки',
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
                title: const Text('Уведомления')),
            const Divider(height: 1),
            SwitchListTile(
                value: appState.darkMode,
                onChanged: appState.toggleTheme,
                secondary:
                    const Icon(Icons.dark_mode_outlined, color: brandBlue),
                title: const Text('Тёмная тема')),
            const Divider(height: 1),
            SwitchListTile(
                value: compact,
                onChanged: (v) => setState(() => compact = v),
                secondary: const Icon(Icons.density_small, color: brandBlue),
                title: const Text('Компактный режим'))
          ])),
      const SizedBox(height: 12),
      const Card(
          elevation: 0,
          child: Column(children: [
            ListTile(
                leading: Icon(Icons.lock_outline, color: brandBlue),
                title: Text('Конфиденциальность'),
                trailing: Icon(Icons.chevron_right)),
            Divider(height: 1),
            ListTile(
                leading: Icon(Icons.help_outline, color: brandBlue),
                title: Text('Помощь'),
                trailing: Icon(Icons.chevron_right))
          ])),
      const SizedBox(height: 20),
      OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              minimumSize: const Size.fromHeight(50)),
          onPressed: appState.signOut,
          icon: const Icon(Icons.logout),
          label: const Text('Выйти')),
    ]));
  }
}
