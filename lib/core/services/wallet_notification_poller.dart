import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/authentication.dart';
import '../../features/routes/routes.dart';
import '../network/http/api_keys.dart';
import '../utils/functions/functions.dart';
import 'in_app_notification_service.dart';

class WalletNotificationPoller {
  static const Duration _pollInterval = Duration(seconds: 30);
  static const Duration _requestTimeout = Duration(seconds: 10);
  static const String _lastSeenKeyPrefix = 'wallet_notification_last_seen_';

  static Timer? _timer;
  static bool _isPolling = false;

  static void start() {
    if (_timer != null) return;

    _timer = Timer.periodic(_pollInterval, (_) => pollNow());
    Timer(const Duration(seconds: 3), () => pollNow());
  }

  static void stop() {
    _timer?.cancel();
    _timer = null;
    _isPolling = false;
  }

  static Future<void> pollNow() async {
    if (_isPolling || !_isAppForeground) return;

    _isPolling = true;
    try {
      final login = await Authentication().getUserLogin();
      if (login == null || login["is_login"] != "Y") return;

      final userId = await Authentication().getUserId();
      if (userId <= 0) return;

      final response = await Functions().requestHandler(
        apiKey: "${ApiKeys.notificationApi}$userId",
        timeout: _requestTimeout,
      );

      if (response == "No Internet" || response is! Map) return;

      final items = response["items"];
      if (items is! List || items.isEmpty) return;

      final notifications = items
          .map(_WalletNotificationSnapshot.tryParse)
          .whereType<_WalletNotificationSnapshot>()
          .toList()
        ..sort((a, b) => a.id.compareTo(b.id));

      if (notifications.isEmpty) return;

      final newest = notifications.last;
      final prefs = await SharedPreferences.getInstance();
      final prefKey = "$_lastSeenKeyPrefix$userId";
      final lastSeenId = prefs.getInt(prefKey);

      if (lastSeenId == null) {
        await prefs.setInt(prefKey, newest.id);
        return;
      }

      final newNotifications =
          notifications.where((item) => item.id > lastSeenId).toList();
      if (newNotifications.isEmpty) return;

      final notificationToShow = newNotifications.last;
      final didShow = await InAppNotificationService.show(
        title: "Notification",
        message: notificationToShow.message,
        type: _typeForMessage(notificationToShow.message),
        icon: _iconForMessage(notificationToShow.message),
        onTap: () => Get.toNamed(Routes.notifications),
      );

      if (didShow) {
        await prefs.setInt(prefKey, newest.id);
      }
    } catch (e) {
      debugPrint("[WalletNotificationPoller] $e");
    } finally {
      _isPolling = false;
    }
  }

  static bool get _isAppForeground {
    final lifecycleState = WidgetsBinding.instance.lifecycleState;
    return lifecycleState == null || lifecycleState == AppLifecycleState.resumed;
  }

  static InAppNotificationType _typeForMessage(String message) {
    final lower = message.toLowerCase();
    if (lower.contains("received") || lower.contains("credit")) {
      return InAppNotificationType.success;
    }
    if (lower.contains("failed") || lower.contains("declined")) {
      return InAppNotificationType.error;
    }
    return InAppNotificationType.info;
  }

  static IconData _iconForMessage(String message) {
    final lower = message.toLowerCase();
    if (lower.contains("share")) return Icons.ios_share_rounded;
    if (lower.contains("received") || lower.contains("credit")) {
      return Icons.call_received_rounded;
    }
    if (lower.contains("parking")) return Icons.local_parking_rounded;
    return Icons.account_balance_wallet_outlined;
  }
}

class _WalletNotificationSnapshot {
  const _WalletNotificationSnapshot({
    required this.id,
    required this.message,
  });

  final int id;
  final String message;

  static _WalletNotificationSnapshot? tryParse(dynamic raw) {
    if (raw is! Map) return null;

    final rawId = raw["sms_id"];
    final id = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? "");
    if (id == null) return null;

    final message = raw["sms_msg"]?.toString().trim() ?? "";
    if (message.isEmpty) return null;

    return _WalletNotificationSnapshot(id: id, message: message);
  }
}
