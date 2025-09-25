import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  static const _key = 'theme_mode'; // 'light' | 'dark' | 'system'
  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_key);
    _mode = _stringToMode(s) ?? ThemeMode.system;
    notifyListeners();
  }

  Future<void> setMode(ThemeMode m) async {
    _mode = m;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, _modeToString(m));
  }

  Future<void> toggleDark(bool value) async {
    await setMode(value ? ThemeMode.dark : ThemeMode.light);
  }

  String _modeToString(ThemeMode m) {
    switch (m) {
      case ThemeMode.light: return 'light';
      case ThemeMode.dark:  return 'dark';
      case ThemeMode.system:return 'system';
    }
  }

  ThemeMode? _stringToMode(String? s) {
    switch (s) {
      case 'light':  return ThemeMode.light;
      case 'dark':   return ThemeMode.dark;
      case 'system': return ThemeMode.system;
    }
    return null;
    }
}
