import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:luvpay/auth/authentication.dart';
import 'package:luvpay/shared/dialogs/dialogs.dart';
import 'package:luvpay/shared/widgets/variables.dart';
import 'package:luvpay/core/utils/functions/functions.dart';
import 'package:luvpay/core/network/http/api_keys.dart';
import 'package:luvpay/core/network/http/http_request.dart';
import 'package:luvpay/shared/components/otp_field/view.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../routes/routes.dart';

class RegistrationController extends GetxController
    with GetSingleTickerProviderStateMixin {
  RxBool isShowPass = false.obs;
  RxBool isLoading = false.obs;
  RxInt passStrength = 1.obs;
  RxInt storedOtp = 0.obs;
  final GlobalKey<FormState> formKeyRegister = GlobalKey<FormState>();
  TextEditingController mobileNumber = TextEditingController();
  TextEditingController password = TextEditingController();
  TextEditingController referralCode = TextEditingController();
  bool isLogin = false;
  bool isInternetConnected = true;
  RxBool isApplied = false.obs;

  bool isTappedReg = false;
  var usersLogin = [];

  void toggleLoading(bool value) {
    isLoading.value = value;
  }

  void onPasswordChanged(String value) {
    if (value.isEmpty) {
      passStrength.value = 1;
    } else {
      passStrength.value = Variables.getPasswordStrength(value);
    }
    update();
  }

  void onMobileChanged(String value) {
    if (value.startsWith("0")) {
      mobileNumber.text = value.substring(1);
    } else {
      mobileNumber.text = value;
    }
    update();
  }

  Future<bool> validateReferral() async {
    final code = referralCode.text.trim();

    if (code.isEmpty) {
      CustomDialogStack.showInfo(
        Get.context!,
        "Referral Code",
        "Please enter a referral code.",
        () {
          Get.back();
        },
      );
      return false;
    }

    if (Get.isBottomSheetOpen ?? false) Get.back();

    CustomDialogStack.showLoading(Get.context!);

    try {
      String api = "";
      final res =
          await HttpRequestApi(
            api: api,
            parameters: {"referral_code": code},
          ).postBody();

      Get.back();

      if (res == "No Internet" || res == null) {
        CustomDialogStack.showServerError(Get.context!, () => Get.back());
        return false;
      }

      final ok = res["success"] == "Y";
      if (!ok) {
        CustomDialogStack.showError(
          Get.context!,
          "luvpay",
          res["msg"] ?? "Invalid code.",
          () => Get.back(),
        );
        return false;
      }

      return true;
    } catch (_) {
      Get.back();
      CustomDialogStack.showServerError(Get.context!, () => Get.back());
      return false;
    }
  }

  Future<void> onSubmit() async {
    String devKey = await Functions().getUniqueDeviceId();
    Map<String, dynamic> parameters = {
      "mobile_no": "63${mobileNumber.text.toString().replaceAll(" ", "")}",
      "pwd": password.text,
      "device_key": devKey.toString(),
      // "referral_code": referralCode.text,
    };
    print("parameters $parameters");

    CustomDialogStack.showConfirmation(
      Get.context!,
      "Create Account",
      "Are you sure you want to proceed?",
      leftText: "No",
      rightText: "Yes",
      () {
        Get.back();
      },
      () {
        Get.back();
        CustomDialogStack.showLoading(Get.context!);

        HttpRequestApi(
          api: ApiKeys.postUserReg,
          parameters: parameters,
        ).postBody().then((returnPost) async {
          Get.back();
          if (returnPost == "No Internet") {
            CustomDialogStack.showConnectionLost(Get.context!, () {
              Get.back();
            });
            return;
          }

          if (returnPost == null) {
            CustomDialogStack.showServerError(Get.context!, () {
              Get.back();
            });
            return;
          }
          if (returnPost["success"] == "Y") {
            final prefs = await SharedPreferences.getInstance();
            prefs.setBool('isLoggedIn', false);
            final plainText = jsonEncode(parameters);
            Authentication().encryptData(plainText);

            requestOtp();

            return;
          } else {
            CustomDialogStack.showError(
              // maxLines: 3,
              Get.context!,
              "luvpay",
              returnPost["msg"],
              () {
                Get.back();
              },
            );
            // Get.back();
            return;
          }
        });
      },
    );
  }

  Future<void> requestOtp() async {
    CustomDialogStack.showLoading(Get.context!);
    DateTime timeNow = await Functions.getTimeNow();
    Get.back();
    String mobileNo = "63${mobileNumber.text.replaceAll(" ", "")}";
    Map<String, String> reqParam = {
      "mobile_no": mobileNo.toString(),
      "new_pwd": password.text,
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
      Duration difference = otpExpiry.difference(timeNow);

      if (obj["success"] == "Y" || obj["status"] == "PENDING") {
        Map<String, String> putParam = {
          "mobile_no": mobileNo.toString(),
          "req_type": "NA",
          "otp": obj["otp"].toString(),
        };

        Object args = {
          "time_duration": difference,
          "mobile_no": mobileNo.toString(),
          "req_otp_param": reqParam,
          "verify_param": putParam,
          "callback": (otp) {
            if (otp != null) {
              Map<String, dynamic> data = {
                "mobile_no": mobileNo,
                "pwd": password.text,
              };
              final plainText = jsonEncode(data);

              Authentication().encryptData(plainText);
              CustomDialogStack.showSuccess(
                Get.context!,
                "Success!",
                "Your account is ready.\nPlease log in to proceed.",
                leftText: "Okay",
                () {
                  mobileNumber.text == "";
                  password.text == "";
                  Get.offAllNamed(Routes.login);
                },
              );
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

  void visibilityChanged(bool visible) {
    isShowPass.value = visible;
    update();
  }

  @override
  void onInit() {
    mobileNumber = TextEditingController();
    password = TextEditingController();
    super.onInit();
  }

  @override
  void onClose() {
    if (formKeyRegister.currentState != null) {
      formKeyRegister.currentState!.reset();
    }

    super.onClose();
  }

  RegistrationController();
}
