// ignore_for_file: avoid_print, unnecessary_string_interpolations

import 'dart:typed_data';

import 'package:get/get.dart';
import 'package:luvpay/custom_widgets/longprint.dart';
import '../../custom_widgets/alert_dialog.dart';
import '../../custom_widgets/app_color_v2.dart';
import '../../functions/functions.dart';
import '../../http/api_keys.dart';
import '../../http/http_request.dart';

class SubWalletController extends GetxController
    with GetSingleTickerProviderStateMixin {
  RxList userData = [].obs;
  RxDouble numericBalance = 0.0.obs;
  RxString luvpayBal = '0.00'.obs;
  RxList<Map<String, dynamic>> categoryList = <Map<String, dynamic>>[].obs;
  final Map<String, Uint8List> iconCache = {};
  @override
  void onInit() {
    super.onInit();
    luvpayBalance();
    getSubWalletCategories();
  }

  Future<void> getSubWalletCategories() async {
    try {
      final api = ApiKeys.getSubWalletCategories;
      final returnData = await HttpRequestApi(api: api).get();

      if (returnData == "No Internet") {
        if (Get.context != null) {
          CustomDialogStack.showConnectionLost(Get.context!, Get.back);
        }
        return;
      }

      if (returnData == null || returnData is! Map) {
        if (Get.context != null) {
          CustomDialogStack.showServerError(Get.context!, Get.back);
        }
        return;
      }

      final items = returnData["items"];

      List<Map<String, dynamic>> processedCategories = [];

      for (var item in items) {
        processedCategories.add({
          'category_title': item['category_title'] ?? 'Unknown',
          'image_base64': item['image_base64'] ?? '',
          'color': item['color'] ?? AppColorV2.lpBlueBrand,
        });
      }

      categoryList.value = processedCategories;
    } catch (e, s) {
      longPrint('Error fetching subwallet categories: $e');
      longPrint('$s');
    }
  }

  Future<void> luvpayBalance() async {
    try {
      final data = await Functions.getUserBalance();
      userData.value = data;
      luvpayBal.value = userData[0]["items"][0]["amount_bal"];
      numericBalance.value = double.parse(luvpayBal.value);
    } catch (e) {
      print('Error fetching LuvPay balance: $e');
    }
  }

  Future<void> updateMainBalance(double amountToDeduct) async {
    try {
      numericBalance.value -= amountToDeduct;
      luvpayBal.value = numericBalance.value.toStringAsFixed(2);

      print(
        'Deducted $amountToDeduct from main balance. New balance: ${luvpayBal.value}',
      );
    } catch (e) {
      print('Error updating main balance: $e');
    }
  }

  Future<void> returnToMainBalance(double amountToAdd) async {
    try {
      numericBalance.value += amountToAdd;
      luvpayBal.value = numericBalance.value.toStringAsFixed(2);

      print(
        'Added $amountToAdd to main balance. New balance: ${luvpayBal.value}',
      );
    } catch (e) {
      print('Error updating main balance: $e');
    }
  }

  @override
  void onClose() {
    userData.clear();
    categoryList.clear();
    luvpayBal.value = '0.0';
    numericBalance.value = 0.0;
    super.onClose();
  }
}
