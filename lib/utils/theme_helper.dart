import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class ThemeHelper {
  static final ThemeHelper _instance = ThemeHelper._internal();
  factory ThemeHelper() => _instance;
  ThemeHelper._internal();

  Color _themeColor = Colors.indigo; // Varsayılan tema
  double _fontSize = 14.0; // Varsayılan 14 punto
  bool _darkMode = false;

  Color get themeColor => _themeColor;
  double get fontSize => _fontSize;
  bool get darkMode => _darkMode;

  // Tema değişikliği dinleyicileri
  final List<VoidCallback> _themeChangeListeners = [];
  final List<VoidCallback> _fontSizeChangeListeners = [];

  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeColorValue =
          prefs.getInt('theme_color') ?? Colors.indigo.value;
      final fontSize = prefs.getDouble('font_size') ?? 14.0;
      final darkMode = prefs.getBool('dark_mode') ?? false;

      _themeColor = Color(themeColorValue);
      _fontSize = fontSize;
      _darkMode = darkMode;
    } catch (e) {
      debugPrint('Tema ayarları yüklenirken hata: $e');
    }
  }

  Future<void> setThemeColor(Color color) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('theme_color', color.value);
      _themeColor = color;

      // Tüm dinleyicilere bildir
      for (var listener in _themeChangeListeners) {
        listener();
      }
    } catch (e) {
      debugPrint('Tema rengi kaydedilirken hata: $e');
    }
  }

  Future<void> setDarkMode(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('dark_mode', enabled);
      _darkMode = enabled;
      for (var listener in List<VoidCallback>.from(_themeChangeListeners)) {
        listener();
      }
    } catch (e) {
      debugPrint('Koyu tema ayarı kaydedilirken hata: $e');
    }
  }

  Future<void> setFontSize(double size) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('font_size', size);
      _fontSize = size;

      // Tüm dinleyicilere bildir
      for (var listener in _fontSizeChangeListeners) {
        listener();
      }
    } catch (e) {
      debugPrint('Font boyutu kaydedilirken hata: $e');
    }
  }

  void addThemeChangeListener(VoidCallback listener) {
    _themeChangeListeners.add(listener);
  }

  void removeThemeChangeListener(VoidCallback listener) {
    _themeChangeListeners.remove(listener);
  }

  void addFontSizeChangeListener(VoidCallback listener) {
    _fontSizeChangeListeners.add(listener);
  }

  void removeFontSizeChangeListener(VoidCallback listener) {
    _fontSizeChangeListeners.remove(listener);
  }
}
