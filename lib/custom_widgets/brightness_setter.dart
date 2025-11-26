// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:screen_brightness/screen_brightness.dart';

class BrightnessSetter {
  static double? _previousBrightness;
  static bool _isFullBrightness = false;

  static Future<void> setFullBrightness() async {
    try {
      if (_isFullBrightness) return;

      _previousBrightness = await ScreenBrightness().current;

      await ScreenBrightness().setScreenBrightness(.8);
      _isFullBrightness = true;

      debugPrint('✅ Brightness set to full. Previous: $_previousBrightness');
    } catch (e) {
      debugPrint('⚠️ Failed to set full brightness: $e');
    }
  }

  static Future<void> restoreBrightness() async {
    try {
      if (!_isFullBrightness) return;

      await ScreenBrightness().resetScreenBrightness();

      _isFullBrightness = false;
    } catch (e) {
      debugPrint('⚠️ Failed to restore brightness: $e');
      try {
        await ScreenBrightness().resetScreenBrightness();
      } catch (e2) {
        debugPrint('⚠️ Even basic reset failed: $e2');
      }
    }
  }
}
