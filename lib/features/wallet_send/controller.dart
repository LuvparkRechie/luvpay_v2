import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:flutter_native_contact_picker/model/contact.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:luvpay/features/scanner_screen.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../auth/authentication.dart';
import '../../core/network/http/api_keys.dart';
import '../../core/network/http/http_request.dart';
import '../../core/security/agent_x.dart';
import '../../core/services/notification_controller.dart';
import '../../core/utils/functions/functions.dart';
import '../../shared/components/otp_field/view.dart';
import '../../shared/dialogs/dialogs.dart';
import '../../shared/widgets/variables.dart';
import 'view.dart';

class WalletSendController extends GetxController {
  WalletSendController();

  final isRecipientLookupLoading = false.obs;

  final GlobalKey<FormState> formKeySend = GlobalKey<FormState>();
  final TextEditingController tokenAmount = TextEditingController();
  final TextEditingController message = TextEditingController();

  final GlobalKey contentKey = GlobalKey();

  RxBool isLpAccount = false.obs;
  RxBool isLoading = true.obs;

  PermissionStatus cameraStatus = PermissionStatus.denied;

  RxBool isNetConn = true.obs;
  RxList userData = [].obs;
  RxList recipientData = [].obs;

  String mobileNumber = '';

  RxString userName = "".obs;
  RxString userImage = "".obs;

  final FlutterNativeContactPicker contactPicker = FlutterNativeContactPicker();
  Rx<Contact?> contact = Rx<Contact?>(null);

  RxBool isValidUser = true.obs;

  RxInt denoInd = 0.obs;
  RxInt indexbtn = 0.obs;

  RxList padData = [].obs;
  bool _loadingShown = false;

  void _showLoadingOnce() {
    if (_loadingShown) return;
    _loadingShown = true;

    CustomDialogStack.showLoading(Get.context!);
  }

  void _closeLoadingSafe() {
    if (!_loadingShown) return;
    _loadingShown = false;

    if (Get.key.currentState?.canPop() ?? false) {
      Get.back();
    }
  }

  final List dataList =
      [
        {"value": 20, "is_active": false},
        {"value": 30, "is_active": false},
        {"value": 50, "is_active": false},
        {"value": 100, "is_active": false},
        {"value": 200, "is_active": false},
        {"value": 250, "is_active": false},
        {"value": 300, "is_active": false},
        {"value": 500, "is_active": false},
        {"value": 1000, "is_active": false},
      ].obs;

  @override
  void onInit() {
    super.onInit();
    refreshUserData();
    padData.value = dataList;
  }

  @override
  void onClose() {
    tokenAmount.dispose();
    message.dispose();
    if (formKeySend.currentState != null) {
      formKeySend.currentState!.reset();
    }
    super.onClose();
  }

  Future<void> showBottomSheet() async {
    if (Get.isBottomSheetOpen == true) return;

    Get.bottomSheet(
      UsersBottomsheet(index: 1, cb: (index) => Functions.popPage(index)),
      enableDrag: false,
      isDismissible: false,
    );
  }

  bool isBase64(String s) {
    try {
      String normalized = Base64Codec().normalize(s);
      base64Decode(normalized);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> requestCameraPermission() async {
    Get.to(
      ScannerScreenV2(
        onchanged: (args) async {
          String raw = args.toString().trim();

          String? normalize(String input) {
            var s = input.replaceAll(RegExp(r'[^0-9]'), '');
            if (s.isEmpty) return null;

            if (s.length == 12 && s.startsWith('63')) return s;
            if (s.length == 11 && s.startsWith('09')) {
              return '63${s.substring(1)}';
            }
            if (s.length == 10 && s.startsWith('9')) return '63$s';

            return null;
          }

          void invalid([String? msg]) {
            CustomDialogStack.showError(
              Get.context!,
              "Invalid QR Code",
              msg ?? "The scanned QR code is invalid. Please try again.",
              () => Get.back(),
            );
          }

          final direct = normalize(raw);
          if (direct != null) {
            if (Get.key.currentState?.canPop() ?? false) {
              await getRecipient(direct);
            }
            return;
          }

          if (!isBase64(raw)) {
            invalid();
            return;
          }

          dynamic jsonData;
          try {
            final decrypted = AgentX_().decryptAES256CBC(raw);
            jsonData = jsonDecode(decrypted);
          } catch (_) {
            invalid("Unable to read QR code.");
            return;
          }

          if (jsonData is! Map || !jsonData.containsKey('mobile_no')) {
            invalid();
            return;
          }

          final normalizedMobile = normalize(jsonData["mobile_no"].toString());
          if (normalizedMobile == null) {
            invalid("Invalid mobile number.");
            return;
          }

          if (Get.key.currentState?.canPop() ?? false) Get.back();
          await getRecipient(normalizedMobile);
        },
      ),
    );
  }

  Future<void> proceedToOtp() async {
    if (recipientData.isEmpty || recipientData[0]["mobile_no"] == null) {
      CustomDialogStack.showError(
        Get.context!,
        "Error",
        "Recipient data is not available.",
        () => Get.back(),
      );
      return;
    }

    await getVerifiedAcc();
  }

  Future<void> getVerifiedAcc() async {
    _showLoadingOnce();

    try {
      final params =
          "${ApiKeys.verifyUserAccount}?mobile_no=${recipientData[0]["mobile_no"]}";

      final returnData = await HttpRequestApi(api: params).get();

      if (returnData == "No Internet") {
        _closeLoadingSafe();
        CustomDialogStack.showConnectionLost(Get.context!, () {
          refreshUserData();
          Get.back();
        });
        return;
      }

      if (returnData == null) {
        _closeLoadingSafe();
        CustomDialogStack.showServerError(Get.context!, () => Get.back());
        return;
      }

      if (returnData["is_valid"] == "Y") {
        _closeLoadingSafe();

        final data = await Authentication().getEncryptedKeys();
        await _requestOtpAndOpenOtpScreen(pwd: data["pwd"]);
        return;
      }

      _closeLoadingSafe();
      CustomDialogStack.showError(
        Get.context!,
        "luvpay",
        returnData["items"][0]["msg"],
        () => Get.back(),
      );
    } catch (_) {
      _closeLoadingSafe();
      CustomDialogStack.showError(
        Get.context!,
        "Error",
        "Something went wrong. Please try again.",
        () => Get.back(),
      );
    }
  }

  Future<void> _requestOtpAndOpenOtpScreen({required String pwd}) async {
    final uData = await Authentication().getUserData2();

    final requestParam = <String, String>{
      "mobile_no": uData["mobile_no"].toString(),
      "pwd": pwd,
    };

    DateTime timeNow;
    try {
      timeNow = await Functions.getTimeNow();
    } catch (_) {
      CustomDialogStack.showError(
        Get.context!,
        "Error",
        "Unable to get server time. Please try again.",
        () => Get.back(),
      );
      return;
    }

    final completer = Completer<void>();

    Functions().requestOtp(requestParam, (objData) async {
      if (objData == null) {
        CustomDialogStack.showServerError(Get.context!, () => Get.back());
        completer.complete();
        return;
      }

      if (objData["success"] == "Y" || objData["status"] == "PENDING") {
        final timeExp = DateFormat(
          "yyyy-MM-dd hh:mm:ss a",
        ).parse(objData["otp_exp_dt"].toString());

        final otpExpiry = DateTime(
          timeExp.year,
          timeExp.month,
          timeExp.day,
          timeExp.hour,
          timeExp.minute,
          timeExp.second,
        );

        final difference = otpExpiry.difference(timeNow);

        final putParam = <String, String>{
          "mobile_no": uData["mobile_no"].toString(),
          "otp": objData["otp"].toString(),
          "req_type": "SR",
        };

        final args = {
          "time_duration": difference,
          "mobile_no": uData["mobile_no"].toString(),
          "req_otp_param": requestParam,
          "verify_param": putParam,
          "callback": (otp) async {
            if (otp != null) {
              await shareToken(pwd: pwd);
            }
          },
        };

        await Get.to(
          OtpFieldScreen(arguments: args),
          transition: Transition.rightToLeftWithFade,
          duration: const Duration(milliseconds: 400),
        );

        completer.complete();
        return;
      }

      CustomDialogStack.showError(
        Get.context!,
        "luvpay",
        objData["msg"]?.toString() ?? "Unable to request OTP.",
        () => Get.back(),
      );
      completer.complete();
    });

    await completer.future;
  }

  void _closeDialogIfOpen() {
    if (Get.isDialogOpen == true) {
      Get.back();
    }
  }

  Future<void> pads(String value) async {
    double textValue = double.parse(value.toString());
    tokenAmount.text = textValue.toString();
    padData.value =
        dataList.map((obj) {
          obj["is_active"] = (obj["value"] == value);
          return obj;
        }).toList();
  }

  Future<void> refreshUserData() async {
    isLoading.value = true;
    final userId = await Authentication().getUserId();
    String subApi = "${ApiKeys.getUserBalance}$userId";

    HttpRequestApi(api: subApi).get().then((returnBalance) async {
      if (returnBalance == "No Internet") {
        isLoading.value = false;
        isNetConn.value = false;
        return;
      }
      if (returnBalance == null) {
        isLoading.value = false;
        isNetConn.value = false;
        return;
      }
      isLoading.value = false;
      isNetConn.value = true;
      if (returnBalance["items"].isNotEmpty) {
        userData.value = returnBalance["items"];
      }
    });
  }

  Future<void> shareToken({required String pwd}) async {
    final uData = await Authentication().getUserData2();
    int userId = await Authentication().getUserId();

    CustomDialogStack.showLoading(Get.context!);
    Map<String, dynamic> parameters = {
      "user_id": userId.toString(),
      "to_mobile_no": recipientData[0]["mobile_no"],
      "amount": tokenAmount.text,
      "to_msg": message.text,
      "session_id": uData["session_id"].toString(),
      "pwd": pwd,
    };

    HttpRequestApi(
      api: ApiKeys.postShareToken,
      parameters: parameters,
    ).postBody().then((retvalue) {
      if (retvalue == "No Internet") {
        Get.back();
        CustomDialogStack.showError(
          Get.context!,
          "Error",
          "Please check your internet connection and try again.",
          () => Get.back(),
        );
        return;
      }

      if (retvalue == null) {
        Get.back();
        CustomDialogStack.showError(
          Get.context!,
          "Error",
          "Error while connecting to server, Please try again.",
          () {
            if (Navigator.canPop(Get.context!)) {
              Get.back();
            }
          },
        );
        return;
      }

      if (retvalue["success"] == "Y") {
        NotificationController.shareTokenNotification(
          0,
          0,
          'Transfer Token',
          "${retvalue["msg"]}.",
          "walletScreen",
        );

        Get.back();

        CustomDialogStack.showSuccess(
          Get.context!,
          "Success!",
          "Transaction is complete",
          leftText: "Okay",
          () {
            Get.back();
            Get.back();
            refreshUserData();

            Future.delayed(const Duration(milliseconds: 500), () {
              if (Get.key.currentState?.canPop() ?? false) Get.back();
            });
          },
        );
        return;
      }

      Get.back();
      CustomDialogStack.showError(
        Get.context!,
        "luvpay",
        retvalue["msg"],
        () => Get.back(),
      );
    });
  }

  Future<void> getRecipient(String mobileNo, {String? proceed}) async {
    final cleaned = mobileNo.toString().replaceAll(" ", "");
    if (cleaned.isEmpty) return;

    isRecipientLookupLoading.value = true;
    isValidUser.value = true;
    userName.value = "";
    userImage.value = "";
    recipientData.clear();

    final api = "${ApiKeys.getRecipient}?mobile_no=$cleaned";

    dynamic objData;
    try {
      objData = await HttpRequestApi(api: api).get();
    } catch (_) {
      objData = null;
    } finally {
      isRecipientLookupLoading.value = false;
    }

    if (objData == "No Internet" || objData == null) {
      isValidUser.value = false;
      userName.value = "Unknown user";
      recipientData.value = [
        {"email": "No email provided yet", "mobile_no": cleaned},
      ];
      return;
    }

    if (objData["user_id"] == 0) {
      isValidUser.value = false;
      userName.value = "Unknown user";
      recipientData.value = [
        {"email": "No email provided yet", "mobile_no": cleaned},
      ];
      return;
    }

    isValidUser.value = true;
    recipientData.value = [objData];

    final fname = (objData["first_name"] ?? "").toString();
    userImage.value = (objData["image_base64"] ?? "").toString();

    if (fname.isNotEmpty) {
      final transformedF = Variables.transformFullName(
        fname.replaceAll(RegExp(r'\..*'), ''),
      );
      final transformedL = Variables.transformFullName(
        (objData["last_name"] ?? "").toString().replaceAll(RegExp(r'\..*'), ''),
      );
      final middle = (objData["middle_name"] ?? "").toString();
      final middleInitial = middle.isNotEmpty ? middle[0] : "";

      userName.value =
          '$transformedF ${middleInitial.isNotEmpty ? "$middleInitial. " : ""}$transformedL';
    } else {
      userName.value = "Unverified User";
    }

    if (proceed == "false") {
      if (Get.key.currentState?.canPop() ?? false) Get.back();
    }
  }
}
