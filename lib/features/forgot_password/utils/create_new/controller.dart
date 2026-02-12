import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:luvpay/core/network/http/http_request.dart';
import '../../../../auth/authentication.dart';
import 'package:luvpay/shared/dialogs/dialogs.dart';
import '../../../../shared/widgets/variables.dart';
import '../../../../core/utils/functions/functions.dart';
import '../../../../core/network/http/api_keys.dart';
import '../../../../shared/components/otp_field/view.dart';
import '../../../routes/routes.dart';

class CreateNewPassController extends GetxController {
  CreateNewPassController();
  String mobileNoParam = Get.arguments;
  final GlobalKey<FormState> formKeyCreatePass = GlobalKey<FormState>();
  TextEditingController newPass = TextEditingController();
  TextEditingController confirmPass = TextEditingController();

  RxBool isPendingOtp = false.obs;
  RxBool isLoading = false.obs;
  RxBool isInternetConnected = true.obs;
  RxBool isShowNewPass = false.obs;
  RxBool isShowConfirmPass = false.obs;
  RxBool isFinish = true.obs;
  RxInt passStrength = 1.obs;

  RxInt totalMinutes = 0.obs; // Change this to set timer duration
  RxInt remainingSeconds = 0.obs;
  Timer? timer;

  @override
  void onInit() {
    newPass = TextEditingController();
    confirmPass = TextEditingController();

    super.onInit();
  }

  void startTimer() {
    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (remainingSeconds > 0) {
        remainingSeconds.value--;
        isFinish.value = false;
        update();
        isFinish.value = false;
      } else {
        isFinish.value = true;
        timer.cancel();
        update();
      }
    });
  }

  void onToggleNewPass(bool isShow) {
    isShowNewPass.value = isShow;
    update();
  }

  void onToggleConfirmPass(bool isShow) {
    isShowConfirmPass.value = isShow;
    update();
  }

  void onPasswordChanged(String value) {
    passStrength.value = Variables.getPasswordStrength(value);
    update();
  }

  Future<void> requestOtp() async {
    CustomDialogStack.showLoading(Get.context!);
    DateTime timeNow = await Functions.getTimeNow();
    Get.back();
    Map<String, String> reqParam = {
      "mobile_no": mobileNoParam.toString(),
      "new_pwd": newPass.text,
    };

    Functions().requestOtp(reqParam, (obj) async {
      DateTime timeExp = DateFormat(
        "yyyy-MM-dd hh:mm:ss a",
      ).parse(obj["otp_exp_dt"].toString());
      DateTime otpExpiry = DateTime(
        timeExp.year,
        timeExp.month,
        timeExp.day,
        timeExp.hour,
        timeExp.minute,
        timeExp.millisecond,
      );

      // Calculate difference
      Duration difference = otpExpiry.difference(timeNow);
      Map<String, dynamic> putParam = {
        "mobile_no": mobileNoParam.toString(),
        "otp": obj["otp"].toString(),
        "new_pwd": newPass.text,
      };
      if (obj["success"] == "Y" || obj["status"] == "PENDING") {
        Object args = {
          "time_duration": difference,
          "mobile_no": mobileNoParam,
          "req_otp_param": reqParam,
          "verify_param": putParam,
          "is_forget_vfd_pass": false,
          "callback": (otp) {
            if (otp != null) {
              CustomDialogStack.showLoading(Get.context!);

              Map<String, dynamic> postParam = {
                "mobile_no": mobileNoParam.toString(),
                "otp": otp.toString(),
                "new_pwd": newPass.text,
              };

              HttpRequestApi(
                api: ApiKeys.putLogin,
                parameters: postParam,
              ).putBody().then((retvalue) {
                Get.back();
                if (retvalue == "No Internet") {
                  CustomDialogStack.showError(
                    Get.context!,
                    "Error",
                    "Please check your internet connection and try again.",
                    () {
                      Get.back();
                    },
                  );
                  return;
                }
                if (retvalue == null) {
                  CustomDialogStack.showError(
                    Get.context!,
                    "Error",
                    "Error while connecting to server, Please try again.",
                    () {
                      Get.back();
                    },
                  );
                } else {
                  if (retvalue["success"] == "Y") {
                    Map<String, dynamic> data = {
                      "mobile_no": mobileNoParam,
                      "pwd": newPass.text,
                    };
                    final plainText = jsonEncode(data);

                    Authentication().encryptData(plainText);
                    CustomDialogStack.showSuccess(
                      Get.context!,
                      "Success!",
                      "Your password has been updated",
                      leftText: "Okay",
                      () async {
                        Get.offAllNamed(Routes.login);
                      },
                    );
                  } else {
                    CustomDialogStack.showError(
                      Get.context!,
                      "Error",
                      retvalue["msg"],
                      () {
                        Get.back();
                      },
                    );
                  }
                }
              });
            }
          },
        };

        Get.to(
          OtpFieldScreen(arguments: args),
          transition: Transition.rightToLeftWithFade,
          duration: Duration(milliseconds: 400),
        );
      }
    });
  }

  @override
  void onClose() {
    formKeyCreatePass.currentState?.reset();
    timer?.cancel();
    super.onClose();
  }
}
