import 'dart:convert';
import 'dart:math';

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

class ForgotVerifiedAcctController extends GetxController {
  ForgotVerifiedAcctController();
  String mobileNoParam = Get.arguments;

  TextEditingController answer = TextEditingController();
  TextEditingController newPass = TextEditingController();
  final GlobalKey<FormState> formKeyForgotVerifiedAcc = GlobalKey<FormState>();
  RxBool isLoading = false.obs;
  RxBool isBtnLoading = false.obs;
  RxBool isInternetConn = true.obs;
  RxBool isShowNewPass = false.obs;
  RxBool isVerifiedAns = false.obs;
  RxList questionData = [].obs;
  RxInt passStrength = 1.obs;
  RxString question = "".obs;
  int? randomNumber;

  @override
  void onInit() {
    answer = TextEditingController();
    Random random = Random();
    randomNumber = random.nextInt(3) + 1;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getSecQdata();
    });
    super.onInit();
  }

  void onPasswordChanged(String value) {
    passStrength.value = Variables.getPasswordStrength(value);
    update();
  }

  void onToggleNewPass(bool isShow) {
    isShowNewPass.value = isShow;
    update();
  }

  void getSecQdata() {
    isInternetConn.value = true;
    isLoading.value = true;

    String subApi =
        "${ApiKeys.getSecQue}?mobile_no=$mobileNoParam&secq_no=$randomNumber";

    HttpRequestApi(api: subApi).get().then((returnData) {
      if (returnData == "No Internet") {
        isInternetConn.value = false;
        isLoading.value = false;
        CustomDialogStack.showConnectionLost(Get.context!, () {
          Get.back();
        });

        return;
      }
      if (returnData == null) {
        isInternetConn.value = true;
        isLoading.value = false;
        CustomDialogStack.showServerError(Get.context!, () {
          Get.back();
        });
        return;
      } else {
        isInternetConn.value = true;
        isLoading.value = false;
        if (returnData["items"].isNotEmpty) {
          questionData.value = returnData["items"];
        } else {
          CustomDialogStack.showError(
            Get.context!,
            "luvpay",
            "Make sure that you've entered the correct phone number.",
            () {
              Get.back();
            },
          );
          return;
        }
      }
    });
  }

  void secRequestOtp() async {
    CustomDialogStack.showLoading(Get.context!);
    DateTime timeNow = await Functions.getTimeNow();
    Get.back();
    Map<String, String> reqParam = {
      "mobile_no": mobileNoParam.toString(),
      "secq_no": randomNumber.toString(),
      "secq_id": questionData[0]["secq_id"].toString(),
      "seca": answer.text,
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

      if (obj["success"] == "Y" || obj["status"] == "PENDING") {
        Map<String, String> putParam = {
          "mobile_no": mobileNoParam.toString(),
          "otp": obj["otp"].toString(),
          "new_pwd": newPass.text,
        };
        Object args = {
          "time_duration": difference,
          "mobile_no": mobileNoParam,
          "req_otp_param": reqParam,
          "verify_param": putParam,
          "callback": (otp) async {
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
}
