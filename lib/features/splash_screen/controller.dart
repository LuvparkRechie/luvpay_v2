// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:get/get.dart';
import '../../auth/authentication.dart';
import '../../shared/widgets/variables.dart';
import '../../core/security/security/app_security.dart';
import '../routes/routes.dart';

class SplashController extends GetxController
    with GetSingleTickerProviderStateMixin {
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
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

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
    _verifyVersion();
  }

  void _verifyVersion() async {
    // final packageInfo = await PackageInfo.fromPlatform();

    // try {
    //   final result = await AppVersionUpdate.checkForUpdates(
    //     appleId: '6473724622',
    //     playStoreId: 'com.cmds.luvpay',
    //   );

    //   bool canUpdate;

    //   final storeVersion = Version.parse(result.storeVersion.toString());
    //   final localVersion = Version.parse(packageInfo.version);

    //   canUpdate = storeVersion > localVersion;

    //   if (canUpdate) {
    //     _showCustomAlertDialog(Get.context!, result);
    //   } else {
    //     basicStatusCheck();
    //   }
    // } catch (e) {
    //   basicStatusCheck();
    // }
    basicStatusCheck();
  }

  basicStatusCheck() async {
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
