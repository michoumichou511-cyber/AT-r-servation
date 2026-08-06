import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeSetting { light, dark, auto }

class ThemeProvider extends ChangeNotifier {
  ThemeSetting _setting = ThemeSetting.auto;
  bool _isDark = false;

  ThemeSetting get setting => _setting;
  bool get isDark => _isDark;
  ThemeMode get themeMode {
    switch (_setting) {
      case ThemeSetting.light: return ThemeMode.light;
      case ThemeSetting.dark:  return ThemeMode.dark;
      case ThemeSetting.auto:  return ThemeMode.system;
    }
  }

  ThemeProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('theme_setting') ?? 'auto';
    _setting = ThemeSetting.values.firstWhere(
      (e) => e.name == saved,
      orElse: () => ThemeSetting.auto,
    );
    _computeIsDark();
    notifyListeners();
  }

  void _computeIsDark() {
    switch (_setting) {
      case ThemeSetting.light:
        _isDark = false;
      case ThemeSetting.dark:
        _isDark = true;
      case ThemeSetting.auto:
        _isDark = SchedulerBinding.instance.platformDispatcher.platformBrightness
            == Brightness.dark;
    }
  }

  Future<void> setSetting(ThemeSetting s) async {
    _setting = s;
    _computeIsDark();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_setting', s.name);
  }

  void onPlatformBrightnessChanged() {
    if (_setting == ThemeSetting.auto) {
      _computeIsDark();
      notifyListeners();
    }
  }
}
