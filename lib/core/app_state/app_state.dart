// lib/core/app_state/app_state.dart

import 'package:flutter/material.dart';
import 'package:gestion_ecole/config/app_logger.dart';
import 'package:gestion_ecole/core/constants/app_constants.dart';
import 'package:gestion_ecole/core/preferences/app_preferences.dart';

class AppState extends ChangeNotifier {
  static final AppState _instance = AppState._internal();
  AppState._internal();
  factory AppState() => _instance;

  bool _estEnModeSombre = false;
  bool get estEnModeSombre => _estEnModeSombre;

  ThemeMode? themeMode;

  void update(VoidCallback callBack) {
    callBack();
    notifyListeners();
  }

  Future<void> initialiser() async {
    await AppPreferences.init();
    themeMode = themeChoisi();
    _estEnModeSombre = themeMode == ThemeMode.dark;
    AppLogger.info('Thème chargé : $themeMode');
    notifyListeners();
  }

  void basculerModeSombre() {
    _estEnModeSombre = !_estEnModeSombre;
    final themePref = _estEnModeSombre
        ? AppConstants.themeSombre
        : AppConstants.themeClair;
    AppPreferences.prefs.setString(AppConstants.cleTheme, themePref);
    themeMode = themeChoisi();
    notifyListeners();
  }

  set estEnModeSombre(bool value) {
    _estEnModeSombre = value;
    notifyListeners();
  }

  ThemeMode themeChoisi() {
    final themePref = AppPreferences.getString(AppConstants.cleTheme);
    if (themePref == AppConstants.themeSombre) return ThemeMode.dark;
    return ThemeMode.light;
  }

  void forcerModeClair() {
    _estEnModeSombre = false;
    themeMode = ThemeMode.light;
    AppPreferences.prefs.setString(
      AppConstants.cleTheme,
      AppConstants.themeClair,
    );
    notifyListeners();
  }

  void forcerModeSombre() {
    _estEnModeSombre = true;
    themeMode = ThemeMode.dark;
    AppPreferences.prefs.setString(
      AppConstants.cleTheme,
      AppConstants.themeSombre,
    );
    notifyListeners();
  }
}
