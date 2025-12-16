import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';
import 'package:luvpay/http/http_request.dart';

import '../../auth/authentication.dart';
import '../../custom_widgets/alert_dialog.dart';
import '../../functions/functions.dart';
import '../../http/api_keys.dart';
import '../../web_view/webview.dart';
import '../change_password/change_pass_ver.dart';
import '../routes/routes.dart';

class SecuritySettingsController extends GetxController {
  RxString mobileNo = "".obs;
  RxList userData = [].obs;
  final LocalAuthentication auth = LocalAuthentication();
  RxBool canCheckBiometrics = false.obs;
  RxBool isBiometricSupported = false.obs;
  RxBool isLoading = false.obs;
  RxBool isToggle = false.obs;
  bool isAuth = false;

  @override
  void onInit() {
    super.onInit();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      canCheckBiometrics.value = await auth.canCheckBiometrics;
      isBiometricSupported.value = await auth.isDeviceSupported();
    } catch (e) {
      canCheckBiometrics.value = false;
      isBiometricSupported.value = false;
    }

    if (isBiometricSupported.value) {
      checkIfEnabledBio();
    } else {
      isLoading.value = false;
    }
  }

  Future<void> checkIfEnabledBio() async {
    try {
      bool? isEnabledBio = await Authentication().getBiometricStatus();
      isToggle.value = isEnabledBio ?? false;
    } catch (e) {
      debugPrint("Error checking if biometric is enabled: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void authenticateWithBiometrics(bool enable) async {
    try {
      final bool canCheck = await auth.canCheckBiometrics;
      final bool isSupported = await auth.isDeviceSupported();

      if (!canCheck || !isSupported) {
        Get.snackbar("Unavailable", " authentication is not supported.");
        return;
      }

      final bool authenticated = await auth.authenticate(
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

      isAuth = authenticated;
      if (isAuth) {
        isToggle.value = enable;
        await Authentication().setBiometricStatus(enable);
      } else {
        Get.snackbar("Failed", "Authentication was not successful.");
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to authenticate.");
    }
  }

  void toggleBiometricAuthentication(bool value) {
    authenticateWithBiometrics(value);
  }

  Future<void> cancelAuthentication() async {
    try {
      await auth.stopAuthentication();
    } catch (e) {}
  }

  Future<void> deleteAccount() async {
    CustomDialogStack.showLoading(Get.context!);
    try {
      final mydata = await Authentication().getUserData2();
      mobileNo.value = mydata["mobile_no"];

      Map<String, String> param = {"mobile_no": mobileNo.value};
      var returnData =
          await HttpRequestApi(
            api: ApiKeys.postDeleteUserAcct,
            parameters: param,
          ).deleteData();

      Get.back();

      if (returnData == "No Internet") {
        CustomDialogStack.showConnectionLost(Get.context!, () => Get.back());
        return;
      }

      if (returnData == null) {
        CustomDialogStack.showServerError(Get.context!, () => Get.back());
        return;
      }

      if (returnData["success"] == "Y") {
        _showSuccessDialog();
      } else {
        _showErrorDialog("Delete Account", returnData["msg"]);
      }
    } catch (e) {
      Get.back();
      Get.snackbar("Error", "Failed to delete account.");
    }
  }

  void _showErrorDialog(String title, String message) {
    CustomDialogStack.showError(Get.context!, title, message, () => Get.back());
  }

  void _showSuccessDialog() {
    CustomDialogStack.showSuccess(
      Get.context!,
      "Success",
      "You will be directed to delete account page. Wait for customer support",
      leftText: "Okay",
      () {
        Get.back();
        Get.to(
          WebviewPage(
            urlDirect: "https://luvpark.ph/account-deletion/",
            label: "Account Deletion",
            isBuyToken: false,
            callback: () async {
              CustomDialogStack.showLoading(Get.context!);

              CustomDialogStack.showInfo(
                Get.context!,
                "Account status",
                "Your account might not be active.",
                () async {
                  Get.back();
                  CustomDialogStack.showLoading(Get.context!);
                  await Future.delayed(const Duration(seconds: 3));

                  final userLogin = await Authentication().getUserLogin();
                  List userDataList =
                      [userLogin].map((e) {
                        e["is_login"] = "N";
                        return e;
                      }).toList();

                  await Authentication().setLogin(jsonEncode(userDataList[0]));

                  Get.back();
                  Get.offAllNamed(Routes.login);
                },
              );
            },
          ),
        );
      },
    );
  }

  void verifyMobile() async {
    try {
      final data = await Authentication().getUserData2();
      Functions().verifyMobile(data["mobile_no"], (objData) {
        if (objData["success"]) {
          if (objData["data"]["is_verified"] == "Y") {
            Functions().getSecQdata(data["mobile_no"], (cbData) {
              if (cbData != null) {
                Get.to(
                  ChangePasswordVerified(),
                  arguments: {"mobile_no": data["mobile_no"], "data": cbData},
                );
              }
            });
          } else {
            Get.toNamed(Routes.createNewPass, arguments: data["mobile_no"]);
          }
        }
      });
    } catch (e) {
      Get.snackbar("Error", "Mobile verification failed.");
    }
  }
}
