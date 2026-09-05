import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// App-wide preferences (theme mode + language), persisted on-device.
class SettingsController extends ChangeNotifier {
  static const String boxName = 'kioku_settings_v1';

  late Box _box;
  ThemeMode _themeMode = ThemeMode.dark;
  Locale? _locale; // null = follow system

  ThemeMode get themeMode => _themeMode;
  Locale? get locale => _locale;

  Future<void> init() async {
    _box = await Hive.openBox(boxName);
    _themeMode = switch (_box.get('themeMode') as String?) {
      'light' => ThemeMode.light,
      'system' => ThemeMode.system,
      _ => ThemeMode.dark,
    };
    final code = _box.get('locale') as String?;
    _locale = code == null ? null : Locale(code);
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    _box.put('themeMode', mode.name);
    notifyListeners();
  }

  void setLocale(Locale? locale) {
    _locale = locale;
    _box.put('locale', locale?.languageCode);
    notifyListeners();
  }
}
