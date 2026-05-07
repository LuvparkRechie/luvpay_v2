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
import 'package:luvpay/core/network/http/api_keys.dart';

class AppSecurity {
  static const platform = MethodChannel('com.cmds.luvpay/root');
  static String message = '';
  static bool rootedCheck = false;
  static bool devMode = false;
  static bool jailbreak = false;
  static bool isEmulator = false;

  static bool get _shouldEnforce => ApiKeys.enforceSecurity;
  static bool get _rootCheckEnabled => ApiKeys.appSecurityRootCheckEnabled;
  static bool get _jailbreakCheckEnabled =>
      ApiKeys.appSecurityJailbreakCheckEnabled;
  static bool get _developerModeCheckEnabled =>
      ApiKeys.appSecurityDeveloperModeCheckEnabled;
  static bool get _emulatorCheckEnabled =>
      ApiKeys.appSecurityEmulatorCheckEnabled;

  static void _resetFlags() {
    message = '';
    rootedCheck = false;
    devMode = false;
    jailbreak = false;
    isEmulator = false;
  }

  static List<Map<String, dynamic>> _buildResult(List<String> issues) {
    final hasIssue = issues.isNotEmpty;
    final issueMessage = hasIssue ? _composeIssueMessage(issues) : "";
    final isSecured = !hasIssue || !_shouldEnforce;

    if (hasIssue) {
      debugPrint(
          "[AppSecurity] detected: $issueMessage | enforce=$_shouldEnforce");
    }

    message = issueMessage;
    return [
      {
        'is_secured': isSecured,
        'msg': hasIssue && _shouldEnforce ? issueMessage : "",
      },
    ];
  }

  static String _composeIssueMessage(List<String> issues) {
    if (issues.isEmpty) return "";
    if (issues.length == 1) return issues.first;
    if (issues.length == 2) return '${issues.first} and ${issues.last}';
    return '${issues.sublist(0, issues.length - 1).join(', ')}, and ${issues.last}';
  }

  static Future<List> checkDevMode() async {
    _resetFlags();

    await developerMode();

    if (Platform.isIOS) {
      await checkIfIosEmulator();
    } else if (Platform.isAndroid) {
      await checkIfAndroidEmulator();
    }

    final issues = <String>[
      if (devMode) 'In developer mode',
      if (isEmulator) 'Running on an emulator',
    ];

    return _buildResult(issues);
  }

  static Future<List> checkDeviceSecurity() async {
    _resetFlags();

    if (Platform.isAndroid) {
      await androidRootChecker();
      await developerMode();
      await checkIfAndroidEmulator();
    } else if (Platform.isIOS) {
      await iosJailbreak();
      await developerMode();
      await checkIfIosEmulator();
    }

    final issues = <String>[
      if (rootedCheck) 'Rooted',
      if (jailbreak) 'Jailbroken',
      if (devMode) 'In developer mode',
      if (isEmulator) 'Running on an emulator',
    ];

    return _buildResult(issues);
  }

  static Future<void> developerMode() async {
    if (!_developerModeCheckEnabled) {
      devMode = false;
      return;
    }

    if (!Platform.isAndroid) {
      devMode = false;
      return;
    }

    try {
      devMode = (await RootCheckerPlus.isDeveloperMode()) ?? false;
    } on MissingPluginException {
      devMode = false;
    } on PlatformException {
      devMode = false;
    }
  }

  static Future<void> iosJailbreak() async {
    if (!_jailbreakCheckEnabled) {
      jailbreak = false;
      return;
    }

    try {
      jailbreak = (await RootCheckerPlus.isJailbreak()) ?? false;
    } on MissingPluginException {
      jailbreak = false;
    } on PlatformException {
      jailbreak = false;
    }
  }

  static Future<void> androidRootChecker() async {
    if (!_rootCheckEnabled) {
      rootedCheck = false;
      return;
    }

    try {
      final bool isRooted = await platform.invokeMethod('isRooted');
      rootedCheck = isRooted;
    } on MissingPluginException {
      rootedCheck = false;
    } on PlatformException catch (e) {
      debugPrint("Failed to get root status: '${e.message}'.");
      rootedCheck = true;
    }
  }

  static Future<void> checkIfIosEmulator() async {
    if (!_emulatorCheckEnabled) {
      isEmulator = false;
      return;
    }

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
    if (!_emulatorCheckEnabled) {
      isEmulator = false;
      return;
    }

    try {
      final bool isEmulatorDevice = await platform.invokeMethod('isEmulator');

      isEmulator = isEmulatorDevice;
    } on MissingPluginException {
      isEmulator = false;
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
          biometricOnly: true,
          persistAcrossBackgrounding: true,
          localizedReason: 'Please authenticate to continue',
          authMessages: const <AuthMessages>[
            AndroidAuthMessages(
                signInTitle: 'Biometric authentication required!',
                cancelButton: 'No thanks'),
            IOSAuthMessages(cancelButton: 'No thanks'),
          ]);
    } catch (e) {
      debugPrint("e $e");
    }
    return authenticated;
  }
}
