import 'dart:async';
import 'dart:io';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:luvpay/main.dart';

class IosBgProcess {
  Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    if (Platform.isIOS || Platform.isAndroid) {
      await service.configure(
        androidConfiguration: AndroidConfiguration(
          onStart: onStart,
          autoStart: true,
          isForegroundMode: true,
          notificationChannelId: 'my_foreground',
          initialNotificationTitle: 'AWESOME SERVICE',
          initialNotificationContent: 'Initializing',
          foregroundServiceNotificationId: 888,
          foregroundServiceTypes: [AndroidForegroundType.location],
        ),
        iosConfiguration: IosConfiguration(
          autoStart: true,
          onForeground: onStart,
          onBackground: onIosBackground,
        ),
      );
    }
  }
}
