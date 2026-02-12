// ignore_for_file: unnecessary_null_comparison, unnecessary_string_interpolations, prefer_const_constructors

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luvpay/core/network/http/http_request.dart';
import 'package:luvpay/shared/dialogs/dialogs.dart';
import 'package:screenshot/screenshot.dart';

import '../../auth/authentication.dart';
import '../../core/utils/functions/functions.dart';
import '../../core/network/http/api_keys.dart';
import 'utils/allbillers.dart';
import 'utils/receipt_billing.dart';

class BillersController extends GetxController {
  BillersController();

  final TextEditingController billAccNo = TextEditingController();
  final TextEditingController billerAccountName = TextEditingController();
  final TextEditingController billNo = TextEditingController();
  final TextEditingController amount = TextEditingController();
  final ScreenshotController screenshotController = ScreenshotController();
  Map<String, TextEditingController> controllers2 = {};
  RxBool isNetConn = true.obs;
  RxList billers = [].obs;
  RxList favBillers = [].obs;
  RxString payKey = "".obs;
  RxBool isLoading = true.obs;
  var fav = <int, bool>{}.obs;
  RxList filteredBillers = [].obs;

  //for sorting
  RxString selectedSortOption = "Biller Name".obs;
  RxBool isAscending = true.obs;
  var searchQuery = ''.obs;

  @override
  void onInit() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadFavoritesAndBillers();
    });

    super.onInit();
  }

  void clearFields() {
    billAccNo.clear();
    billerAccountName.clear();
    billNo.clear();
    amount.clear();
  }

  Future<void> loadFavoritesAndBillers() async {
    isLoading.value = true;
    await getFavorites();
  }

  Future<void> getBillers(Function cb) async {
    String subApi = "${ApiKeys.getBillers}";
    CustomDialogStack.showLoading(Get.context!);

    HttpRequestApi(api: subApi).get().then((response) async {
      Get.back();
      if (response == "No Internet") {
        cb(false);
        CustomDialogStack.showConnectionLost(Get.context!, () {
          Get.back();
        });
        return;
      }
      if (response == null) {
        cb(false);
        CustomDialogStack.showServerError(Get.context!, () {
          Get.back();
        });
        return;
      }
      billers.assignAll(response["items"]);
      filteredBillers.assignAll(billers);
      cb(true);
    });
  }

  void filterBillers(String query) {
    if (query.isEmpty) {
      filteredBillers.assignAll(billers);
    } else {
      filteredBillers.assignAll(
        billers.where((biller) {
          return biller['biller_name'].toLowerCase().contains(
            query.toLowerCase(),
          );
        }).toList(),
      );
    }
  }

  Future<void> sortFavorites() async {
    if (selectedSortOption.value == selectedSortOption.value) {
      isAscending.value = !isAscending.value;
    }
    if (selectedSortOption.value == 'Nickname') {
      favBillers.sort((a, b) {
        String nameA = a['account_name'] ?? '';
        String nameB = b['account_name'] ?? '';
        return isAscending.value
            ? nameA.compareTo(nameB)
            : nameB.compareTo(nameA);
      });
    } else if (selectedSortOption.value == "Biller Name") {
      favBillers.sort((a, b) {
        String nameA = a["biller_name"] ?? '';
        String nameB = b["biller_name"] ?? '';
        return isAscending.value
            ? nameA.compareTo(nameB)
            : nameB.compareTo(nameA);
      });
    } else if (selectedSortOption.value == "Biller Address") {
      favBillers.sort((a, b) {
        String addressA = a["biller_address"] ?? '';
        String addressB = b["biller_address"] ?? '';
        return isAscending.value
            ? addressA.compareTo(addressB)
            : addressB.compareTo(addressA);
      });
    }
    update();
  }

  Future<void> addFavorites(params, billId, accountNo, nickName) async {
    int userId = await Authentication().getUserId();
    bool isButtonEnabled = true;
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
        if (!isButtonEnabled) return;
        isButtonEnabled = false;
        CustomDialogStack.showLoading(Get.context!);
        var parameter = {
          "user_id": userId,
          "biller_id": billId,
          "account_no": accountNo,
          "account_name": nickName.toString(),
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
                    if (params["source"] == "fav") {
                      Functions.popPage(3);
                      getFavorites();
                    } else {
                      Get.back();
                      getFavorites();
                    }
                  },
                );
              } else {
                CustomDialogStack.showError(
                  Get.context!,
                  "luvpark",
                  returnPost["msg"],
                  () {
                    if (params["source"] == "fav") {
                      Functions.popPage(2);
                    } else {
                      Get.back();
                      getFavorites();
                    }
                  },
                );
              }
            })
            .whenComplete(() {
              Future.delayed(const Duration(seconds: 2), () {
                isButtonEnabled = true;
              });
            });
      },
    );
  }

  Future<void> onPay(args) async {
    FocusManager.instance.primaryFocus?.unfocus();

    CustomDialogStack.showLoading(Get.context!);
    final response = await Functions.generateQr();

    if (response["response"] == "Success") {
      double serviceFee =
          double.tryParse(args['service_fee'].toString()) ?? 0.0;
      double userAmount = double.tryParse(amount.text) ?? 0.0;
      double addedAmount = serviceFee + userAmount;
      String totalAmount = addedAmount.toStringAsFixed(2);
      int userId = await Authentication().getUserId();
      CustomDialogStack.showConfirmation(
        Get.context!,
        "Pay Bills",
        "Are you sure you want to continue?",
        leftText: "No",
        rightText: "Okay",
        () {
          Get.back();
        },
        () async {
          Get.back();
          var parameter = {
            "luvpay_id": userId.toString(),
            "biller_id": args["biller_id"].toString(),
            "bill_acct_no": billAccNo.text,
            "amount": totalAmount,
            "payment_hk": response["data"],
            "bill_no": billNo.text,
            "account_name": billerAccountName.text,
            'original_amount': amount.text,
          };

          CustomDialogStack.showLoading(Get.context!);

          HttpRequestApi(
            api: ApiKeys.postPayBills,
            parameters: parameter,
          ).postBody().then((returnPost) async {
            Get.back();
            if (returnPost == "No Internet") {
              isLoading.value = false;
              isNetConn.value = false;
              CustomDialogStack.showConnectionLost(Get.context!, () {
                Get.back();
              });
            } else if (returnPost == null) {
              isLoading.value = false;
              isNetConn.value = true;
              CustomDialogStack.showServerError(Get.context!, () {
                Get.back();
              });
            } else {
              if (returnPost["success"] == 'Y') {
                var params = {
                  "user_id": userId,
                  "biller_id": args["biller_id"].toString(),
                  "account_no": billAccNo.text,
                  "biller_name": args["biller_name"],
                  "biller_address": args["biller_address"],
                  'user_biller_id': args['user_biller_id'],
                  'amount': totalAmount.toString(),
                  "account_name": billerAccountName.text,
                  "service_fee": args['service_fee'].toString(),
                  "original_amount": amount.text,
                };
                Get.to(TicketUI(), arguments: params);
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
            isNetConn.value = true;
          });
        },
      );
    }
  }

  Future<void> getFavorites() async {
    final item = await Authentication().getUserData();
    String userId = jsonDecode(item!)['user_id'].toString();
    String subApi = "${ApiKeys.getFavBiller}?user_id=$userId";
    HttpRequestApi(api: subApi).get().then((response) async {
      if (response == "No Internet") {
        isLoading.value = false;
        isNetConn.value = false;
        return;
      }
      if (response == null) {
        isLoading.value = false;
        isNetConn.value = true;
        favBillers.value = [];
        CustomDialogStack.showServerError(Get.context!, () {
          Get.back();
        });
        return;
      }
      favBillers.value = response["items"];
      isNetConn.value = true;
      isLoading.value = false;
    });
  }

  Future<void> getTemplate(billerData) async {
    int billerId = int.parse(billerData["biller_id"].toString());
    CustomDialogStack.showLoading(Get.context!);
    HttpRequestApi(
      api: "${ApiKeys.getBillerTemp}?biller_id=$billerId",
    ).get().then((response) async {
      Get.back();
      if (response["items"].isNotEmpty) {
        List data = response["items"];
        List dataBiller = [];

        for (dynamic row in data) {
          dataBiller.add({
            "label": row["input_label"],
            "key": row["input_key"],
            "value": "",
            "maxLength": row["max_length"],
            "type": row["input_type"],
            "required": row["is_required"] == "Y" ? true : false,
            "is_validation": row["is_validation"],
            "is_for_posting": row["is_for_posting"],
            "is_amount": row["is_amount"],
            "input_formatter": row["input_formatter"],
          });
        }
        controllers2.clear();

        dynamic param = {"details": billerData, "field": dataBiller};

        Get.bottomSheet(ValidateAccount(billerData: param));
      }
    });
  }

  Future<void> generateQr() async {
    CustomDialogStack.showLoading(Get.context!);
    final response = await Functions.generateQr();

    Get.back();
    if (response["response"] == "No Internet") {
      isNetConn.value = false;
      return;
    }
    if (response["response"] == "Success") {
      isNetConn.value = true;
      payKey.value = response["data"];
      CustomDialogStack.showSuccess(
        Get.context!,
        "Success",
        "Qr successfully changed",
        leftText: "Done",
        () {
          Get.back();
        },
      );
      return;
    } else {
      isNetConn.value = true;
    }
  }

  void deleteFavoriteBiller(int billerId) async {
    final userId = await Authentication().getUserId();
    var params = {"user_id": userId, "u_biller_id": billerId};
    CustomDialogStack.showConfirmation(
      Get.context!,
      "Delete Biller",
      "Are you sure you want to delete this biller?",
      leftText: "No",
      rightText: "Yes",
      () {
        Get.back();
      },
      () {
        Get.back();
        CustomDialogStack.showLoading(Get.context!);
        HttpRequestApi(
          api: ApiKeys.deleteFavBiller,
          parameters: params,
        ).deleteData().then((retDelete) {
          Get.back();
          if (retDelete == "No Internet") {
            CustomDialogStack.showConnectionLost(Get.context!, () {
              Get.back();
            });
          } else if (retDelete["success"] == "Y") {
            CustomDialogStack.showSuccess(
              Get.context!,
              "Success",
              "Successfully deleted",
              leftText: "Okay",
              () {
                Get.back();
                loadFavoritesAndBillers();
              },
            );
          } else {
            CustomDialogStack.showServerError(Get.context!, () {
              Get.back();
            });
          }
        });
      },
    );
  }
}
