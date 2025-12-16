import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:luvpay/http/http_request.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';

import '../../auth/authentication.dart';
import '../../custom_widgets/alert_dialog.dart';
import '../../custom_widgets/app_color_v2.dart';
import '../../functions/functions.dart';
import '../../http/api_keys.dart';
import '../biller_screen/bill_receipt.dart';
import '../biller_screen/biller_screen.dart';
import '../merchant/pay_merchant.dart';
import '../routes/routes.dart';
import 'view.dart';

class BillsPaymentController extends GetxController {
  final GlobalKey<FormState> confirmFormKey = GlobalKey<FormState>();
  final arguments = Get.arguments;
  RxBool isShowPass = false.obs;
  TextEditingController accNo = TextEditingController();
  TextEditingController accName = TextEditingController();
  TextEditingController billRefNo = TextEditingController();
  TextEditingController billAmount = TextEditingController();
  TextEditingController note = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  TextEditingController myPass = TextEditingController();

  @override
  void onInit() {
    accNo.text = arguments["accountno"];
    accName.text = arguments["account_name"];
    super.onInit();
  }

  Future<dynamic> getpaymentHK() async {
    // CustomDialogStack.showLoading(Get.context!);
    final userID = await Authentication().getUserId();

    final paymentKey =
        await HttpRequestApi(api: "${ApiKeys.getPaymentKey}$userID").get();
    if (paymentKey == "No Internet") {
      CustomDialogStack.showConnectionLost(Get.context!, () {
        Get.back();
      });
      return null;
    }
    if (paymentKey == null) {
      CustomDialogStack.showServerError(Get.context!, () {
        Get.back();
      });

      return null;
    }
    if (paymentKey["items"].isNotEmpty) {
      return paymentKey["items"][0]["payment_hk"].toString();
    } else {
      CustomDialogStack.showServerError(Get.context!, () {
        Get.back();
      });

      return null;
    }
  }

  void getBillerKey() async {
    CustomDialogStack.showLoading(Get.context!);
    final paymentHk = await getpaymentHK();
    Get.back();

    if (paymentHk != null) {
      payBills(paymentHk);
    }
  }

  void payBills(String paymentHk) async {
    CustomDialogStack.showLoading(Get.context!);
    final billAcct = accNo.text;
    final billNo = billRefNo.text;
    final accountName = accName.text;
    final amount = billAmount.text;

    double serviceFee =
        double.tryParse(arguments['service_fee'].toString()) ?? 0.0;
    double userAmount = double.tryParse(amount) ?? 0.0;
    double addedAmount = serviceFee + userAmount;
    String totalAmount = addedAmount.toStringAsFixed(2);
    int userId = await Authentication().getUserId();
    var parameter = {
      "luvpay_id": userId.toString(),
      "biller_id": arguments["biller_id"].toString(),
      "bill_acct_no": billAcct,
      "amount": totalAmount,
      "payment_hk": paymentHk,
      "bill_no": billNo,
      "account_name": accountName,
      'original_amount': amount,
    };

    HttpRequestApi(
      api: ApiKeys.postPayBills,
      parameters: parameter,
    ).postBody().then((returnPost) async {
      Get.back();
      if (returnPost == "No Internet") {
        CustomDialogStack.showConnectionLost(Get.context!, () {
          Get.back();
        });
      } else if (returnPost == null) {
        CustomDialogStack.showServerError(Get.context!, () {
          Get.back();
        });
      } else {
        if (returnPost["success"] == 'Y') {
          accNo.clear();
          accName.clear();
          billRefNo.clear();
          billAmount.clear();
          final result = await Get.to(
            BillPaymentReceipt(
              apiResponse: returnPost,
              paymentParams: parameter,
            ),
          );
          if (result != null) {
            Get.back(result: true);
          }
        } else {
          CustomDialogStack.showError(
            Get.context!,
            "Error",
            returnPost["msg"],
            () {
              Get.back();
            },
          );
        }
      }
    });
  }

  bool isValidResponse(dynamic res) {
    if (res == null) return false;
    if (res == "Error" || res == "Failed") return false;
    if (res == "" || res == "{}" || res == "[]") return false;

    // If it's a map and contains required fields
    if (res is Map && res.isNotEmpty) return true;
    if (res is List && res.isNotEmpty) return true;

    return false;
  }

  void handleSuccess(
    String args,
    String type,
    dynamic response,
    serviceName,
    serviceAddress,
  ) async {
    // Navigate or handle according to type
    final paymentHk = await getpaymentHK();
    Get.back();
    if (type == "biller") {
      Get.to(BillerScreen(data: response["items"], paymentHk: paymentHk));
    } else {
      List itemData = [
        {
          "data": response["items"],
          'merchant_key': args,
          "merchant_name": serviceName,
          'merchant_address': serviceAddress,
          "payment_key": paymentHk,
        },
      ];
      Get.to(
        Scaffold(
          backgroundColor: AppColorV2.background,
          appBar: AppBar(
            elevation: 1,
            backgroundColor: AppColorV2.lpBlueBrand,
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarColor: AppColorV2.lpBlueBrand,
              statusBarBrightness: Brightness.dark,
              statusBarIconBrightness: Brightness.light,
            ),
            title: Text("Pay Merchant"),
            centerTitle: true,
            leading: IconButton(
              onPressed: () {
                Get.back();
              },
              icon: Icon(Iconsax.arrow_left, color: Colors.white),
            ),
          ),
          body: PayMerchant(data: itemData),
        ),
      );
    }
  }

  Future<void> addFavorites() async {
    int userId = await Authentication().getUserId();

    CustomDialogStack.showConfirmation(
      Get.context!,
      "Add to Favorites",
      "Do you want to add this biller to your favorites?",
      leftText: "No",
      rightText: "Yes",
      () {
        Get.back();
      },
      () {
        Get.back();

        CustomDialogStack.showLoading(Get.context!);
        var parameter = {
          "user_id": userId,
          "biller_id": arguments["biller_id"],
          "account_no": accNo.text,
          "account_name": accName.text,
        };

        HttpRequestApi(api: ApiKeys.postAddFavBiller, parameters: parameter)
            .postBody()
            .then((returnPost) async {
              Get.back();
              if (returnPost == "No Internet") {
                CustomDialogStack.showConnectionLost(Get.context!, () {
                  Get.back();
                });
                return {"response": returnPost, "data": []};
              }
              if (returnPost == null) {
                CustomDialogStack.showServerError(Get.context!, () {
                  Get.back();
                });
                return {"response": returnPost, "data": []};
              }
              if (returnPost["success"] == 'Y') {
                CustomDialogStack.showSuccess(
                  Get.context!,
                  "Success",
                  "Successfully added to favorites.",
                  leftText: "Okay",
                  () {
                    Get.back();
                  },
                );
              } else {
                CustomDialogStack.showError(
                  Get.context!,
                  "luvpark",
                  returnPost["msg"],
                  () {
                    Get.back();
                  },
                );
              }
            })
            .whenComplete(() {
              Future.delayed(const Duration(seconds: 2), () {});
            });
      },
    );
  }

  Future<void> saveTicket(Widget ddWidget) async {
    String randomNumber = Random().nextInt(100000).toString();
    String fname = 'luvpark$randomNumber.png';

    CustomDialogStack.showLoading(Get.context!);

    ScreenshotController()
        .captureFromWidget(ddWidget, delay: const Duration(seconds: 3))
        .then((image) async {
          final dir = await getApplicationDocumentsDirectory();
          final imagePath = await File('${dir.path}/$fname').create();
          await imagePath.writeAsBytes(image);
          GallerySaver.saveImage(imagePath.path).then((result) {
            Get.back();
            CustomDialogStack.showSuccess(
              Get.context!,
              "Success",
              "Receipt has been saved. Please check your gallery.",
              leftText: "Okay",
              () {
                Get.back();
              },
            );
          });
        });
  }

  @override
  void onClose() {
    super.onClose();
  }
}
