import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService with ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final String? themeName = prefs.getString('theme_mode');
    if (themeName == 'light') _themeMode = ThemeMode.light;
    else if (themeName == 'dark') _themeMode = ThemeMode.dark;
    else _themeMode = ThemeMode.system;
    notifyListeners();
  }

  Future<void> updateTheme(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners(); // Tell the app to repaint
    final prefs = await SharedPreferences.getInstance();
    String themeName = 'system';
    if (mode == ThemeMode.light) themeName = 'light';
    if (mode == ThemeMode.dark) themeName = 'dark';
    await prefs.setString('theme_mode', themeName);
  }
}