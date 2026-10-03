import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'IT Chat';

  @override
  String get tagline => 'Chats and tasks in one place';

  @override
  String get workspace => 'Your team\'s workspace';

  @override
  String get profile => 'Profile';

  @override
  String get wait => 'Please wait…';

  @override
  String get registerAction => 'Create account';

  @override
  String get myProfile => 'My profile';

  @override
  String get chats => 'Chats';

  @override
  String get createGroup => 'Create group';

  @override
  String get contacts => 'Contacts';

  @override
  String get tasks => 'Tasks';

  @override
  String get settings => 'Settings';

  @override
  String get darkTheme => 'Dark theme';

  @override
  String get signOut => 'Sign out';

  @override
  String get notifications => 'Notifications';

  @override
  String get language => 'Language';

  @override
  String get help => 'Help';

  @override
  String get chooseLanguage => 'Choose a language';

  @override
  String get russian => 'Russian';

  @override
  String get english => 'English';

  @override
  String get udmurt => 'Udmurt';

  @override
  String get tatar => 'Tatar';

  @override
  String get bashkir => 'Bashkir';

  @override
  String get connecting => 'Connecting…';

  @override
  String get updating => 'Updating…';

  @override
  String get searchChats => 'Search chats';

  @override
  String get noChats => 'No chats yet';

  @override
  String get findContact => 'Find a contact and start a conversation';

  @override
  String get noBoards => 'No boards yet';

  @override
  String get createFirstBoard => 'Create your first task board';

  @override
  String get createBoard => 'Create board';

  @override
  String get newTask => 'New task';

  @override
  String participants(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count participants',
      one: '1 participant',
      zero: 'No participants',
    );
    return '$_temp0';
  }

  @override
  String get login => 'Sign in';

  @override
  String get registration => 'Register';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Password';

  @override
  String get signIn => 'Sign in';
}
