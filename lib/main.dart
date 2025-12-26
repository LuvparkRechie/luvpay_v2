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
import 'package:google_fonts/google_fonts.dart';
import 'package:luvpay/auth/authentication.dart';
import 'package:luvpay/bg_process/bg_process.dart';
import 'package:luvpay/custom_widgets/app_color_v2.dart';
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

import 'notification_controller.dart';
import 'security/app_security.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
Timer? _sessionTimer;
Timer? _tamperTimer;

// ===== Shared Tamper Flag =====
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
    // Background should still respect tamper check
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
      print("[Session Timeout] Skipped tamper check — dialog active.");
    }
  });
}

void _onUserActivity() {
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
    print("Error in checkTamper: $e");
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
  DartPingIOS.register();
  await setTamperDialogActive(false);
  tz.initializeTimeZones();
  final packageInfo = await PackageInfo.fromPlatform();
  Variables.version = packageInfo.version;

  final status = await Permission.notification.status;
  if (status.isDenied) {
    await Permission.notification.request();
  }

  bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
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

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    setTamperDialogActive(false);

    NotificationController.startListeningNotificationEvents();
    if (Platform.isAndroid) {
      AndroidAlarmManager.initialize();
    }
    initializedDeviceSecurity();
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _tamperTimer?.cancel();
    super.dispose();
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
    return Listener(
      onPointerDown: (_) => _onUserActivity(),
      child: GetMaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: !ApiKeys.isProduction,
        title: 'MyApp',
        theme: ThemeData(
          scaffoldBackgroundColor: AppColorV2.background,
          colorScheme: ColorScheme(
            primary: AppColorV2.lpBlueBrand,
            onPrimaryFixedVariant: AppColorV2.lpBlueBrand,
            secondary: AppColorV2.lpTealBrand,
            onSecondaryFixedVariant: AppColorV2.lpTealBrand,
            surface: Colors.white,
            error: AppColorV2.incorrectState,
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onSurface: AppColorV2.primaryTextColor,
            onError: Colors.white,
            brightness: Brightness.light,
          ),
          useMaterial3: false,
          appBarTheme: AppBarTheme(
            titleTextStyle: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 28 / 18,
              color: AppColorV2.background,
              fontStyle: FontStyle.normal,
            ),
            backgroundColor: AppColorV2.lpBlueBrand,
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarColor: AppColorV2.lpBlueBrand,
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.dark,
            ),
          ),
          dividerTheme: DividerThemeData(
            color: Colors.grey.shade300,
            thickness: 0.5,
            space: 15,
            indent: 5,
          ),
        ),
        navigatorObservers: [GetObserver()],
        initialRoute: Routes.splash,
        getPages: AppPages.pages,
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:camera/camera.dart';
// import 'verification/verify_identity_screen.dart';

// late List<CameraDescription> cameras; // Global variable

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   // Initialize cameras
//   final camerasList = await availableCameras();

//   runApp(MyApp(cameras: camerasList));
// }

// class MyApp extends StatelessWidget {
//   final List<CameraDescription> cameras;

//   const MyApp({super.key, required this.cameras});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(home: VerifyIdentityScreen(cameras: cameras));
//   }
// }
