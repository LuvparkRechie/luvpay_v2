import 'dart:async';
import 'dart:io';

import 'package:app_version_update/app_version_update.dart';
import 'package:app_version_update/data/models/app_version_result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:get/get.dart';
import 'package:luvpay/pages/splash_screen/util/update_app.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:version/version.dart';
import '../../http/http_request.dart';
import '../../auth/authentication.dart';
import '../../custom_widgets/variables.dart';
import '../../functions/functions.dart';
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
    // isNetConn.value = true;

    // final response = await HttpRequestApi(api: "").pingInternet();

    // if (response == "Success") {
    //   _verifyVersion();
    // } else {
    //   isNetConn.value = false;
    // }
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

  // basicStatusCheck(NewVersionPlus newVersion) async {
  basicStatusCheck() async {
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
        // LocationService.grantPermission(Get.context!, (isGranted) async {
        //   if (isGranted) {
        //     Get.offAllNamed(Routes.map);
        //   } else {
        //     final response = await Get.toNamed(Routes.permission);

        //     if (response) {
        //       Get.offAllNamed(Routes.map);
        //     }
        //   }
        // });
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
