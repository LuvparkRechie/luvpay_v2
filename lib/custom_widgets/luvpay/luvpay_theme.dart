import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_color_v2.dart';

class ThemeController extends GetxController {
  final _box = GetStorage();
  static const _key = 'theme_mode'; // 'light' | 'dark' | 'system'

  final themeMode = ThemeMode.system.obs;

  @override
  void onInit() {
    super.onInit();
    themeMode.value = _readThemeMode();
  }

  ThemeMode _readThemeMode() {
    final v = _box.read<String>(_key) ?? 'system';
    switch (v) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  void setThemeMode(ThemeMode mode) {
    themeMode.value = mode;
    _box.write(_key, _modeToString(mode));
    Get.changeThemeMode(mode);
  }

  void toggleLightDark() {
    final isDark =
        themeMode.value == ThemeMode.dark ||
        (themeMode.value == ThemeMode.system && Get.isPlatformDarkMode == true);

    setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
  }

  String _modeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
      default:
        return 'system';
    }
  }
}

class AppThemeV2 {
  static ThemeData light() {
    final scheme = AppColorV2.lightScheme;

    return ThemeData(
      useMaterial3: false,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColorV2.background,
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade300,
        thickness: 0.5,
        space: 15,
        indent: 5,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColorV2.lpBlueBrand,
        titleTextStyle: GoogleFonts.manrope(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          height: 28 / 18,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
    );
  }

  static ThemeData dark() {
    final scheme = AppColorV2.darkScheme;

    return ThemeData(
      useMaterial3: false,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColorV2.darkBackground,
      dividerTheme: DividerThemeData(
        color: AppColorV2.darkStroke,
        thickness: 0.5,
        space: 15,
        indent: 5,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColorV2.darkSurface2,
        titleTextStyle: GoogleFonts.manrope(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          height: 28 / 18,
          color: AppColorV2.darkPrimaryText,
        ),
        iconTheme: const IconThemeData(color: AppColorV2.darkPrimaryText),
      ),
    );
  }
}
