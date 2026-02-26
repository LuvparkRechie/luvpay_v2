import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:characters/characters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:flutter_native_contact_picker/model/contact.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
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
import '../scanner_screen.dart';

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

  RxString userName = "".obs;
  RxString userImage = "".obs;

  final FlutterNativeContactPicker contactPicker = FlutterNativeContactPicker();
  Rx<Contact?> contact = Rx<Contact?>(null);

  RxBool isValidUser = true.obs;

  RxInt denoInd = 0.obs;
  RxInt indexbtn = 0.obs;

  RxList padData = [].obs;

  final recentRecipients = <Map<String, dynamic>>[].obs;

  final GetStorage _box = GetStorage();
  String _recentKey = "wallet_send_recent_0";

  static const int _maxRecent = 5;

  bool _loadingShown = false;

  void _showLoadingOnce() {
    if (_loadingShown) return;
    _loadingShown = true;
    CustomDialogStack.showLoading(Get.context!);
  }

  void _closeLoadingOnly() {
    if (!_loadingShown) return;
    _loadingShown = false;

    final ctx = Get.overlayContext ?? Get.context;
    if (ctx == null) return;

    final nav = Navigator.of(ctx, rootNavigator: true);
    if (nav.canPop()) {
      nav.pop();
    }
  }

  void _closeDialogIfOpen() {
    if (Get.isDialogOpen == true) {
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
    padData.value = dataList;
    _initAsync();
  }

  Future<void> _initAsync() async {
    try {
      final userId = await Authentication().getUserId();
      _recentKey = "wallet_send_recent_$userId";
    } catch (_) {
      _recentKey = "wallet_send_recent_0";
    }

    await _loadRecents();
    await refreshUserData();
  }

  @override
  void onClose() {
    _closeLoadingOnly();
    tokenAmount.dispose();
    message.dispose();
    if (formKeySend.currentState != null) {
      formKeySend.currentState!.reset();
    }
    super.onClose();
  }

  Future<void> _loadRecents() async {
    final raw = _box.read(_recentKey);
    if (raw is List) {
      final parsed =
          raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      recentRecipients.assignAll(parsed);
      _trimRecents();
    } else {
      recentRecipients.clear();
    }
  }

  Future<void> _saveRecents() async {
    await _box.write(_recentKey, recentRecipients.toList());
  }

  void _trimRecents() {
    if (recentRecipients.length > _maxRecent) {
      recentRecipients.removeRange(_maxRecent, recentRecipients.length);
    }
  }

  String? normalizeMobile(String input) {
    var s = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (s.isEmpty) return null;

    if (s.length == 12 && s.startsWith('63')) return s;
    if (s.length == 11 && s.startsWith('09')) return '63${s.substring(1)}';
    if (s.length == 10 && s.startsWith('9')) return '63$s';

    if (s.length >= 10) {
      final last10 = s.substring(s.length - 10);
      if (last10.startsWith('9')) return '63$last10';
    }

    return null;
  }

  Future<void> addRecentFromCurrentRecipient() async {
    if (recipientData.isEmpty) return;
    if (recipientData[0]["mobile_no"] == null) return;

    final mobile = recipientData[0]["mobile_no"].toString();
    final name = userName.value.toString();

    final item = <String, dynamic>{"mobile_no": mobile, "name": name};

    recentRecipients.removeWhere((e) => e["mobile_no"].toString() == mobile);
    recentRecipients.insert(0, item);

    _trimRecents();
    await _saveRecents();
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
        _closeLoadingOnly();
        CustomDialogStack.showConnectionLost(Get.context!, () {
          refreshUserData();
          Get.back();
        });
        return;
      }

      if (returnData == null) {
        _closeLoadingOnly();
        CustomDialogStack.showServerError(Get.context!, () => Get.back());
        return;
      }

      if (returnData["is_valid"] == "Y") {
        _closeLoadingOnly();
        final data = await Authentication().getEncryptedKeys();
        await _requestOtpAndOpenOtpScreen(pwd: data["pwd"]);
        return;
      }

      _closeLoadingOnly();
      CustomDialogStack.showError(
        Get.context!,
        "luvpay",
        returnData["items"][0]["msg"],
        () => Get.back(),
      );
    } catch (_) {
      _closeLoadingOnly();
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
      _closeLoadingOnly();
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
        _closeLoadingOnly();
        CustomDialogStack.showServerError(Get.context!, () => Get.back());
        if (!completer.isCompleted) completer.complete();
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

        _closeLoadingOnly();

        await Get.to(
          OtpFieldScreen(arguments: args),
          transition: Transition.rightToLeftWithFade,
          duration: const Duration(milliseconds: 400),
        );

        _closeLoadingOnly();

        if (!completer.isCompleted) completer.complete();
        return;
      }

      _closeLoadingOnly();
      CustomDialogStack.showError(
        Get.context!,
        "luvpay",
        objData["msg"]?.toString() ?? "Unable to request OTP.",
        () => Get.back(),
      );
      if (!completer.isCompleted) completer.complete();
    });

    await completer.future;
    _closeLoadingOnly();
  }

  Future<void> refreshUserData() async {
    isLoading.value = true;
    final userId = await Authentication().getUserId();
    String subApi = "${ApiKeys.getUserBalance}$userId";

    HttpRequestApi(api: subApi).get().then((returnBalance) async {
      if (returnBalance == "No Internet" || returnBalance == null) {
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
    final userId = await Authentication().getUserId();

    _showLoadingOnce();

    Map<String, dynamic> parameters = {
      "user_id": userId.toString(),
      "to_mobile_no": recipientData[0]["mobile_no"],
      "amount": tokenAmount.text,
      "to_msg": message.text,
      "session_id": uData["session_id"].toString(),
      "pwd": pwd,
    };

    dynamic retvalue;
    try {
      retvalue =
          await HttpRequestApi(
            api: ApiKeys.postShareToken,
            parameters: parameters,
          ).postBody();
    } catch (_) {
      retvalue = null;
    }

    if (retvalue == "No Internet") {
      _closeLoadingOnly();
      CustomDialogStack.showError(
        Get.context!,
        "Error",
        "Please check your internet connection and try again.",
        () => Get.back(),
      );
      return;
    }

    if (retvalue == null) {
      _closeLoadingOnly();
      CustomDialogStack.showError(
        Get.context!,
        "Error",
        "Error while connecting to server, Please try again.",
        () {
          if (Navigator.canPop(Get.context!)) Get.back();
        },
      );
      return;
    }

    if (retvalue["success"] == "Y") {
      await addRecentFromCurrentRecipient();

      NotificationController.shareTokenNotification(
        0,
        0,
        'Transfer Token',
        "${retvalue["msg"]}.",
        "walletScreen",
      );

      _closeLoadingOnly();

      CustomDialogStack.showSuccess(
        Get.context!,
        "Success!",
        "Transaction is complete",
        leftText: "Okay",
        () {
          Get.back();
          Get.back();
          refreshUserData();
        },
      );
      return;
    }

    _closeLoadingOnly();
    CustomDialogStack.showError(
      Get.context!,
      "luvpay",
      retvalue["msg"],
      () => Get.back(),
    );
  }

  Future<void> getRecipient(String mobileNo, {String? isFromQR}) async {
    final normalized =
        normalizeMobile(mobileNo) ?? mobileNo.toString().replaceAll(" ", "");
    if (normalized.isEmpty) return;

    isRecipientLookupLoading.value = true;
    isValidUser.value = true;
    userName.value = "";
    userImage.value = "";
    recipientData.clear();

    final api = "${ApiKeys.getRecipient}?mobile_no=$normalized";

    dynamic objData;
    try {
      objData = await HttpRequestApi(api: api).get();
    } catch (_) {
      objData = null;
    } finally {
      isRecipientLookupLoading.value = false;
    }

    if (objData == "No Internet" ||
        objData == null ||
        objData["user_id"] == 0) {
      isValidUser.value = false;
      userName.value = "Unknown user";
      recipientData.value = [
        {"email": "No email provided yet", "mobile_no": normalized},
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
  }
}
