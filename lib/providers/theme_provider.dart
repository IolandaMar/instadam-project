import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('mode_fosc') ?? false;
    notifyListeners();
  }

  void toggleTheme(bool isOn) async {
    _isDarkMode = isOn;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('mode_fosc', isOn);
    notifyListeners();
  }
}
