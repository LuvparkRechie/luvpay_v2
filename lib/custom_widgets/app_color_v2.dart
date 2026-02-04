import 'package:flutter/material.dart';

class AppColorV2 {
  // ====== LIGHT (your current) ======
  static const Color primaryTextColor = Color(0xFF132C4E); // midnight
  static const Color bodyTextColor = Color(0xFF6B7D91); // grey

  static const Color lpBlueBrand = Color(0xFF0078FF);
  static const Color lpTealBrand = Color(0xFF00DEEB);

  static const Color pastelBlueAccent = Color(0xFFE5F1FF);
  static const Color darkMintAccent = Color(0xFF4CD9CC);

  static const Color background = Color(0xFFFFFFFF);
  static const Color boxStroke = Color(0xFFE2EAF5);

  static const Color incorrectState = Color(0xFFD52525);
  static const Color correctState = Color(0xFF4CAF50);
  static const Color partialState = Color(0xFFFF9800);
  static const Color inactiveState = Color(0xFFD9D9D9);

  static const Color inactiveButton = Color(0xFFd0e3fc);

  // ====== DARK (add these) ======
  // Keep brand the same; adjust surfaces/text for dark mode.
  static const Color darkBackground = Color(0xFF0B1220);
  static const Color darkSurface = Color(0xFF111A2E);
  static const Color darkSurface2 = Color(0xFF16213A);
  static const Color darkStroke = Color(0xFF22304D);

  static const Color darkPrimaryText = Color(0xFFEAF1FF);
  static const Color darkBodyText = Color(0xFFA9B6CC);

  // ====== ColorSchemes ======
  static const ColorScheme lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: lpBlueBrand,
    onPrimary: Colors.white,
    secondary: lpTealBrand,
    onSecondary: Colors.white,
    surface: Colors.white,
    onSurface: primaryTextColor,
    error: incorrectState,
    onError: Colors.white,
  );

  static const ColorScheme darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: lpBlueBrand,
    onPrimary: Colors.white,
    secondary: lpTealBrand,
    onSecondary: Colors.black,
    surface: darkSurface,
    onSurface: darkPrimaryText,
    error: incorrectState,
    onError: Colors.white,
  );

  // Optional: gradients still ok
  static const Gradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0078FF), Color(0xFF0066DD)],
  );

  // ====== Aliases (for older code compatibility) ======
  // These are just shortcuts so existing UI code won't break.

  static const Color secondary = lpTealBrand;
  static const Color accent = darkMintAccent;

  static const Color success = correctState;
  static const Color warning = partialState;
  static const Color error = incorrectState;

  static const Color onSurfaceVariant = bodyTextColor;
}
