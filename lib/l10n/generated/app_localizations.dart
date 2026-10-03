import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ba.dart';
import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_tt.dart';
import 'app_localizations_udm.dart';

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ba'),
    Locale('en'),
    Locale('ru'),
    Locale('tt'),
    Locale('udm')
  ];

  /// No description provided for @appTitle.
  ///
  /// In ru, this message translates to:
  /// **'IT Chat'**
  String get appTitle;

  /// No description provided for @tagline.
  ///
  /// In ru, this message translates to:
  /// **'Чаты и задачи — в одном месте'**
  String get tagline;

  /// No description provided for @workspace.
  ///
  /// In ru, this message translates to:
  /// **'Рабочее пространство вашей команды'**
  String get workspace;

  /// No description provided for @profile.
  ///
  /// In ru, this message translates to:
  /// **'Профиль'**
  String get profile;

  /// No description provided for @wait.
  ///
  /// In ru, this message translates to:
  /// **'Подождите…'**
  String get wait;

  /// No description provided for @registerAction.
  ///
  /// In ru, this message translates to:
  /// **'Зарегистрироваться'**
  String get registerAction;

  /// No description provided for @myProfile.
  ///
  /// In ru, this message translates to:
  /// **'Мой профиль'**
  String get myProfile;

  /// No description provided for @chats.
  ///
  /// In ru, this message translates to:
  /// **'Чаты'**
  String get chats;

  /// No description provided for @createGroup.
  ///
  /// In ru, this message translates to:
  /// **'Создать группу'**
  String get createGroup;

  /// No description provided for @contacts.
  ///
  /// In ru, this message translates to:
  /// **'Контакты'**
  String get contacts;

  /// No description provided for @tasks.
  ///
  /// In ru, this message translates to:
  /// **'Задачи'**
  String get tasks;

  /// No description provided for @settings.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get settings;

  /// No description provided for @darkTheme.
  ///
  /// In ru, this message translates to:
  /// **'Тёмная тема'**
  String get darkTheme;

  /// No description provided for @signOut.
  ///
  /// In ru, this message translates to:
  /// **'Выйти'**
  String get signOut;

  /// No description provided for @notifications.
  ///
  /// In ru, this message translates to:
  /// **'Уведомления'**
  String get notifications;

  /// No description provided for @language.
  ///
  /// In ru, this message translates to:
  /// **'Язык'**
  String get language;

  /// No description provided for @help.
  ///
  /// In ru, this message translates to:
  /// **'Помощь'**
  String get help;

  /// No description provided for @chooseLanguage.
  ///
  /// In ru, this message translates to:
  /// **'Выберите язык'**
  String get chooseLanguage;

  /// No description provided for @russian.
  ///
  /// In ru, this message translates to:
  /// **'Русский'**
  String get russian;

  /// No description provided for @english.
  ///
  /// In ru, this message translates to:
  /// **'Английский'**
  String get english;

  /// No description provided for @udmurt.
  ///
  /// In ru, this message translates to:
  /// **'Удмуртский'**
  String get udmurt;

  /// No description provided for @tatar.
  ///
  /// In ru, this message translates to:
  /// **'Татарский'**
  String get tatar;

  /// No description provided for @bashkir.
  ///
  /// In ru, this message translates to:
  /// **'Башкирский'**
  String get bashkir;

  /// No description provided for @connecting.
  ///
  /// In ru, this message translates to:
  /// **'Соединение…'**
  String get connecting;

  /// No description provided for @updating.
  ///
  /// In ru, this message translates to:
  /// **'Обновление…'**
  String get updating;

  /// No description provided for @searchChats.
  ///
  /// In ru, this message translates to:
  /// **'Поиск по чатам'**
  String get searchChats;

  /// No description provided for @noChats.
  ///
  /// In ru, this message translates to:
  /// **'Чатов пока нет'**
  String get noChats;

  /// No description provided for @findContact.
  ///
  /// In ru, this message translates to:
  /// **'Найдите контакт и начните переписку'**
  String get findContact;

  /// No description provided for @noBoards.
  ///
  /// In ru, this message translates to:
  /// **'Досок пока нет'**
  String get noBoards;

  /// No description provided for @createFirstBoard.
  ///
  /// In ru, this message translates to:
  /// **'Создайте первую доску задач'**
  String get createFirstBoard;

  /// No description provided for @createBoard.
  ///
  /// In ru, this message translates to:
  /// **'Создать доску'**
  String get createBoard;

  /// No description provided for @newTask.
  ///
  /// In ru, this message translates to:
  /// **'Новая задача'**
  String get newTask;

  /// No description provided for @participants.
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, =0{Нет участников} =1{1 участник} other{{count} участников}}'**
  String participants(int count);

  /// No description provided for @login.
  ///
  /// In ru, this message translates to:
  /// **'Вход'**
  String get login;

  /// No description provided for @registration.
  ///
  /// In ru, this message translates to:
  /// **'Регистрация'**
  String get registration;

  /// No description provided for @email.
  ///
  /// In ru, this message translates to:
  /// **'E-mail'**
  String get email;

  /// No description provided for @password.
  ///
  /// In ru, this message translates to:
  /// **'Пароль'**
  String get password;

  /// No description provided for @signIn.
  ///
  /// In ru, this message translates to:
  /// **'Войти'**
  String get signIn;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ba', 'en', 'ru', 'tt', 'udm'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ba': return AppLocalizationsBa();
    case 'en': return AppLocalizationsEn();
    case 'ru': return AppLocalizationsRu();
    case 'tt': return AppLocalizationsTt();
    case 'udm': return AppLocalizationsUdm();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
