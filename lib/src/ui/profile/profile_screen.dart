import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../../theme.dart';
import '../../../l10n/generated/app_localizations.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController name;
  late final TextEditingController bio;
  Uint8List? selectedAvatar;
  String? validationError;
  bool initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (initialized) return;
    final state = AppStateScope.of(context);
    name = TextEditingController(text: state.displayName);
    bio = TextEditingController(text: state.bio);
    initialized = true;
  }

  @override
  void dispose() {
    name.dispose();
    bio.dispose();
    super.dispose();
  }

  Future<void> pickAvatar() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (!mounted || result == null) return;
    final bytes = result.files.single.bytes;
    if (bytes == null) {
      setState(() => validationError = 'Не удалось прочитать изображение');
      return;
    }
    if (bytes.length > 500 * 1024) {
      setState(
          () => validationError = 'Выберите изображение размером до 500 КБ');
      return;
    }
    setState(() {
      selectedAvatar = bytes;
      validationError = null;
    });
  }

  Future<void> save() async {
    final state = AppStateScope.of(context);
    final ok = await state.saveProfile(
      name: name.text,
      about: bio.text,
      avatar: selectedAvatar == null ? null : base64Encode(selectedAvatar!),
    );
    if (!mounted) return;
    setState(() => validationError = state.error);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Профиль сохранён')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final strings = AppLocalizations.of(context) ??
        lookupAppLocalizations(const Locale('ru'));
    final storedAvatar =
        state.avatarBase64.isEmpty ? null : base64Decode(state.avatarBase64);
    final avatar = selectedAvatar ?? storedAvatar;
    return Scaffold(
      appBar: AppBar(
        leading: widget.onBack == null
            ? null
            : IconButton(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back),
              ),
        title: Text(strings.profile),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 58,
                        backgroundColor: brandBlue.withOpacity(.14),
                        backgroundImage:
                            avatar == null ? null : MemoryImage(avatar),
                        child: avatar == null
                            ? Text(
                                state.username.isEmpty
                                    ? '@'
                                    : state.username[0].toUpperCase(),
                                style: const TextStyle(
                                  color: brandBlue,
                                  fontSize: 36,
                                  fontWeight: FontWeight.w800,
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        right: -4,
                        bottom: -2,
                        child: IconButton.filled(
                          tooltip: 'Выбрать изображение',
                          onPressed: pickAvatar,
                          icon: const Icon(Icons.photo_camera_outlined),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '@${state.username}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 28),
                TextField(
                  controller: name,
                  maxLength: 50,
                  decoration: const InputDecoration(
                    labelText: 'Имя',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bio,
                  minLines: 3,
                  maxLines: 5,
                  maxLength: 160,
                  decoration: const InputDecoration(
                    labelText: 'О себе',
                    hintText: 'Должность, команда или несколько слов о себе',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.info_outline),
                  ),
                ),
                if (validationError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      validationError!,
                      style:
                          TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                FilledButton.icon(
                  onPressed: state.busy ? null : save,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(state.busy ? 'Сохраняем…' : 'Сохранить'),
                ),
                const SizedBox(height: 10),
                Text(
                  'Поддерживаются изображения до 500 КБ.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
