// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luvpay/http/api_keys.dart';
import 'package:luvpay/http/http_request.dart';

import '../../auth/authentication.dart';
import '../../custom_widgets/alert_dialog.dart';
import '../../custom_widgets/app_color_v2.dart';
import '../../custom_widgets/floating_toast_manager.dart';

class VouchersController extends GetxController {
  RxBool isLoading = true.obs;
  RxBool isNetConn = true.obs;

  Future<void> putVoucher(
    String voucherCode,
    BuildContext context,
    GlobalKey textFieldKey, {
    bool? fromBooking,
  }) async {
    try {
      final item = await Authentication().getUserData();
      if (item == null) return;

      String userId = jsonDecode(item)['user_id'].toString();
      CustomDialogStack.showLoading(context);
      final String api = "${ApiKeys.vouchers}/";
      final dynamic params = {"user_id": userId, "voucher_code": voucherCode};
      final objKey =
          await HttpRequestApi(api: api, parameters: params).putBody();
      if (fromBooking == false) {
        Get.back(closeOverlays: true);
      } else {
        Get.back();
      }

      if (objKey == "No Internet") {
        isNetConn.value = false;
        isLoading.value = false;
        CustomDialogStack.showConnectionLost(context, () => Get.back());
        return;
      }

      if (objKey == null) {
        isNetConn.value = true;
        isLoading.value = false;
        CustomDialogStack.showServerError(context, () => Get.back());
        return;
      }

      isNetConn.value = true;
      isLoading.value = false;

      if (objKey["success"] == 'Y') {
        FloatingToastManager(
          context: context,
          message: "Voucher successfully claimed!",
          targetKey: textFieldKey,
          textColor: AppColorV2.correctState,
          image: "state_success",
        );
      } else {
        final errorMessage = objKey['msg']?.toString() ?? 'Unknown error';
        final lowerCaseMessage = errorMessage.toLowerCase();

        String message;
        Color textColor;
        String image;

        if (lowerCaseMessage.contains('claimed')) {
          message = errorMessage;
          textColor = AppColorV2.lpBlueBrand;
          image = "state_claimed";
        } else if (lowerCaseMessage.contains('expired') ||
            lowerCaseMessage.contains('reached')) {
          message = errorMessage;
          textColor = AppColorV2.incorrectState;
          image = "state_expired";
        } else if (lowerCaseMessage.contains('invalid')) {
          message = errorMessage;
          textColor = AppColorV2.incorrectState;
          image = "state_invalid";
        } else {
          message = errorMessage;
          textColor = AppColorV2.incorrectState;
          image = "state_expired";
        }

        FloatingToastManager(
          context: context,
          message: message,
          targetKey: textFieldKey,
          textColor: textColor,
          image: image,
        );
      }
    } catch (e) {
      Get.back(closeOverlays: true);

      CustomDialogStack.showError(
        context,
        "luvpay",
        "An unexpected error occurred. Please try again.",
        () {},
      );
    }
  }
}
