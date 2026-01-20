// ignore_for_file: avoid_print, unnecessary_string_interpolations

import 'dart:typed_data';

import 'package:get/get.dart';
import 'package:luvpay/custom_widgets/longprint.dart';
import '../../auth/authentication.dart';
import '../../custom_widgets/alert_dialog.dart';
import '../../custom_widgets/app_color_v2.dart';
import '../../functions/functions.dart';
import '../../http/api_keys.dart';
import '../../http/http_request.dart';
import 'view.dart';

class SubWalletController extends GetxController
    with GetSingleTickerProviderStateMixin {
  RxList userData = [].obs;
  RxDouble numericBalance = 0.0.obs;
  RxString luvpayBal = '0.00'.obs;
  RxList<Map<String, dynamic>> categoryList = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> userSubWallets = <Map<String, dynamic>>[].obs;
  final Map<String, Uint8List> iconCache = {};
  RxBool isLoading = false.obs;
  RxBool hasNet = true.obs;
  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString().replaceAll(',', '')) ?? 0.0;
  }

  @override
  void onInit() {
    super.onInit();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await luvpayBalance();
    await getSubWalletCategories();
    await getUserSubWallets();
  }

  Future<void> refreshAllData() async {
    try {
      isLoading.value = true;
      await Future.wait([
        luvpayBalance(),
        getSubWalletCategories(),
        getUserSubWallets(),
      ]);
    } catch (e) {
      print('Error refreshing data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getUserSubWallets() async {
    try {
      isLoading.value = true;
      final userID = await Authentication().getUserId();
      String subApi = "${ApiKeys.subWallets}?user_id=$userID";
      final returnData = await HttpRequestApi(api: subApi).get();
      if (returnData == "No Internet") {
        hasNet.value = false;
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

      userSubWallets.clear();

      if (returnData.containsKey("items") && returnData["items"] is List) {
        List<dynamic> items = returnData["items"];

        for (var item in items) {
          double amount = 0.0;
          if (item['sub_wallet_amt'] != null) {
            try {
              amount = double.parse(item['sub_wallet_amt'].toString());
            } catch (e) {
              amount = 0.0;
            }
          }

          userSubWallets.add({
            'id': item['user_sub_wallet_id']?.toString() ?? '',
            'user_id': item['user_id']?.toString() ?? '',
            'category_id': item['category_id']?.toString() ?? '',
            'name': item['sub_wallet_name']?.toString() ?? 'Unnamed Wallet',
            'amount': amount,
            'created_on': item['created_on']?.toString() ?? '',
            'updated_on': item['updated_on']?.toString() ?? '',
            'is_active': item['is_active']?.toString() ?? 'N',
            'category_title': item['category_title']?.toString() ?? 'Unknown',
            'image_base64': item['image_base64']?.toString() ?? '',
          });
        }
        userSubWallets.sort((a, b) {
          final aDate =
              DateTime.tryParse(a['created_on'] ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0);

          final bDate =
              DateTime.tryParse(b['created_on'] ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0);

          return bDate.compareTo(aDate);
        });
      }

      hasNet.value = true;

      update();
    } catch (e) {
      print('Error fetching user subwallets: $e');
      if (Get.context != null) {
        CustomDialogStack.showError(
          Get.context!,
          "Error",
          "Failed to load subwallets",
          Get.back,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>> postSubWallet({
    int? categoryId,
    String? subWalletName,
    double? amount,
  }) async {
    try {
      final userID = await Authentication().getUserId();

      Map<String, dynamic> postParam = {
        "user_id": userID,
        "category_id": categoryId,
        "sub_wallet_name": subWalletName,
        "amount": amount,
      };

      String api = ApiKeys.subWallets;

      isLoading.value = true;

      final retValue =
          await HttpRequestApi(api: api, parameters: postParam).postBody();
      if (retValue == "No Internet") {
        return {"success": false, "error": "No Internet"};
      }

      if (retValue == null) {
        return {"success": false, "error": "Server error"};
      }

      if (retValue['success'] == "Y") {
        return {"success": true, "message": retValue["msg"]};
      } else {
        return {"success": false, "error": retValue["msg"]};
      }
    } catch (e) {
      print(e);
      return {
        "success": false,
        "error": "An error occurred while creating wallet",
      };
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>> editSubwallet({
    int? subwalletId,
    String? subWalletName,
  }) async {
    try {
      final parameters = <String, dynamic>{
        "user_sub_wallet_id": subwalletId,
        "sub_wallet_name": subWalletName,
      };
      String api = ApiKeys.subWallets;
      final res =
          await HttpRequestApi(api: api, parameters: parameters).putBody();

      if (res == "No Internet") {
        CustomDialogStack.showConnectionLost(Get.context!, () {
          Get.back();
        });
      }

      if (res == null) {
        CustomDialogStack.showServerError(Get.context!, () {
          Get.back();
        });
      }

      if (res["success"] == "Y") {
        return {"success": true, "message": res["msg"]};
      } else {
        return {"success": false, "error": res["msg"]};
      }
    } catch (e) {
      print('Error editing subwallet: $e');
      return {
        "success": false,
        "error": "An error occurred while editing wallet",
      };
    }
  }

  Future<Map<String, dynamic>> transferSubWallet({
    int? subwalletId,
    double? amount,
    required String wttarget,
    String? subWalletName,
    int? categoryId,
  }) async {
    try {
      final userID = await Authentication().getUserId();

      final params = <String, dynamic>{
        "user_sub_wallet_id": subwalletId,
        "user_id": userID,
        "wt_target": wttarget,
      };

      if (amount != null && (wttarget == "SUB" || wttarget == "MAIN")) {
        params["amount"] = amount;
      }
      if (subWalletName != null && wttarget == "UPDATE") {
        params["sub_wallet_name"] = subWalletName;
      }
      if (categoryId != null && wttarget == "UPDATE") {
        params["category_id"] = categoryId;
      }

      isLoading.value = true;

      final res =
          await HttpRequestApi(
            api: ApiKeys.subwalletTransfer,
            parameters: params,
          ).postBody();

      if (res == "No Internet") {
        hasNet.value = false;
        return {
          "success": false,
          "code": "NO_INTERNET",
          "error": "No Internet",
        };
      }

      if (res == null || res is! Map) {
        return {
          "success": false,
          "code": "SERVER_ERROR",
          "error": "Server error",
        };
      }

      final ok = (res["success"]?.toString() ?? "N") == "Y";
      final msg = res["msg"]?.toString() ?? "";

      if (!ok) {
        return {
          "success": false,
          "code": "FAILED",
          "error": msg.isNotEmpty ? msg : "Failed",
        };
      }

      await Future.wait([getUserSubWallets(), luvpayBalance()]);

      update();

      return {
        "success": true,
        "code": "SUCCESS",
        "message": msg.isNotEmpty ? msg : "Success",
      };
    } catch (e) {
      print("transferSubWallet error: $e");
      return {
        "success": false,
        "code": "EXCEPTION",
        "error": "Something went wrong",
      };
    } finally {
      isLoading.value = false;
    }
  }

  Map<String, dynamic>? getSubWalletById(String id) {
    try {
      return userSubWallets.firstWhere((wallet) => wallet['id'] == id);
    } catch (e) {
      return null;
    }
  }

  List<Map<String, dynamic>> getSubWalletsByCategory(String categoryId) {
    return userSubWallets
        .where((wallet) => wallet['category_id'] == categoryId)
        .toList();
  }

  double getTotalSubWalletAmount() {
    double total = 0.0;
    for (var wallet in userSubWallets) {
      total += wallet['amount'] ?? 0.0;
    }
    return total;
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
          'category_id': item['category_id'] ?? 0,
          'category_title': item['category_title'] ?? 'Unknown',
          'image_base64': item['image_base64'] ?? '',
          'color': item['color'] ?? AppColorV2.lpBlueBrand,
        });
      }

      categoryList.value = processedCategories;

      update();
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
      numericBalance.value = _toDouble(luvpayBal.value);

      update();
    } catch (e) {
      print('Error fetching LuvPay balance: $e');
    }
  }

  Map<String, dynamic>? getCategoryById(String categoryId) {
    try {
      return categoryList.firstWhere(
        (cat) => cat['category_id']?.toString() == categoryId,
      );
    } catch (e) {
      return null;
    }
  }

  Map<String, dynamic>? getCategoryByName(String categoryName) {
    try {
      return categoryList.firstWhere(
        (cat) =>
            (cat['category_title']?.toString() ?? '').toLowerCase() ==
            categoryName.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> deleteSubWallet(String id) async {
    final ctx = Get.context;
    if (ctx == null) {
      return {"success": false, "error": "No context"};
    }

    CustomDialogStack.showLoading(ctx);

    try {
      String subApi = ApiKeys.subWallets;
      var params = {"user_sub_wallet_id": int.tryParse(id)};

      isLoading.value = true;

      final response =
          await HttpRequestApi(api: subApi, parameters: params).deleteData();

      if (Get.isDialogOpen == true) Get.back();

      if (response == "No Internet") {
        CustomDialogStack.showConnectionLost(Get.context!, () {
          Get.back();
        });
        return {"success": false, "error": "No Internet"};
      }

      if (response == null) {
        return {"success": false, "error": "Server error"};
      }

      if (response["success"] == "Y") {
        final deletedWallet = getSubWalletById(id);

        userSubWallets.removeWhere((wallet) => wallet['id'] == id);

        if (deletedWallet != null) {
          final walletAmount = deletedWallet['amount'] ?? 0.0;
          if (walletAmount > 0) {
            await luvpayBalance();
          }
        }

        update();

        return {
          "success": true,
          "message": response["msg"] ?? "Wallet deleted successfully",
        };
      }

      return {
        "success": false,
        "error": response["msg"] ?? "Failed to delete wallet",
      };
    } catch (e) {
      if (Get.isDialogOpen == true) Get.back();

      print('Error deleting subwallet: $e');
      return {
        "success": false,
        "error": "An error occurred while deleting wallet",
      };
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<Transaction>> fetchWalletTransactions({
    required int subWalletId,
  }) async {
    try {
      isLoading.value = true;

      final api =
          "${ApiKeys.subwalletTransfer}?user_sub_wallet_id=$subWalletId";
      final res = await HttpRequestApi(api: api).get();

      if (res == "No Internet") {
        hasNet.value = false;
        return <Transaction>[];
      }

      if (res == null || res is! Map) {
        return <Transaction>[];
      }

      final items = (res["items"] as List?) ?? [];

      return items.map((e) {
        final map = Map<String, dynamic>.from(e as Map);

        final rawAmount = _toDouble(map["amount"]);
        final isIncome = rawAmount > 0;

        final desc =
            (map["transfer_desc"]?.toString().trim().isNotEmpty ?? false)
                ? map["transfer_desc"].toString()
                : "Wallet Transfer";

        return Transaction(
          id: map["wallet_transfer_id"]?.toString() ?? '',
          description: desc,
          amount: rawAmount,
          date:
              DateTime.tryParse(map["transfer_date"]?.toString() ?? '') ??
              DateTime.now(),
          isIncome: isIncome,
          raw: map,
        );
      }).toList();
    } catch (e) {
      return <Transaction>[];
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    userData.clear();
    categoryList.clear();
    userSubWallets.clear();
    luvpayBal.value = '0.0';
    numericBalance.value = 0.0;
    super.onClose();
  }
}
