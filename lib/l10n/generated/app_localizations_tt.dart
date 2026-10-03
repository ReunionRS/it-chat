import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

/// The translations for Tatar (`tt`).
class AppLocalizationsTt extends AppLocalizations {
  AppLocalizationsTt([String locale = 'tt']) : super(locale);

  @override
  String get appTitle => 'IT Chat';

  @override
  String get tagline => 'Чатлар һәм бурычлар — бер урында';

  @override
  String get workspace => 'Сезнең төркемнең эш киңлеге';

  @override
  String get profile => 'Профиль';

  @override
  String get wait => 'Көтегез…';

  @override
  String get registerAction => 'Теркәлү';

  @override
  String get myProfile => 'Минем профиль';

  @override
  String get chats => 'Чатлар';

  @override
  String get createGroup => 'Төркем төзү';

  @override
  String get contacts => 'Контактлар';

  @override
  String get tasks => 'Бурычлар';

  @override
  String get settings => 'Көйләүләр';

  @override
  String get darkTheme => 'Караңгы тема';

  @override
  String get signOut => 'Чыгу';

  @override
  String get notifications => 'Белдерүләр';

  @override
  String get language => 'Тел';

  @override
  String get help => 'Ярдәм';

  @override
  String get chooseLanguage => 'Телне сайлагыз';

  @override
  String get russian => 'Рус теле';

  @override
  String get english => 'Инглиз теле';

  @override
  String get udmurt => 'Удмурт теле';

  @override
  String get tatar => 'Татар теле';

  @override
  String get bashkir => 'Башкорт теле';

  @override
  String get connecting => 'Тоташу…';

  @override
  String get updating => 'Яңарту…';

  @override
  String get searchChats => 'Чатларны эзләү';

  @override
  String get noChats => 'Чатлар әлегә юк';

  @override
  String get findContact => 'Контакт табыгыз һәм сөйләшүне башлагыз';

  @override
  String get noBoards => 'Такталар әлегә юк';

  @override
  String get createFirstBoard => 'Беренче бурыч тактасын төзегез';

  @override
  String get createBoard => 'Такта төзү';

  @override
  String get newTask => 'Яңа бурыч';

  @override
  String participants(int count) {
    return '$count катнашучы';
  }

  @override
  String get login => 'Керү';

  @override
  String get registration => 'Теркәлү';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Серсүз';

  @override
  String get signIn => 'Керү';
}
