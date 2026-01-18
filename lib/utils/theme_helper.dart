import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class ThemeHelper {
  static final ThemeHelper _instance = ThemeHelper._internal();
  factory ThemeHelper() => _instance;
  ThemeHelper._internal();

  Color _themeColor = Colors.indigo; // Varsayılan indigo (orijinal renk)
  double _fontSize = 14.0; // Varsayılan 14 punto
  
  Color get themeColor => _themeColor;
  double get fontSize => _fontSize;
  
  // Tema değişikliği dinleyicileri
  final List<VoidCallback> _themeChangeListeners = [];
  final List<VoidCallback> _fontSizeChangeListeners = [];

  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeColorValue = prefs.getInt('theme_color') ?? Colors.indigo.value;
      final fontSize = prefs.getDouble('font_size') ?? 14.0;
      
      _themeColor = Color(themeColorValue);
      _fontSize = fontSize;
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

