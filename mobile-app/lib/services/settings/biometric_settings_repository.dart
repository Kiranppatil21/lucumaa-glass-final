import 'package:shared_preferences/shared_preferences.dart';

class BiometricSettingsRepository {
  static const _kEnabled = 'biometric_enabled_v1';

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kEnabled) ?? false;
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnabled, enabled);
  }
}
