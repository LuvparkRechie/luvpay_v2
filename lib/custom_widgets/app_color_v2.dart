import 'package:flutter/material.dart';

//Approved

class AppColorV2 {
  // Typography & Colors v2

  // Text Colors
  static Color primaryTextColor = const Color(0xFF132C4E); // midnight
  static Color bodyTextColor = const Color(0xFF6B7D91); //grey

  // Brand Colors
  static Color lpBlueBrand = const Color(0xFF0078FF);
  static Color lpTealBrand = const Color(0xFF00DEEB);

  // Accent Colors
  static Color pastelBlueAccent = const Color(0xFFE5F1FF);
  static Color darkMintAccent = const Color(0xFF4CD9CC);

  // Background/Stroke Colors
  static Color background = const Color(0xFFFFFFFF);
  static Color boxStroke = const Color(0xFFE2EAF5); //const Color(0xFFF6F6F6);

  // State Colors
  static Color incorrectState = const Color(0xFFD52525);
  static Color correctState = const Color(0xFF4CAF50);
  static Color partialState = const Color(0xFFFF9800);
  static Color inactiveState = const Color(0xFFD9D9D9);

  //InActive Button
  static Color inactiveButton = const Color(0xFFd0e3fc);

  // ============ NEW COLORS ADDED ============

  // Primary Colors
  static const Color primary = Color(0xFF0078FF);
  static const Color primaryVariant = Color(0xFF0066DD);

  // Secondary/Accent Colors
  static const Color secondary = Color(0xFFFF6B8A);
  static const Color accent = Color(0xFF4CD0E8);

  // Neutral Colors
  static const Color surface = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF1A1D1F);
  static const Color onSurfaceVariant = Color(0xFF6A7278);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // Semantic Colors
  static const Color success = Color(0xFF2ECC71);
  static const Color warning = Color(0xFFFF9F43);
  static const Color error = Color(0xFFE74C3C);

  // Gradients
  static const Gradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0078FF), Color(0xFF0066DD)],
  );
}
