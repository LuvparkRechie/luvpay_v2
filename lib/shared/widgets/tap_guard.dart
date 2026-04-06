import 'package:flutter/material.dart';

class TapGuard {
  static final Map<String, bool> _locks = {};

  static bool isLocked(String key) => _locks[key] == true;

  static Future<void> run({
    required String key,
    required Future<void> Function() action,
    Duration? minDelay,
  }) async {
    if (_locks[key] == true) return;

    _locks[key] = true;

    final start = DateTime.now();

    try {
      await action();
    } catch (e) {
      debugPrint("TapGuard error for key '$key': $e");
    } finally {
      if (minDelay != null) {
        final elapsed = DateTime.now().difference(start);
        if (elapsed < minDelay) {
          await Future.delayed(minDelay - elapsed);
        }
      }

      _locks[key] = false;
    }
  }

  static void unlock(String key) {
    _locks[key] = false;
  }
}
