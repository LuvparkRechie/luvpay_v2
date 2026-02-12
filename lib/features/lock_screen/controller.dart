import 'dart:async';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../auth/authentication.dart';
import 'package:luvpay/shared/dialogs/dialogs.dart';
import '../../core/utils/functions/functions.dart';
import '../../core/database/sqlite/pa_message_table.dart';
import '../../core/database/sqlite/reserve_notification_table.dart';
import '../routes/routes.dart';

class LockScreenController extends GetxController {
  LockScreenController();
  final parameter = Get.arguments;
  RxBool hasNet = true.obs;

  RxString formattedTime = "".obs;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getParamData();
    });
  }

  void getParamData() async {
    await Authentication().enableTimer(false);
    await Authentication().setLogoutStatus(true);
    await Authentication().setBiometricStatus(false);
    await Authentication().remove("userData");
    await PaMessageDatabase.instance.deleteAll();
    NotificationDatabase.instance.deleteAll();
    AwesomeNotifications().cancelAllSchedules();
    AwesomeNotifications().cancelAll();
    DateTime timeNow = await Functions.getTimeNow();

    DateTime localDate = DateTime.parse(parameter[0]["locked_expiry_on"]);

    DateTime parsedDateNow = DateTime(
      timeNow.year,
      timeNow.month,
      timeNow.day,
      timeNow.hour,
      timeNow.minute,
    );
    DateTime parsedLocDate = DateTime(
      localDate.year,
      localDate.month,
      localDate.day,
      localDate.hour,
      localDate.minute,
    );

    formattedTime.value = parameter[0]["msg"].toString();

    if (parsedDateNow.isBefore(parsedLocDate)) {
      timeout(parsedLocDate);
    } else {
      unlockAccount();
    }
  }

  void timeout(DateTime localDate) {
    Timer.periodic(Duration(seconds: 3), (timer) async {
      DateTime timeNow = await Functions.getTimeNow();

      if (timeNow.isAfter(localDate) || timeNow.isAtSameMomentAs(localDate)) {
        timer.cancel(); // Stop the timer
        unlockAccount();
      }
    });
  }

  void unlockAccount() async {
    hasNet.value = true;

    Get.offAndToNamed(Routes.login);
  }

  void switchAccount() async {
    final uData = await Authentication().getUserData2();
    CustomDialogStack.showConfirmation(
      Get.context!,
      "Switch Account",
      "Are you sure you want to switch Account?",
      leftText: "No",
      rightText: "Yes",
      () {
        Get.back();
      },
      () async {
        Get.back();
        Functions.logoutUser(
          uData == null ? "" : uData["session_id"].toString(),
          (isSuccess) async {
            if (isSuccess["is_true"]) {
              await Authentication().setLogoutStatus(true);
              await Authentication().setBiometricStatus(false);
              await Authentication().remove("userData");
              await PaMessageDatabase.instance.deleteAll();
              NotificationDatabase.instance.deleteAll();
              AwesomeNotifications().cancelAllSchedules();
              AwesomeNotifications().cancelAll();
              Get.offAndToNamed(Routes.login);
            }
          },
        );
      },
    );
  }
}
