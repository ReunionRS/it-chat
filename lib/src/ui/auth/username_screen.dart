import 'package:flutter/material.dart';

import '../../state/app_state.dart';

class UsernameScreen extends StatefulWidget {
  const UsernameScreen({super.key});
  @override
  State<UsernameScreen> createState() => _UsernameScreenState();
}

class _UsernameScreenState extends State<UsernameScreen> {
  final controller = TextEditingController();
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    return Scaffold(
        body: Center(
            child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const CircleAvatar(
                              radius: 38,
                              backgroundColor: Color(0xFF2AABEE),
                              child: Icon(Icons.alternate_email,
                                  size: 38, color: Colors.white)),
                          const SizedBox(height: 24),
                          const Text('Придумайте @username',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 27, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 10),
                          const Text(
                              'По нему коллеги смогут найти вас в контактах. Изменить имя можно будет позже.',
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(color: Colors.grey, height: 1.45)),
                          const SizedBox(height: 28),
                          TextField(
                              controller: controller,
                              autofocus: true,
                              autocorrect: false,
                              textCapitalization: TextCapitalization.none,
                              decoration: const InputDecoration(
                                  prefixText: '@ ', hintText: 'username')),
                          if (state.error != null)
                            Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Text(state.error!,
                                    style: const TextStyle(color: Colors.red))),
                          const SizedBox(height: 18),
                          FilledButton(
                              onPressed: state.busy
                                  ? null
                                  : () => state.saveUsername(controller.text),
                              child: Text(
                                  state.busy ? 'Проверяем…' : 'Продолжить')),
                          const SizedBox(height: 10),
                          TextButton(
                              onPressed: state.signOut,
                              child: const Text('Выйти из аккаунта')),
                        ])))));
  }
}
