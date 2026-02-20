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
import 'package:luvpay/shared/widgets/variables.dart';
import 'package:luvpay/core/network/http/api_keys.dart';
import 'package:luvpay/features/routes/pages.dart';
import 'package:luvpay/features/routes/routes.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart'
    hide PermissionStatus;
import 'package:shared_preferences/shared_preferences.dart';
import 'core/security/auto_logout_guard.dart';
import 'core/security/tamper_gaurd.dart';
import 'shared/widgets/luvpay_theme.dart';
import 'shared/widgets/theme_mode_controller.dart';
import 'core/services/notification_controller.dart';
import 'core/security/security/app_security.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
Timer? _sessionTimer;
Timer? _tamperTimer;

@pragma('vm:entry-point')
Future<void> backgroundFunc(int id, Map<String, dynamic> params) async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  String userId = params['userId'];
  List appSecurity = await AppSecurity.checkDevMode();
  bool isAppSecured = appSecurity[0]["is_secured"];

  if (isAppSecured) {
    await TamperGuard.checkOnce(
      onTamperUi: (_) {
        TamperGuard.exitApp();
      },
    );
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
    print(stack);
  }
}

@pragma('vm:entry-point')
void sessionTimeOut(BuildContext context) {
  _tamperTimer?.cancel();
  _tamperTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
    if (!await TamperGuard.isDialogActive()) {
      getLogSession(context);
    } else {
      print("[Session Timeout] Skipped session log — tamper dialog active.");
    }
  });
}

void _onUserActivity() {
  _sessionTimer?.cancel();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final ctx = navigatorKey.currentContext;
    if (ctx != null) sessionTimeOut(ctx);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  await dotenv.load();
  if (Platform.isAndroid) {
    await AndroidAlarmManager.initialize();
  }
  await AutoLogoutGuard.checkColdStartLogout();

  Get.put(ThemeModeController(), permanent: true);
  DartPingIOS.register();
  await TamperGuard.prime();

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
    TamperGuard.start(
      interval: const Duration(seconds: 10),
      onTamperUi: (msg) {
        final ctx = navigatorKey.currentContext;
        if (ctx != null) {
          Variables.showSecurityPopUp(msg);
        } else {
          TamperGuard.exitApp();
        }
      },
    );
    WidgetsBinding.instance.addObserver(this);

    NotificationController.startListeningNotificationEvents();

    initializedDeviceSecurity();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    TamperGuard.stop();
    _sessionTimer?.cancel();
    _tamperTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    await AutoLogoutGuard.handleLifecycle(state);
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

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = navigatorKey.currentContext;
        if (ctx != null) sessionTimeOut(ctx);
      });
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
