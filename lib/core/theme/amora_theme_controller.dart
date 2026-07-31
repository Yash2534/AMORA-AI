import 'package:flutter/material.dart';

class AmoraThemeController {
  AmoraThemeController._();

  static final instance = AmoraThemeController._();

  final ValueNotifier<ThemeMode> mode = ValueNotifier(ThemeMode.light);

  void update(ThemeMode _) {
    if (mode.value != ThemeMode.light) mode.value = ThemeMode.light;
  }
}
