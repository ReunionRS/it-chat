import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import '../../theme.dart';

class EmailAuthScreen extends StatefulWidget {
  const EmailAuthScreen({super.key});
  @override
  State<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends State<EmailAuthScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool register = false, obscure = true, confirmationSent = false;
  String? error;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email.text)) {
      setState(() => error = 'Введите корректный e-mail');
      return;
    }
    if (password.text.length < 6) {
      setState(() => error = 'Пароль должен содержать минимум 6 символов');
      return;
    }
    final state = AppStateScope.of(context);
    final ok = confirmationSent
        ? await state.confirmEmail()
        : register
            ? await state.register(email.text.trim(), password.text)
            : await state.signIn(email.text.trim(), password.text);
    if (!mounted) return;
    setState(() {
      if (register && ok && !confirmationSent) confirmationSent = true;
      error = state.error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
        body: SafeArea(
            child: Center(
                child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Align(
                                  child: Container(
                                      width: 76,
                                      height: 76,
                                      decoration: BoxDecoration(
                                          color: brandBlue.withOpacity(.1),
                                          borderRadius:
                                              BorderRadius.circular(24)),
                                      child: Icon(
                                          confirmationSent
                                              ? Icons.mark_email_read_outlined
                                              : Icons.forum_rounded,
                                          color: brandBlue,
                                          size: 38))),
                              const SizedBox(height: 22),
                              RichText(
                                  key: const Key('authLogo'),
                                  textAlign: TextAlign.center,
                                  text: TextSpan(
                                      style: TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.w800,
                                          color: scheme.onSurface),
                                      children: const [
                                        TextSpan(text: 'IT '),
                                        TextSpan(
                                            text: 'Chat',
                                            style: TextStyle(color: brandBlue))
                                      ])),
                              const SizedBox(height: 10),
                              Text(
                                  confirmationSent
                                      ? 'Подтвердите e-mail'
                                      : 'Чаты и задачи — в одном месте',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 8),
                              Text(
                                  confirmationSent
                                      ? 'Мы отправили ссылку подтверждения на\n${email.text}'
                                      : 'Рабочее пространство вашей команды',
                                  key: const Key('authSubtitle'),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: scheme.onSurfaceVariant,
                                      height: 1.4)),
                              const SizedBox(height: 28),
                              if (!confirmationSent) ...[
                                Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                        color: scheme.surfaceContainerHighest,
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    child: Row(children: [
                                      Expanded(
                                          child: _ModeButton(
                                              'Вход',
                                              !register,
                                              () => setState(
                                                  () => register = false))),
                                      Expanded(
                                          child: _ModeButton(
                                              'Регистрация',
                                              register,
                                              () => setState(
                                                  () => register = true)))
                                    ])),
                                const SizedBox(height: 20),
                                const Text('E-mail',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 7),
                                TextField(
                                    key: const Key('emailField'),
                                    controller: email,
                                    keyboardType: TextInputType.emailAddress,
                                    autofillHints: const [AutofillHints.email],
                                    decoration: const InputDecoration(
                                        prefixIcon: Icon(Icons.mail_outline),
                                        hintText: 'name@company.ru')),
                                const SizedBox(height: 14),
                                const Text('Пароль',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 7),
                                TextField(
                                    key: const Key('passwordField'),
                                    controller: password,
                                    obscureText: obscure,
                                    autofillHints: const [
                                      AutofillHints.password
                                    ],
                                    decoration: InputDecoration(
                                        prefixIcon:
                                            const Icon(Icons.lock_outline),
                                        suffixIcon: IconButton(
                                            onPressed: () => setState(
                                                () => obscure = !obscure),
                                            icon: Icon(obscure
                                                ? Icons.visibility_outlined
                                                : Icons
                                                    .visibility_off_outlined)))),
                              ] else
                                Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                        color: brandBlue.withOpacity(.08),
                                        borderRadius:
                                            BorderRadius.circular(14)),
                                    child: const Text(
                                        'Откройте ссылку из письма, затем вернитесь в приложение.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            color: brandBlue,
                                            fontWeight: FontWeight.w600))),
                              if (error != null)
                                Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: Text(error!,
                                        key: const Key('authError'),
                                        style: const TextStyle(
                                            color: Colors.red))),
                              const SizedBox(height: 18),
                              FilledButton(
                                  key: const Key('authSubmit'),
                                  onPressed: state.busy ? null : submit,
                                  child: Text(state.busy
                                      ? 'Подождите…'
                                      : confirmationSent
                                          ? 'Я подтвердил e-mail'
                                          : register
                                              ? 'Зарегистрироваться'
                                              : 'Войти')),
                              if (confirmationSent)
                                TextButton(
                                    onPressed: () => setState(
                                        () => confirmationSent = false),
                                    child: const Text('Изменить e-mail')),
                            ]))))));
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton(this.text, this.selected, this.onTap);
  final String text;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
              color: selected ? brandBlue : Colors.transparent,
              borderRadius: BorderRadius.circular(9)),
          child: Text(text,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: selected
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700))));
}
