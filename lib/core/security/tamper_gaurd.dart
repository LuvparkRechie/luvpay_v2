// lib/security/tamper_guard.dart
// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:ntp_dart/ntp_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef TamperUiHandler = void Function(String message);

class TamperGuard {
  TamperGuard._();

  static const _kTamperDialogActive = 'tamperDialogActive';

  static const _kPrefLastUtcOffsetMinutes = 'last_utc_offset_minutes';
  static const _kPrefLastTrustedEpochMs = 'last_trusted_epoch_ms';
  static const _kPrefLastTrustedOkEpochMs = 'last_trusted_ok_epoch_ms';

  // Tune these:
  static const int allowedDriftSeconds = 120; // keep your original
  static const int allowedRollbackSeconds = 10;

  // If you want strict offline policy:
  // 0 = allow offline forever (no forced tamper)
  // e.g. 120 = must have trusted time within 2 mins
  static const int maxTrustedStaleSeconds = 0;

  static Timer? _timer;
  static bool _running = false;

  static Future<bool> isDialogActive() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kTamperDialogActive) ?? false;
  }

  static Future<void> setDialogActive(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kTamperDialogActive, value);
  }

  /// Call once on app start (baseline offset + clear dialog state).
  static Future<void> prime() async {
    await setDialogActive(false);

    final prefs = await SharedPreferences.getInstance();
    final currentOffset = DateTime.now().timeZoneOffset.inMinutes;
    prefs.setInt(_kPrefLastUtcOffsetMinutes, currentOffset);
  }

  /// Start periodic checks (foreground).
  static void start({
    required Duration interval,
    required TamperUiHandler onTamperUi,
  }) {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) async {
      await checkOnce(onTamperUi: onTamperUi);
    });
  }

  static void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Call from background jobs too.
  static Future<void> checkOnce({required TamperUiHandler onTamperUi}) async {
    if (_running) return;
    _running = true;

    try {
      if (await isDialogActive()) return;

      final prefs = await SharedPreferences.getInstance();

      // --- 1) Timezone/offset tamper (stable) ---
      final offsetNow = DateTime.now().timeZoneOffset.inMinutes;
      final savedOffset = prefs.getInt(_kPrefLastUtcOffsetMinutes);

      // baseline if missing
      if (savedOffset == null) {
        await prefs.setInt(_kPrefLastUtcOffsetMinutes, offsetNow);
      } else if (savedOffset != offsetNow) {
        await _trigger(onTamperUi, "Timezone Tampered");
        return;
      }

      // --- 2) Trusted time (NTP) ---
      DateTime trustedNow;
      bool trustedOk = false;

      try {
        trustedNow = await AccurateTime.now().timeout(
          const Duration(seconds: 5),
        );
        trustedOk = trustedNow.year >= 2000;
      } catch (e) {
        trustedNow = DateTime.fromMillisecondsSinceEpoch(0);
        trustedOk = false;
      }

      // Offline strict policy (optional)
      final lastTrustedOk = prefs.getInt(_kPrefLastTrustedOkEpochMs) ?? 0;
      if (!trustedOk) {
        if (maxTrustedStaleSeconds > 0 && lastTrustedOk > 0) {
          final staleSeconds =
              ((DateTime.now().millisecondsSinceEpoch - lastTrustedOk) / 1000)
                  .round();
          if (staleSeconds > maxTrustedStaleSeconds) {
            await _trigger(onTamperUi, "Time Check Failed (no trusted time)");
            return;
          }
        }
        // if offline and policy allows, just skip time drift checks
        return;
      } else {
        await prefs.setInt(
          _kPrefLastTrustedOkEpochMs,
          DateTime.now().millisecondsSinceEpoch,
        );
      }

      final deviceNow = DateTime.now();

      // --- 3) Drift check ---
      final driftSeconds = trustedNow.difference(deviceNow).inSeconds.abs();
      if (driftSeconds > allowedDriftSeconds) {
        await _trigger(
          onTamperUi,
          "Time/Date Tampered (drift: ${driftSeconds}s)",
        );
        return;
      }

      // --- 4) Rollback check (trusted time going backwards) ---
      final lastTrusted = prefs.getInt(_kPrefLastTrustedEpochMs) ?? 0;
      final nowEpoch = trustedNow.millisecondsSinceEpoch;

      if (lastTrusted > 0) {
        final rollbackSeconds = ((lastTrusted - nowEpoch) / 1000).round();
        if (rollbackSeconds > allowedRollbackSeconds) {
          await _trigger(
            onTamperUi,
            "Time Tampered (rollback: ${rollbackSeconds}s)",
          );
          return;
        }
      }

      await prefs.setInt(_kPrefLastTrustedEpochMs, nowEpoch);
    } catch (e, stack) {
      print("TamperGuard error: $e");
      print(stack);
    } finally {
      _running = false;
    }
  }

  static Future<void> _trigger(TamperUiHandler onTamperUi, String msg) async {
    await setDialogActive(true);

    // Let UI layer decide how to show it. If UI not available, you can exit.
    onTamperUi(msg);
  }

  /// Optional hard-exit helper
  static void exitApp() {
    if (Platform.isAndroid) {
      SystemNavigator.pop();
    } else if (Platform.isIOS) {
      exit(0);
    }
  }
}
