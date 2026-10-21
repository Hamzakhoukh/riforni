import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RestaurantProvider extends ChangeNotifier {
  static const _nameKey = 'restaurant_name';
  static const _logoKey = 'restaurant_logo_path';
  static const _setupDoneKey = 'setup_done';

  String _name = 'Riforni';
  String? _logoPath;
  bool _setupDone = false;

  String get name => _name.isEmpty ? 'Riforni' : _name;
  String? get logoPath => _logoPath;
  bool get setupDone => _setupDone;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _setupDone = prefs.getBool(_setupDoneKey) ?? false;
    _name = prefs.getString(_nameKey) ?? 'Riforni';
    _logoPath = prefs.getString(_logoKey);
    notifyListeners();
  }

  Future<void> save(String name, String? logoPath) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = name.trim().isEmpty ? 'Riforni' : name.trim();
    await prefs.setString(_nameKey, trimmed);
    await prefs.setBool(_setupDoneKey, true);
    if (logoPath != null) {
      await prefs.setString(_logoKey, logoPath);
    } else {
      await prefs.remove(_logoKey);
    }
    _name = trimmed;
    _logoPath = logoPath;
    _setupDone = true;
    notifyListeners();
  }

  Future<void> removeLogo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_logoKey);
    _logoPath = null;
    notifyListeners();
  }
}
