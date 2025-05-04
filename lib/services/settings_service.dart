import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _modeFoscKey = 'mode_fosc';

  Future<void> setModeFosc(bool habilitat) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_modeFoscKey, habilitat);
  }

  Future<bool> getModeFosc() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_modeFoscKey) ?? false;
  }
}
