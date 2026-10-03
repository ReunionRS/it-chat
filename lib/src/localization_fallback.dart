import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

const _additionalLanguages = {'udm', 'tt', 'ba'};

class AdditionalMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const AdditionalMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      _additionalLanguages.contains(locale.languageCode);

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      GlobalMaterialLocalizations.delegate.load(const Locale('ru'));

  @override
  bool shouldReload(
          covariant LocalizationsDelegate<MaterialLocalizations> old) =>
      false;
}

class AdditionalCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const AdditionalCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      _additionalLanguages.contains(locale.languageCode);

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      GlobalCupertinoLocalizations.delegate.load(const Locale('ru'));

  @override
  bool shouldReload(
          covariant LocalizationsDelegate<CupertinoLocalizations> old) =>
      false;
}
