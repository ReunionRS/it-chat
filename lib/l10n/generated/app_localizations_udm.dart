import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

/// The translations for Udmurt (`udm`).
class AppLocalizationsUdm extends AppLocalizations {
  AppLocalizationsUdm([String locale = 'udm']) : super(locale);

  @override
  String get appTitle => 'IT Chat';

  @override
  String get tagline => 'Чатъёс но ужъёс — одӥг интыын';

  @override
  String get workspace => 'Тӥляд командалэн уж интыез';

  @override
  String get profile => 'Профиль';

  @override
  String get wait => 'Возьматы…';

  @override
  String get registerAction => 'Регистраци лэсьтыны';

  @override
  String get myProfile => 'Мынам профиль';

  @override
  String get chats => 'Чатъёс';

  @override
  String get createGroup => 'Группа лэсьтыны';

  @override
  String get contacts => 'Контактъёс';

  @override
  String get tasks => 'Ужпумъёс';

  @override
  String get settings => 'Настройкаос';

  @override
  String get darkTheme => 'Сӧд тема';

  @override
  String get signOut => 'Потыны';

  @override
  String get notifications => 'Юнматонъёс';

  @override
  String get language => 'Кыл';

  @override
  String get help => 'Валэктон';

  @override
  String get chooseLanguage => 'Кыл бырйы';

  @override
  String get russian => 'Ӟуч кыл';

  @override
  String get english => 'Англи кыл';

  @override
  String get udmurt => 'Удмурт кыл';

  @override
  String get tatar => 'Татар кыл';

  @override
  String get bashkir => 'Башкир кыл';

  @override
  String get connecting => 'Герӟаськон…';

  @override
  String get updating => 'Выльматон…';

  @override
  String get searchChats => 'Чатъёсты утчаны';

  @override
  String get noChats => 'Чатъёс на ӧвӧл';

  @override
  String get findContact => 'Контакт утча но вераськон кутски';

  @override
  String get noBoards => 'Доскаос на ӧвӧл';

  @override
  String get createFirstBoard => 'Нырысетӥ ужъёс доскаез лэсьты';

  @override
  String get createBoard => 'Доска лэсьтыны';

  @override
  String get newTask => 'Выль уж';

  @override
  String participants(int count) {
    return '$count эшъёс';
  }

  @override
  String get login => 'Пырон';

  @override
  String get registration => 'Регистрация';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Пароль';

  @override
  String get signIn => 'Пырыны';
}
