import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/authentication.dart';
import '../../features/routes/routes.dart';
import '../../shared/widgets/longprint.dart';
import '../network/http/api_keys.dart';
import '../utils/functions/functions.dart';
import 'in_app_notification_service.dart';

class WalletNotificationSyncResult {
  const WalletNotificationSyncResult({
    required this.notifications,
    required this.hasNetwork,
    required this.isAuthenticated,
    this.errorMessage,
    this.newNotificationCount = 0,
    this.didShowBanner = false,
  });

  final List<Map<String, dynamic>> notifications;
  final bool hasNetwork;
  final bool isAuthenticated;
  final String? errorMessage;
  final int newNotificationCount;
  final bool didShowBanner;

  bool get isSuccess =>
      hasNetwork && isAuthenticated && (errorMessage?.isEmpty ?? true);
  bool get hasNewNotifications => newNotificationCount > 0;
}

class WalletNotificationPoller {
  static const Duration _pollInterval = Duration(minutes: 2);
  static const Duration _requestTimeout = Duration(seconds: 10);
  static const String _lastSeenKeyPrefix = 'wallet_notification_last_seen_';

  static final StreamController<WalletNotificationSyncResult> _syncController =
      StreamController<WalletNotificationSyncResult>.broadcast();

  static Timer? _timer;
  static bool _isPolling = false;
  static List<Map<String, dynamic>> _latestNotifications = [];
  static WalletNotificationSyncResult? _lastResult;

  static Stream<WalletNotificationSyncResult> get syncStream =>
      _syncController.stream;

  static List<Map<String, dynamic>> get latestNotifications =>
      List<Map<String, dynamic>>.unmodifiable(_latestNotifications);

  static WalletNotificationSyncResult? get lastResult => _lastResult;

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

  static Future<WalletNotificationSyncResult?> pollNow({
    bool showBanner = false,
    bool force = false,
  }) async {
    if (_isPolling && !force) return _lastResult;

    _isPolling = true;

    try {
      final userId = await Authentication().getUserId();

      if (userId == 0) {
        return _emit(const WalletNotificationSyncResult(
          notifications: [],
          hasNetwork: true,
          isAuthenticated: false,
        ));
      }

      final response = await Functions().requestHandler(
        apiKey: "${ApiKeys.notificationApi}$userId",
        timeout: _requestTimeout,
      );

      if (response == "No Internet") {
        return _emit(WalletNotificationSyncResult(
          notifications: latestNotifications,
          hasNetwork: false,
          isAuthenticated: true,
          errorMessage: "No internet connection",
        ));
      }

      if (response is! Map) {
        return _emit(WalletNotificationSyncResult(
          notifications: latestNotifications,
          hasNetwork: true,
          isAuthenticated: true,
          errorMessage: "Invalid notification response",
        ));
      }

      final rawItems = response["items"];

      final List<Map<String, dynamic>> notifications = rawItems is List
          ? rawItems
              .whereType<Map>()
              .map((item) {
                final id = item["notification_id"] ?? item["sms_id"];
                final message = item["notification"] ?? item["sms_msg"];

                return {
                  "notification_id": id,
                  "notification": message,
                  "created_on": item["created_on"],
                };
              })
              .where((item) =>
                  item["notification_id"] != null &&
                  item["notification"] != null)
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
          : <Map<String, dynamic>>[];

      notifications.sort((a, b) {
        final aId = int.tryParse(a["notification_id"].toString()) ?? 0;
        final bId = int.tryParse(b["notification_id"].toString()) ?? 0;
        return bId.compareTo(aId);
      });
      _latestNotifications = notifications;

      final prefs = await SharedPreferences.getInstance();
      final lastSeenKey = "$_lastSeenKeyPrefix$userId";
      final lastSeenId = prefs.getInt(lastSeenKey) ?? 0;

      final newNotifications = notifications.where((item) {
        final id = int.tryParse(item["notification_id"].toString()) ?? 0;
        return id > lastSeenId;
      }).toList();

      final newestId = notifications.isEmpty
          ? lastSeenId
          : int.tryParse(notifications.first["notification_id"].toString()) ??
              lastSeenId;

      debugPrint("[WalletPoll] lastSeenId=$lastSeenId newestApiId=$newestId");
      debugPrint(
        "[WalletPoll] newIds=${newNotifications.map((e) => e["notification_id"]).toList()}",
      );

      bool didShowBanner = false;

      if (showBanner && newNotifications.isNotEmpty) {
        final newest = newNotifications.first;

        await InAppNotificationService.show(
          title: "New notification",
          message: newest["notification"].toString(),
        );

        didShowBanner = true;
      }

      if (newestId > lastSeenId) {
        await prefs.setInt(lastSeenKey, newestId);
      }

      return _emit(WalletNotificationSyncResult(
        notifications: notifications,
        hasNetwork: true,
        isAuthenticated: true,
        newNotificationCount: newNotifications.length,
        didShowBanner: didShowBanner,
      ));
    } catch (error) {
      return _emit(WalletNotificationSyncResult(
        notifications: latestNotifications,
        hasNetwork: true,
        isAuthenticated: true,
        errorMessage: error.toString(),
      ));
    } finally {
      _isPolling = false;
    }
  }

  static Future<void> deleteNotification(String smsId) async {
    final userId = await Authentication().getUserId();
    if (userId <= 0) {
      throw Exception("User is not logged in");
    }

    final response = await Functions().requestHandler(
      apiKey: "${ApiKeys.notificationApi}$userId",
      parameters: {"sms_id": smsId},
      method: "DELETE",
    );

    if (response == "No Internet") {
      throw Exception("No internet connection");
    }

    if (response is! Map || response["success"] != "Y") {
      throw Exception("Failed to delete notification");
    }

    await pollNow(showBanner: false, force: true);
  }

  static Future<void> markLatestAsSeen() async {
    final userId = await Authentication().getUserId();
    if (userId <= 0 || _latestNotifications.isEmpty) return;

    final newestId = _latestNotifications
        .map(_notificationId)
        .whereType<int>()
        .fold<int?>(null, (current, id) {
      if (current == null || id > current) return id;
      return current;
    });

    if (newestId == null) return;
    await _setLastSeenNotificationId(userId, newestId);
  }

  static WalletNotificationSyncResult _emit(
      WalletNotificationSyncResult result) {
    _lastResult = result;
    if (result.hasNetwork && result.isAuthenticated) {
      _latestNotifications = result.notifications;
    }
    if (!_syncController.isClosed) {
      _syncController.add(result);
    }
    return result;
  }

  static Future<void> _setLastSeenNotificationId(
      int userId, int newestId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("$_lastSeenKeyPrefix$userId", newestId);
  }

  static Map<String, dynamic>? _normalizeNotification(dynamic raw) {
    if (raw is! Map) return null;

    final id = _parseInt(raw["sms_id"] ?? raw["notification_id"]);
    final message =
        (raw["sms_msg"] ?? raw["notification"] ?? "").toString().trim();
    if (id == null || message.isEmpty) return null;

    return {
      "notification_id": id,
      "notification": message,
      "created_on": raw["created_on"]?.toString() ??
          DateTime.now().toUtc().toIso8601String(),
    };
  }

  static int? _notificationId(Map<String, dynamic> notification) {
    return _parseInt(notification["notification_id"] ?? notification["sms_id"]);
  }

  static int? _parseInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? "");
  }

  static bool get _isAppForeground {
    final lifecycleState = WidgetsBinding.instance.lifecycleState;
    return lifecycleState == null ||
        lifecycleState == AppLifecycleState.resumed;
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

    final rawId = raw["sms_id"] ?? raw["notification_id"];
    final id = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? "");
    if (id == null) return null;

    final message =
        (raw["sms_msg"] ?? raw["notification"] ?? "").toString().trim();
    if (message.isEmpty) return null;

    return _WalletNotificationSnapshot(id: id, message: message);
  }
}
