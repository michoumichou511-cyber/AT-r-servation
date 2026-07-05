import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralise les preferences app : theme, langue, notifications.
/// Persiste via SharedPreferences. Notify les widgets via ChangeNotifier.
class AppPreferences extends ChangeNotifier {
  static const _kTheme   = 'pref_theme';        // 'light' | 'dark'
  static const _kLocale  = 'pref_locale';       // 'fr' | 'ar'
  static const _kNotifMissions    = 'pref_notif_missions';
  static const _kNotifValidations = 'pref_notif_validations';
  static const _kNotifMessages    = 'pref_notif_messages';
  static const _kNotifSysteme     = 'pref_notif_systeme';

  late SharedPreferences _prefs;

  // Valeurs courantes (avec defaults)
  ThemeMode _themeMode = ThemeMode.light;
  Locale    _locale    = const Locale('fr');
  bool _notifMissions    = true;
  bool _notifValidations = true;
  bool _notifMessages    = true;
  bool _notifSysteme     = false;

  // Getters
  ThemeMode get themeMode    => _themeMode;
  Locale    get locale       => _locale;
  bool get isDark            => _themeMode == ThemeMode.dark;
  bool get isArabic          => _locale.languageCode == 'ar';
  bool get notifMissions     => _notifMissions;
  bool get notifValidations  => _notifValidations;
  bool get notifMessages     => _notifMessages;
  bool get notifSysteme      => _notifSysteme;

  /// Charge les preferences au demarrage.
  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();

    final t = _prefs.getString(_kTheme) ?? 'light';
    _themeMode = (t == 'dark') ? ThemeMode.dark : ThemeMode.light;

    final l = _prefs.getString(_kLocale) ?? 'fr';
    _locale = Locale(l);

    _notifMissions    = _prefs.getBool(_kNotifMissions)    ?? true;
    _notifValidations = _prefs.getBool(_kNotifValidations) ?? true;
    _notifMessages    = _prefs.getBool(_kNotifMessages)    ?? true;
    _notifSysteme     = _prefs.getBool(_kNotifSysteme)     ?? false;

    notifyListeners();
  }

  // Setters
  Future<void> setTheme(bool dark) async {
    _themeMode = dark ? ThemeMode.dark : ThemeMode.light;
    await _prefs.setString(_kTheme, dark ? 'dark' : 'light');
    notifyListeners();
  }

  Future<void> setLocale(String code) async {
    _locale = Locale(code);
    await _prefs.setString(_kLocale, code);
    notifyListeners();
  }

  Future<void> setNotifMissions(bool v) async {
    _notifMissions = v;
    await _prefs.setBool(_kNotifMissions, v);
    notifyListeners();
  }

  Future<void> setNotifValidations(bool v) async {
    _notifValidations = v;
    await _prefs.setBool(_kNotifValidations, v);
    notifyListeners();
  }

  Future<void> setNotifMessages(bool v) async {
    _notifMessages = v;
    await _prefs.setBool(_kNotifMessages, v);
    notifyListeners();
  }

  Future<void> setNotifSysteme(bool v) async {
    _notifSysteme = v;
    await _prefs.setBool(_kNotifSysteme, v);
    notifyListeners();
  }
}
