import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
// ignore: depend_on_referenced_packages
import 'package:local_auth_android/local_auth_android.dart';
// ignore: depend_on_referenced_packages
import 'package:local_auth_darwin/local_auth_darwin.dart';
import 'package:root_checker_plus/root_checker_plus.dart';

import '../http/api_keys.dart';

class AppSecurity {
  static const platform = MethodChannel('com.cmds.luvpay/root');
  static String message = '';
  static bool rootedCheck = false;
  static bool devMode = false;
  static bool jailbreak = false;
  static bool isEmulator = false;

  //work in background

  static Future<List> checkDevMode() async {
    if (Platform.isIOS) {
      await checkIfIosEmulator();
    } else {
      await developerMode();
    }

    if (devMode || isEmulator) {
      message = 'In developer mode';
      return [
        {
          'is_secured': !ApiKeys.isProduction,
          'msg': !ApiKeys.isProduction ? "" : message,
        },
      ];
    } else {
      return [
        {'is_secured': true, 'msg': ""},
      ];
    }
  }

  static Future<List> checkDeviceSecurity() async {
    if (Platform.isAndroid) {
      await androidRootChecker();
      await developerMode();
      await checkIfAndroidEmulator();
    } else if (Platform.isIOS) {
      await iosJailbreak();
      await checkIfIosEmulator();
    }

    if (rootedCheck || devMode || jailbreak || isEmulator) {
      if (rootedCheck && jailbreak && devMode && isEmulator) {
        message =
            'Rooted, jailbroken, in developer mode, and running on an emulator';
      } else if (rootedCheck && jailbreak && devMode) {
        message = 'Rooted, jailbroken, and in developer mode';
      } else if (rootedCheck && jailbreak) {
        message = 'Rooted and jailbroken';
      } else if (rootedCheck && devMode) {
        message = 'Rooted and in developer mode';
      } else if (jailbreak && devMode) {
        message = 'Jailbroken and in developer mode';
      } else if (rootedCheck) {
        message = 'Rooted';
      } else if (jailbreak) {
        message = 'Jailbroken';
      } else if (devMode) {
        message = 'In developer mode';
      } else if (isEmulator) {
        message = 'Running on an emulator';
      }
      return [
        {
          'is_secured': !ApiKeys.isProduction,
          'msg': !ApiKeys.isProduction ? "" : message,
        },
      ];
    } else {
      return [
        {'is_secured': true, 'msg': ""},
      ];
    }
  }

  static Future<void> developerMode() async {
    try {
      devMode = (await RootCheckerPlus.isDeveloperMode())!;
    } on PlatformException {
      devMode = false;
    }
  }

  static Future<void> iosJailbreak() async {
    try {
      jailbreak = (await RootCheckerPlus.isJailbreak())!;
    } on PlatformException {
      jailbreak = false;
    }
  }

  static Future<void> androidRootChecker() async {
    try {
      final bool isRooted = await platform.invokeMethod('isRooted');
      rootedCheck = isRooted;
    } on PlatformException catch (e) {
      debugPrint("Failed to get root status: '${e.message}'.");
      rootedCheck = true;
    }
  }

  static Future<void> checkIfIosEmulator() async {
    final deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      isEmulator = !androidInfo.isPhysicalDevice;
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      isEmulator = !iosInfo.isPhysicalDevice;
    }

    if (isEmulator) {
    } else {}
  }

  static Future<void> checkIfAndroidEmulator() async {
    try {
      final bool isEmulatorDevice = await platform.invokeMethod('isEmulator');

      isEmulator = isEmulatorDevice;
    } on PlatformException catch (e) {
      debugPrint("Failed to get emulator status: '${e.message}'.");
      isEmulator = true;
    }
  }

  static Future<bool> authenticateBio() async {
    final LocalAuthentication auth = LocalAuthentication();

    bool authenticated = false;
    try {
      authenticated = await auth.authenticate(
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
        localizedReason: 'Please authenticate to continue',
        authMessages: const <AuthMessages>[
          AndroidAuthMessages(
            signInTitle: 'Biometric authentication required!',
            cancelButton: 'No thanks',
          ),
          IOSAuthMessages(cancelButton: 'No thanks'),
        ],
      );
    } catch (e) {
      debugPrint("e $e");
    }
    return authenticated;
  }
}
