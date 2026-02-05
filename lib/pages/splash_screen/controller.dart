import 'dart:async';
import 'dart:io';

import 'package:app_version_update/data/models/app_version_result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:get/get.dart';
import 'package:luvpay/pages/splash_screen/util/update_app.dart';
import '../../auth/authentication.dart';
import '../../bg_process/luvpay/session_service.dart';
import '../../custom_widgets/variables.dart';
import '../../security/app_security.dart';
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
      duration: const Duration(seconds: 5),
    );

    animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.fastEaseInToSlowEaseOut,
    );

    _controller.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      initializeApp();
    });

    super.onInit();
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
    basicStatusCheck();
  }

  basicStatusCheck() async {
    await SessionService.enforce();

    final data = await Authentication().getUserData2();
    final userLogin = await Authentication().getUserLogin();

    if (data != null) {
      final service = FlutterBackgroundService();
      service.invoke('updateUserLogin', {
        'userId':
            userLogin != null ? int.parse(userLogin['user_id'].toString()) : 0,
      });

      if (userLogin == null || userLogin["is_login"] == "N") {
        Get.toNamed(Routes.login);
        return;
      } else {
        Get.offAllNamed(Routes.dashboard);
      }
    } else {
      Timer(const Duration(seconds: 3), () {
        Get.offAllNamed(Routes.onboarding);
      });
    }
  }

  void _showCustomAlertDialog(BuildContext context, AppVersionResult data) {
    Get.to(UpdateApp(), arguments: data);
  }

  @override
  void onClose() {
    _controller.dispose();
    super.onClose();
  }

  SplashController();
}
