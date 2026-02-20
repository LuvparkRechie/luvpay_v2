import 'dart:io';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../auth/authentication.dart';
import '../../features/routes/routes.dart';

enum ExpiryUnit { seconds, minutes, hours, days, months }

class ExpiryConfig {
  final int value;
  final ExpiryUnit unit;
  const ExpiryConfig(this.value, this.unit);
}

class AutoLogoutGuard {
  static const ExpiryConfig awayExpiry = ExpiryConfig(30, ExpiryUnit.minutes);

  static const int _awayAlarmId = 92001;

  static const String kLastBackgroundAt = 'last_background_at_ms';
  static const String kLogoutHandledAt = 'logout_handled_at_ms';

  static const String kAwayExpired = 'away_expired_flag';
  static const String kIsInBackground = 'is_in_background_flag';

  static const String kAwayExpiryAt = 'away_expiry_at_ms';

  static Future<void> checkColdStartLogout() async {
    final box = GetStorage();

    box.write(kIsInBackground, false);

    final lastBg = (box.read(kLastBackgroundAt) ?? 0) as int;
    if (lastBg == 0) return;

    final expiryAt = (box.read(kAwayExpiryAt) ?? 0) as int;
    if (expiryAt == 0) return;

    final handledAt = (box.read(kLogoutHandledAt) ?? 0) as int;
    if (handledAt == lastBg) return;

    final now = DateTime.now().millisecondsSinceEpoch;

    if (now >= expiryAt) {
      box.write(kLogoutHandledAt, lastBg);
      await Authentication().setLogoutStatus(true);
    }
  }

  static Future<void> handleLifecycle(AppLifecycleState state) async {
    // ignore: avoid_print
    print("[AutoLogoutGuard] lifecycle = $state");

    final box = GetStorage();

    final isBackgrounding =
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached;

    if (isBackgrounding) {
      final alreadyBg = (box.read(kIsInBackground) ?? false) as bool;

      if (!alreadyBg) {
        final bgAt = DateTime.now().millisecondsSinceEpoch;

        final expiryAt = _computeExpiryAtMs(bgAt, awayExpiry);

        box.write(kLastBackgroundAt, bgAt);
        box.write(kAwayExpiryAt, expiryAt);
        box.write(kIsInBackground, true);
        box.write(kAwayExpired, false);

        // ignore: avoid_print
        print(
          "[AutoLogoutGuard] ENTER background -> lastBg=$bgAt expiryAt=$expiryAt; alarm? ${Platform.isAndroid}",
        );

        if (Platform.isAndroid) {
          await AndroidAlarmManager.cancel(_awayAlarmId);

          final delayMs = expiryAt - bgAt;
          if (delayMs > 0) {
            await AndroidAlarmManager.oneShot(
              Duration(milliseconds: delayMs),
              _awayAlarmId,
              awayExpireAlarmEntry,
              exact: true,
              wakeup: true,
            );
          } else {
            box.write(kAwayExpired, true);
            try {
              await Authentication().setLogoutStatus(true);
            } catch (_) {}
          }
        }
      } else {
        // ignore: avoid_print
        print(
          "[AutoLogoutGuard] already in background, skip overwriting lastBg",
        );
      }
      return;
    }

    if (state == AppLifecycleState.resumed) {
      box.write(kIsInBackground, false);

      if (Platform.isAndroid) {
        await AndroidAlarmManager.cancel(_awayAlarmId);
      }

      final lastBg = (box.read(kLastBackgroundAt) ?? 0) as int;
      if (lastBg == 0) return;

      final expiryAt = (box.read(kAwayExpiryAt) ?? 0) as int;
      if (expiryAt == 0) return;

      final now = DateTime.now().millisecondsSinceEpoch;
      final awayMs = now - lastBg;

      final expiredFlag = (box.read(kAwayExpired) ?? false) as bool;
      final shouldExpire = expiredFlag || now >= expiryAt;

      // ignore: avoid_print
      print(
        "[AutoLogoutGuard] RESUMED lastBg=$lastBg now=$now expiryAt=$expiryAt awayMs=$awayMs "
        "expiredFlag=$expiredFlag shouldExpire=$shouldExpire",
      );

      if (!shouldExpire) return;

      box.write(kAwayExpired, true);

      await Authentication().setLogoutStatus(true);

      final expiryLabel = _formatExpiryLabel(
        awayExpiry,
      ); // e.g. "30 minutes", "1 month"
      final awayLabel = _formatElapsed(awayMs); // e.g. "31 minutes", "2 hours"

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Get.isDialogOpen == true) return;

        Get.dialog(
          PopScope(
            canPop: false,
            child: AlertDialog(
              title: const Text('Session Ended'),
              content: Text(
                'To keep your account secure, you have been logged out due to inactivity.\n\n'
                'You were away for $awayLabel, which exceeded the allowed limit of $expiryLabel.\n\n'
                'Please sign in again to continue.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    if (Get.isDialogOpen == true) Get.back();
                    Get.offAllNamed(Routes.login);
                  },
                  child: const Text('Sign In'),
                ),
              ],
            ),
          ),
          barrierDismissible: false,
        );
      });
    }
  }

  // Helpers

  static int _computeExpiryAtMs(int bgAtMs, ExpiryConfig cfg) {
    final bg = DateTime.fromMillisecondsSinceEpoch(bgAtMs);

    DateTime expiry;
    switch (cfg.unit) {
      case ExpiryUnit.seconds:
        expiry = bg.add(Duration(seconds: cfg.value));
        break;
      case ExpiryUnit.minutes:
        expiry = bg.add(Duration(minutes: cfg.value));
        break;
      case ExpiryUnit.hours:
        expiry = bg.add(Duration(hours: cfg.value));
        break;
      case ExpiryUnit.days:
        expiry = bg.add(Duration(days: cfg.value));
        break;
      case ExpiryUnit.months:
        expiry = _addMonths(bg, cfg.value);
        break;
    }

    return expiry.millisecondsSinceEpoch;
  }

  static DateTime _addMonths(DateTime dt, int monthsToAdd) {
    // month is 1..12
    final int totalMonths = (dt.year * 12) + (dt.month - 1) + monthsToAdd;
    final int newYear = totalMonths ~/ 12;
    final int newMonth = (totalMonths % 12) + 1;

    final int lastDay = _daysInMonth(newYear, newMonth);
    final int newDay = dt.day > lastDay ? lastDay : dt.day;

    return DateTime(
      newYear,
      newMonth,
      newDay,
      dt.hour,
      dt.minute,
      dt.second,
      dt.millisecond,
      dt.microsecond,
    );
  }

  static int _daysInMonth(int year, int month) {
    // Day 0 of next month is last day of current month
    final lastDay = DateTime(year, month + 1, 0).day;
    return lastDay;
  }

  static String _formatExpiryLabel(ExpiryConfig cfg) {
    return _plural(cfg.value, _unitName(cfg.unit));
  }

  static String _unitName(ExpiryUnit unit) {
    switch (unit) {
      case ExpiryUnit.seconds:
        return 'second';
      case ExpiryUnit.minutes:
        return 'minute';
      case ExpiryUnit.hours:
        return 'hour';
      case ExpiryUnit.days:
        return 'day';
      case ExpiryUnit.months:
        return 'month';
    }
  }

  static String _plural(int value, String singular) {
    if (value == 1) return '1 $singular';
    return '$value ${singular}s';
  }

  /// Formats elapsed time in a human way.
  /// Uses largest unit that yields >= 1, with rounding down.
  static String _formatElapsed(int elapsedMs) {
    final seconds = elapsedMs ~/ 1000;

    if (seconds < 60) return _plural(seconds <= 0 ? 1 : seconds, 'second');

    final minutes = seconds ~/ 60;
    if (minutes < 60) return _plural(minutes, 'minute');

    final hours = minutes ~/ 60;
    if (hours < 24) return _plural(hours, 'hour');

    final days = hours ~/ 24;
    if (days < 30) return _plural(days, 'day');

    // Past ~30 days, show months approximation for display only.
    final months = days ~/ 30;
    return _plural(months <= 0 ? 1 : months, 'month');
  }
}

@pragma('vm:entry-point')
Future<void> awayExpireAlarmEntry() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();

  try {
    await dotenv.load();
  } catch (_) {}

  final box = GetStorage();

  // ignore: avoid_print
  print("[AutoLogoutGuard] ANDROID alarm fired -> expire");

  box.write(AutoLogoutGuard.kAwayExpired, true);

  try {
    await Authentication().setLogoutStatus(true);
  } catch (_) {}
}
