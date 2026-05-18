import 'dart:async';
import 'dart:io';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:luvpay/auth/authentication.dart';
import 'package:luvpay/core/network/http/api_keys.dart';
import 'package:luvpay/core/utils/functions/functions.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../features/routes/routes.dart';
import 'wallet_notification_poller.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } catch (error) {
    debugPrint("[FCM] Background initialization skipped: $error");
  }
}

class FcmNotificationService {
  static StreamSubscription<RemoteMessage>? _foregroundSubscription;
  static StreamSubscription<RemoteMessage>? _openedSubscription;
  static StreamSubscription<String>? _tokenSubscription;
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _loadEnvironment();
      await _initializeFirebase();

      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      final messaging = FirebaseMessaging.instance;

      await messaging.requestPermission(alert: true, badge: true, sound: true);

      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      final token = await messaging.getToken();

      debugPrint("[FCM] Token ${token == null ? "unavailable" : "ready"}");

      if (token != null) {
        await saveFcmTokenToBackend(token);
      }
      _tokenSubscription?.cancel();
      _tokenSubscription = messaging.onTokenRefresh.listen((newToken) {
        debugPrint("[FCM] Token refreshed");
        unawaited(saveFcmTokenToBackend(newToken));
      });

      _foregroundSubscription?.cancel();
      _foregroundSubscription = FirebaseMessaging.onMessage.listen(
        _handleForegroundMessage,
      );

      _openedSubscription?.cancel();
      _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
        _handleOpenedMessage,
      );

      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        unawaited(_handleOpenedMessage(initialMessage));
      }

      _isInitialized = true;
    } catch (error) {
      debugPrint("[FCM] Disabled: $error");
    }
  }

  static Future<void> saveCurrentTokenAfterLogin() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();

      if (token == null) {
        debugPrint("[FCM] Token save after login skipped: token unavailable");
        return;
      }

      await saveFcmTokenToBackend(token);
    } catch (error) {
      debugPrint("[FCM] Token save after login failed: $error");
    }
  }

  static Future<void> saveFcmTokenToBackend(String token) async {
    try {
      final userId = await Authentication().getUserId();

      if (userId <= 0) {
        debugPrint("[FCM] Token save skipped: no logged-in user");
        return;
      }

      final packageInfo = await PackageInfo.fromPlatform();

      final response = await Functions().requestHandler(
        apiKey: ApiKeys.saveFcmTokenApi,
        method: "POST",
        parameters: {
          "user_id": userId.toString(),
          "fcm_token": token,
          "device_type": Platform.isAndroid ? "android" : "ios",
          "device_id": "",
          "app_version": packageInfo.version,
        },
      );

      debugPrint("[FCM] Token save response: $response");
    } catch (error) {
      debugPrint("[FCM] Token save failed: $error");
    }
  }

  static Future<void> dispose() async {
    await _foregroundSubscription?.cancel();
    await _openedSubscription?.cancel();
    await _tokenSubscription?.cancel();

    _foregroundSubscription = null;
    _openedSubscription = null;
    _tokenSubscription = null;
    _isInitialized = false;
  }

  static Future<void> _loadEnvironment() async {
    if (dotenv.isInitialized) return;
    await dotenv.load();
  }

  static Future<void> _initializeFirebase() async {
    if (Firebase.apps.isNotEmpty) return;
    await Firebase.initializeApp();
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint("[FCM] Foreground wallet notification ping");
    debugPrint("[FCM] Data: ${message.data}");

    final result = await WalletNotificationPoller.pollNow(
      showBanner: true,
      force: true,
    );

    debugPrint(
      "[WalletPoll] count=${result?.notifications.length} "
      "new=${result?.newNotificationCount} "
      "banner=${result?.didShowBanner}",
    );
  }

  static Future<void> _handleOpenedMessage(RemoteMessage message) async {
    await AwesomeNotifications().dismissAllNotifications();
    await AwesomeNotifications().cancelAll();
    await AwesomeNotifications().resetGlobalBadge();

    await WalletNotificationPoller.pollNow(
      showBanner: false,
      force: true,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.currentRoute == Routes.notifications) return;
      Get.toNamed(Routes.notifications);
    });
  }
}
