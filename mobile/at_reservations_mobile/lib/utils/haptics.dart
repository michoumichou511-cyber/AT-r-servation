import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Haptics {
  static bool _enabled = true;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool('haptics_enabled') ?? true;
  }

  static Future<void> setEnabled(bool v) async {
    _enabled = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('haptics_enabled', v);
  }

  static bool get isEnabled => _enabled;

  static void success() {
    if (!_enabled) return;
    HapticFeedback.lightImpact();
  }

  static void error() {
    if (!_enabled) return;
    HapticFeedback.vibrate();
  }

  static void warning() {
    if (!_enabled) return;
    HapticFeedback.heavyImpact();
  }

  static void selection() {
    if (!_enabled) return;
    HapticFeedback.selectionClick();
  }

  static void impact() {
    if (!_enabled) return;
    HapticFeedback.mediumImpact();
  }
}
