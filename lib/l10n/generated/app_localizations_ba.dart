import 'app_localizations.dart';

/// The translations for Bashkir (`ba`).
class AppLocalizationsBa extends AppLocalizations {
  AppLocalizationsBa([String locale = 'ba']) : super(locale);

  @override
  String get appTitle => 'IT Chat';

  @override
  String get tagline => 'Чаттар һәм бурыстар — бер урында';

  @override
  String get workspace => 'Төркөмөгөҙҙөң эш киңлеге';

  @override
  String get profile => 'Профиль';

  @override
  String get wait => 'Көтөгөҙ…';

  @override
  String get registerAction => 'Теркәлергә';

  @override
  String get myProfile => 'Минең профилем';

  @override
  String get chats => 'Чаттар';

  @override
  String get createGroup => 'Төркөм булдырыу';

  @override
  String get contacts => 'Бәйләнештәр';

  @override
  String get tasks => 'Бурыстар';

  @override
  String get settings => 'Көйләүҙәр';

  @override
  String get darkTheme => 'Ҡараңғы тема';

  @override
  String get signOut => 'Сығыу';

  @override
  String get notifications => 'Белдереүҙәр';

  @override
  String get language => 'Тел';

  @override
  String get help => 'Ярзам';

  @override
  String get chooseLanguage => 'Телде һайлағыҙ';

  @override
  String get russian => 'Урыҫ теле';

  @override
  String get english => 'Инглиз теле';

  @override
  String get udmurt => 'Удмурт теле';

  @override
  String get tatar => 'Татар теле';

  @override
  String get bashkir => 'Башҡорт теле';

  @override
  String get connecting => 'Тоташыу…';

  @override
  String get updating => 'Яңыртыу…';

  @override
  String get searchChats => 'Чаттарҙы эҙләү';

  @override
  String get noChats => 'Чаттар әлегә юҡ';

  @override
  String get findContact => 'Бәйләнеш табығыҙ һәм һөйләшеүҙе башлағыҙ';

  @override
  String get noBoards => 'Таҡталар әлегә юҡ';

  @override
  String get createFirstBoard => 'Беренсе бурыстар таҡтаһын булдырығыҙ';

  @override
  String get createBoard => 'Таҡта булдырыу';

  @override
  String get newTask => 'Яңы бурыс';

  @override
  String participants(int count) {
    return '$count ҡатнашыусы';
  }

  @override
  String get login => 'Инеү';

  @override
  String get registration => 'Теркәлеү';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Пароль';

  @override
  String get signIn => 'Инеү';
}
