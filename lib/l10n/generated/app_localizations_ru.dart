import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'IT Chat';

  @override
  String get tagline => 'Чаты и задачи — в одном месте';

  @override
  String get workspace => 'Рабочее пространство вашей команды';

  @override
  String get profile => 'Профиль';

  @override
  String get wait => 'Подождите…';

  @override
  String get registerAction => 'Зарегистрироваться';

  @override
  String get myProfile => 'Мой профиль';

  @override
  String get chats => 'Чаты';

  @override
  String get createGroup => 'Создать группу';

  @override
  String get contacts => 'Контакты';

  @override
  String get tasks => 'Задачи';

  @override
  String get settings => 'Настройки';

  @override
  String get darkTheme => 'Тёмная тема';

  @override
  String get signOut => 'Выйти';

  @override
  String get notifications => 'Уведомления';

  @override
  String get language => 'Язык';

  @override
  String get help => 'Помощь';

  @override
  String get chooseLanguage => 'Выберите язык';

  @override
  String get russian => 'Русский';

  @override
  String get english => 'Английский';

  @override
  String get udmurt => 'Удмуртский';

  @override
  String get tatar => 'Татарский';

  @override
  String get bashkir => 'Башкирский';

  @override
  String get connecting => 'Соединение…';

  @override
  String get updating => 'Обновление…';

  @override
  String get searchChats => 'Поиск по чатам';

  @override
  String get noChats => 'Чатов пока нет';

  @override
  String get findContact => 'Найдите контакт и начните переписку';

  @override
  String get noBoards => 'Досок пока нет';

  @override
  String get createFirstBoard => 'Создайте первую доску задач';

  @override
  String get createBoard => 'Создать доску';

  @override
  String get newTask => 'Новая задача';

  @override
  String participants(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count участников',
      one: '1 участник',
      zero: 'Нет участников',
    );
    return '$_temp0';
  }

  @override
  String get login => 'Вход';

  @override
  String get registration => 'Регистрация';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Пароль';

  @override
  String get signIn => 'Войти';
}
