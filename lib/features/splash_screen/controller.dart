// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:io';
import 'package:app_version_update/app_version_update.dart';
import 'package:app_version_update/data/models/app_version_result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:version/version.dart';
import '../../auth/authentication.dart';
import '../../shared/widgets/variables.dart';
import '../../core/security/security/app_security.dart';
import '../routes/routes.dart';
import 'util/update_app.dart';

class SplashController extends GetxController
    with GetSingleTickerProviderStateMixin {
  static const String _appleId = '6453687263'; //luvpayt ios apple id
  // static const String _appleId =
  //     '6473724622'; //mao ni pang test update force, luvpark ni sya
  static const String _playStoreId = 'com.cmds.luvpay';

  late AnimationController _controller;
  late Animation<double> animation;
  RxBool isNetConn = true.obs;
  bool rootedCheck = false;
  bool devMode = false;
  bool jailbreak = false;
  String message = '';
  String release = "";
  @override
  void onInit() {
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    animation =
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);

    _controller.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 120));
      unawaited(initializeApp());
    });
    super.onInit();
  }

  Future<void> _waitSplashPaint({
    Duration minDelay = const Duration(milliseconds: 450),
  }) async {
    await Future.delayed(minDelay);
  }

  Future<void> initializeApp() async {
    List appSecurity = await AppSecurity.checkDeviceSecurity();
    bool isAppSecured = appSecurity[0]["is_secured"];

    if (isAppSecured) {
      await determineInitialRoute();
    } else {
      Variables.showSecurityPopUp(appSecurity[0]["msg"]);
    }
  }

  Future<void> determineInitialRoute() async {
    await _verifyVersion();
  }

  Future<void> _verifyVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();

    try {
      final result = await _checkForStoreUpdate();
      final bool shouldForceUpdate = (result.canUpdate ?? false) ||
          _isStoreVersionNewer(
            localVersion: packageInfo.version,
            storeVersion: result.storeVersion,
          );

      if (shouldForceUpdate) {
        Get.offAll(() => const UpdateApp(), arguments: {
          "data": result,
        });
        return;
      }
    } catch (e) {
      debugPrint("Version check error: $e");
    }

    await basicStatusCheck();
  }

  Future<AppVersionResult> _checkForStoreUpdate() async {
    if (Platform.isIOS) {
      try {
        return await AppVersionUpdate.checkForUpdates(
          appleId: _appleId,
          playStoreId: _playStoreId,
          country: 'ph',
        );
      } catch (_) {
        return AppVersionUpdate.checkForUpdates(
          appleId: _appleId,
          playStoreId: _playStoreId,
        );
      }
    }

    return AppVersionUpdate.checkForUpdates(
      appleId: _appleId,
      playStoreId: _playStoreId,
    );
  }

  bool _isStoreVersionNewer({
    required String localVersion,
    required String? storeVersion,
  }) {
    final parsedLocal = _parseVersion(localVersion);
    final parsedStore = _parseVersion(storeVersion);

    if (parsedLocal == null || parsedStore == null) {
      return false;
    }

    return parsedStore > parsedLocal;
  }

  Version? _parseVersion(String? rawVersion) {
    if (rawVersion == null || rawVersion.trim().isEmpty) {
      return null;
    }

    final cleaned = rawVersion.trim().split('+').first;
    final match = RegExp(r'^\d+(\.\d+){0,2}').firstMatch(cleaned);
    final normalized = match?.group(0);

    if (normalized == null || normalized.isEmpty) {
      return null;
    }

    try {
      return Version.parse(normalized);
    } catch (_) {
      return null;
    }
  }

  Future<void> basicStatusCheck() async {
    final isForcedLogout = await Authentication().getLogoutStatus();
    if (isForcedLogout == true) {
      Get.offAllNamed(Routes.login);
      return;
    }

    final data = await Authentication().getUserData2();
    final userLogin = await Authentication().getUserLogin();

    await _waitSplashPaint(minDelay: const Duration(milliseconds: 900));

    if (data != null) {
      final service = FlutterBackgroundService();
      service.invoke('updateUserLogin', {
        'userId':
            userLogin != null ? int.parse(userLogin['user_id'].toString()) : 0,
      });

      if (userLogin == null || userLogin["is_login"] == "N") {
        Get.offAllNamed(Routes.login);
        return;
      } else {
        Get.offAllNamed(Routes.dashboard);
      }
    } else {
      await Future.delayed(const Duration(milliseconds: 800));
      Get.offAllNamed(Routes.onboarding);
    }
  }

  @override
  void onClose() {
    _controller.dispose();
    super.onClose();
  }

  SplashController();
}
