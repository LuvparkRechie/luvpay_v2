// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:dart_ping_ios/dart_ping_ios.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:luvpay/auth/authentication.dart';
import 'package:luvpay/bg_process/bg_process.dart';
import 'package:luvpay/custom_widgets/variables.dart';
import 'package:luvpay/http/api_keys.dart';
import 'package:luvpay/pages/routes/pages.dart';
import 'package:luvpay/pages/routes/routes.dart';
import 'package:ntp_dart/ntp_dart.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart'
    hide PermissionStatus;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import 'bg_process/luvpay/session_service.dart';
import 'custom_widgets/luvpay/luvpay_theme.dart';
import 'custom_widgets/luvpay/theme_mode_controller.dart';
import 'notification_controller.dart';
import 'security/app_security.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Timer? _sessionTimer;
Timer? _tamperTimer;

Future<bool> isTamperDialogActive() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('tamperDialogActive') ?? false;
}

Future<void> setTamperDialogActive(bool value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('tamperDialogActive', value);
}

@pragma('vm:entry-point')
Future<void> backgroundFunc(int id, Map<String, dynamic> params) async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  String userId = params['userId'];
  List appSecurity = await AppSecurity.checkDevMode();
  bool isAppSecured = appSecurity[0]["is_secured"];

  if (isAppSecured) {
    tz.initializeTimeZones();
    await checkTamper();
    await getMessNotif();
  } else {
    Variables.bgProcess?.cancel();
    Variables.showSecurityPopUp(appSecurity[0]["msg"]);
  }
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  final SharedPreferences preferences = await SharedPreferences.getInstance();
  await preferences.reload();
  final log = preferences.getStringList('log') ?? <String>[];
  log.add(DateTime.now().toIso8601String());
  await preferences.setStringList('log', log);

  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  try {
    DartPluginRegistrant.ensureInitialized();
    await dotenv.load();

    int? userId;

    service.on('updateUserLogin').listen((event) {
      if (event != null && event.containsKey('userId')) {
        userId = event['userId'];
      }
    });

    Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (userId != null && userId != 0) {
        await backgroundFunc(0, {'userId': userId.toString()});
      }
    });
  } catch (e, stack) {
    // ignore: avoid_print
    print(stack);
  }
}

@pragma('vm:entry-point')
void sessionTimeOut(BuildContext context) {
  _tamperTimer?.cancel();
  _tamperTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
    if (!await isTamperDialogActive()) {
      await checkTamper();
      getLogSession(context);
    } else {
      // ignore: avoid_print
      print("[Session Timeout] Skipped tamper check — dialog active.");
    }
  });
}

void _onUserActivity() {
  if (Get.currentRoute == Routes.lock) return;

  SessionService.touchActivity();
  SessionService.startIdleTimer();

  _sessionTimer?.cancel();
  sessionTimeOut(navigatorKey.currentContext!);
}

Future<void> checkTamper() async {
  if (await isTamperDialogActive()) return;

  try {
    DateTime serverUtcTime;
    try {
      serverUtcTime = await AccurateTime.now();
      if (serverUtcTime.year < 2000) throw Exception("Invalid NTP time");
    } catch (_) {
      // ignore: avoid_print
      print("[Tamper] Using fallback local UTC time.");
      serverUtcTime = DateTime.now().toUtc();
    }

    serverUtcTime = DateTime.utc(
      serverUtcTime.year,
      serverUtcTime.month,
      serverUtcTime.day,
      serverUtcTime.hour,
      serverUtcTime.minute,
    );

    DateTime deviceUtcTime = DateTime.now().toUtc();
    deviceUtcTime = DateTime.utc(
      deviceUtcTime.year,
      deviceUtcTime.month,
      deviceUtcTime.day,
      deviceUtcTime.hour,
      deviceUtcTime.minute,
    );

    final differenceMinutes =
        serverUtcTime.difference(deviceUtcTime).inMinutes.abs();
    const allowedDriftMinutes = 1;

    if (differenceMinutes > allowedDriftMinutes || _isTimezoneChanged()) {
      await setTamperDialogActive(true);
      final ctx = navigatorKey.currentContext;
      if (ctx != null) {
        Variables.showSecurityPopUp('"Time/Date Tampered"');
      } else {
        await setTamperDialogActive(false);
        _exitApp();
      }
    }
  } catch (e, stack) {
    // ignore: avoid_print
    print("Error in checkTamper: $e");
    // ignore: avoid_print
    print(stack);
  }
}

bool _isTimezoneChanged() {
  final deviceOffset = DateTime.now().timeZoneOffset.inHours;
  return deviceOffset != 8;
}

void _exitApp() {
  if (Platform.isAndroid) {
    SystemNavigator.pop();
  } else if (Platform.isIOS) {
    exit(0);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await GetStorage.init();
  await dotenv.load();

  Get.put(ThemeModeController(), permanent: true);

  DartPingIOS.register();
  await setTamperDialogActive(false);
  tz.initializeTimeZones();

  final packageInfo = await PackageInfo.fromPlatform();
  Variables.version = packageInfo.version;

  final status = await Permission.notification.status;
  if (status.isDenied) {
    await Permission.notification.request();
  }

  final isAllowed = await AwesomeNotifications().isNotificationAllowed();
  if (!isAllowed) {
    AwesomeNotifications().requestPermissionToSendNotifications();
  }

  NotificationController.initializeLocalNotifications();
  NotificationController.initializeIsolateReceivePort();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((
    _,
  ) {
    runApp(const MyApp());
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final ThemeController themeController = Get.put(ThemeController());

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    setTamperDialogActive(false);

    NotificationController.startListeningNotificationEvents();
    if (Platform.isAndroid) {
      AndroidAlarmManager.initialize();
    }
    initializedDeviceSecurity();

    SessionService.touchActivity();
    SessionService.startIdleTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sessionTimer?.cancel();
    _tamperTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      SessionService.markBackgrounded();
    }

    if (state == AppLifecycleState.resumed) {
      await SessionService.enforce();
    }
  }

  void initializedDeviceSecurity() async {
    List appSecurity = await AppSecurity.checkDeviceSecurity();
    bool isAppSecured = appSecurity[0]["is_secured"];

    if (isAppSecured) {
      if (Platform.isAndroid) {
        initializedBgProcess();
      } else {
        IosBgProcess().initializeService();
      }
      sessionTimeOut(navigatorKey.currentContext!);
    } else {
      Variables.bgProcess?.cancel();
      Variables.showSecurityPopUp(appSecurity[0]["msg"]);
    }
  }

  void initializedBgProcess() async {
    final userId = await Authentication().getUserId();
    await AndroidAlarmManager.periodic(
      const Duration(seconds: 5),
      0,
      backgroundFunc,
      startAt: DateTime.now(),
      params: {'userId': userId.toString()},
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeCtrl = Get.find<ThemeModeController>();

    return Listener(
      onPointerDown: (_) => _onUserActivity(),
      onPointerMove: (_) => _onUserActivity(),
      child: Obx(() {
        return GetMaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: ApiKeys.isProduction,
          title: 'MyApp',
          theme: AppThemeV2.light(),
          darkTheme: AppThemeV2.dark(),
          themeMode: themeCtrl.mode.value,
          navigatorObservers: [GetObserver()],
          initialRoute: Routes.splash,
          getPages: AppPages.pages,
        );
      }),
    );
  }
}
