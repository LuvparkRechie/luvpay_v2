// ignore_for_file: unused_import, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

import 'package:flutter/material.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:get/get.dart';
import 'package:luvpay/core/network/http/http_request.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/authentication.dart';
import 'package:luvpay/shared/dialogs/dialogs.dart';
import '../../shared/widgets/luvpay_text.dart';
import '../../shared/widgets/spacing.dart';
import '../../core/network/http/api_keys.dart';

class QRController extends GetxController
    with GetSingleTickerProviderStateMixin {
  QRController();

  static const int delayInMinutes = 1;

  RxString firstlastCapital = ''.obs;
  RxString fullName = "".obs;
  late final TextEditingController imageSizeEditingController;
  RxBool isAgree = false.obs;
  RxBool isButtonDisabled = false.obs;
  RxBool isInternetConn = true.obs;
  RxBool isLoading = true.obs;
  RxString mobNum = "".obs;
  RxString mono = ''.obs;
  final parameter = Get.arguments;
  RxString payKey = "".obs;
  RxInt remainingTime = 0.obs;
  final ScreenshotController screenshotController = ScreenshotController();
  RxBool showTimerMsg = false.obs;
  RxString userImage = "".obs;

  //regen qr
  Timer? _timer;

  @override
  void onClose() {
    //regen qr _timer?.cancel();
    _timer?.cancel();
    super.onClose();
  }

  @override
  void onInit() {
    super.onInit();
    remainingTime.value = 0;
    isButtonDisabled.value = false;
    getQrData();
    _loadLastGeneratedTime();
  }

  Future<void> getQrData() async {
    String image = await Authentication().getUserProfilePic();
    userImage.value = image;
    isLoading.value = true;
    isInternetConn.value = true;
    var userData = await Authentication().getUserData2();
    if (userData["first_name"] != null) {
      String middleName =
          userData['middle_name']?.toString().toUpperCase() ?? "";
      fullName.value =
          "${userData['first_name']} $middleName ${userData['last_name']}";
      firstlastCapital.value =
          "${userData['first_name'][0]} ${userData['last_name'][0]}";
    } else {
      fullName.value = "Not specified";
    }
    mono.value =
        "+639${userData['mobile_no'].substring(3).replaceAll(RegExp(r'.(?=.{4})'), '·')}";
    mobNum.value = userData['mobile_no'];
    isLoading.value = true;

    HttpRequestApi(
      api: "${ApiKeys.getPaymentKey}${userData["user_id"]}",
    ).get().then((paymentKey) {
      if (paymentKey == "No Internet") {
        isInternetConn.value = false;
        isLoading.value = false;
        CustomDialogStack.showConnectionLost(Get.context!, () {
          Get.back();
        });
        return;
      }
      if (paymentKey == null) {
        isInternetConn.value = true;
        isLoading.value = true;
        CustomDialogStack.showServerError(Get.context!, () {
          Get.back();
        });
        return;
      } else {
        isInternetConn.value = true;
        isLoading.value = false;
        payKey.value = paymentKey["items"][0]["payment_hk"];
      }
    });
  }

  Future<void> generateQr() async {
    if (remainingTime.value > 0) {
      isButtonDisabled.value = true;
      showTimerMsg.value = true;
      return;
    }
    isButtonDisabled.value = true;
    CustomDialogStack.showLoading(Get.context!);
    int userId = await Authentication().getUserId();

    HttpRequestApi(api: "${ApiKeys.getPaymentKey}$userId").put2().then((
      objKey,
    ) {
      if (objKey == "No Internet") {
        isInternetConn.value = false;
        isLoading.value = false;
        CustomDialogStack.showConnectionLost(Get.context!, () {
          isLoading.value = false;
          Get.back();
          Get.back();
        });
        return;
      }
      if (objKey == null) {
        isInternetConn.value = true;
        isLoading.value = true;
        CustomDialogStack.showServerError(Get.context!, () {
          Get.back();
        });
        return;
      } else {
        isInternetConn.value = true;
        isLoading.value = false;
        if (objKey["success"] == 'Y') {
          payKey.value = objKey["payment_hk"];
          SharedPreferences.getInstance().then((prefs) {
            prefs.setInt(
              'lastGeneratedTime',
              DateTime.now().millisecondsSinceEpoch,
            );
          });
          remainingTime.value = delayInMinutes * 60 * 1000;
          _startTimer();
          showTimerMsg.value = true;
          CustomDialogStack.showSuccess(
            Get.context!,
            "Success!",
            "QR Code successfully generated",
            () {
              Get.back();
              Get.back();
            },
          );
        } else {
          CustomDialogStack.showError(
            Get.context!,
            "luvpay",
            objKey['msg'],
            () {},
          );
        }
      }
      isButtonDisabled.value = false;
    });
  }

  Future<void> saveQr(String? myQR) async {
    CustomDialogStack.showLoading(Get.context!);
    String randomNumber = Random().nextInt(100000).toString();
    String fname = "luvpay$randomNumber.png";
    ScreenshotController()
        .captureFromWidget(myWidget(myQR), delay: const Duration(seconds: 2))
        .then((image) async {
          final dir = await getApplicationDocumentsDirectory();
          final imagePath = await File('${dir.path}/$fname').create();
          await imagePath.writeAsBytes(image);
          GallerySaver.saveImage(imagePath.path).then((result) {
            CustomDialogStack.showSuccess(
              Get.context!,
              "Success",
              "QR code has been saved. Please check your gallery.",
              () {
                Get.back();
                Get.back();
              },
            );
          });
        });
  }

  Future<void> shareQr(String? myQR) async {
    try {
      String randomNumber = Random().nextInt(100000).toString();
      String fname = "shared_luvpay$randomNumber.png";

      CustomDialogStack.showLoading(Get.context!);

      final directory = (await getApplicationDocumentsDirectory()).path;
      final filePath = '$directory/$fname';

      Uint8List bytes = await ScreenshotController().captureFromWidget(
        myWidget(myQR),
      );
      final imgFile = File(filePath);
      await imgFile.writeAsBytes(bytes.buffer.asUint8List());

      Get.back();

      if (Platform.isAndroid || Platform.isIOS) {
        await Share.shareXFiles([
          XFile(imgFile.path, mimeType: 'image/png'),
        ], text: "Scan this QR to pay with luvpay!");
      } else {
        CustomDialogStack.showError(
          Get.context!,
          "Unsupported",
          "Sharing is not supported on this platform.",
          () => Get.back(),
        );
      }
    } catch (e) {
      Get.back();
      CustomDialogStack.showError(
        Get.context!,
        "Error",
        "Something went wrong while sharing the QR code.",
        () => Get.back(),
      );
      debugPrint("Error while sharing QR: $e");
    }
  }

  Widget myWidget(String? myQR) => Container(
    color: Colors.grey.shade300,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: LuvpayText(
              text: "Align the QR code\nwithin the frame to proceed.",
              textAlign: TextAlign.center,
            ),
          ),
          spacing(height: 20),
          Container(
            margin: const EdgeInsets.all(40),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: PrettyQrView(
              decoration: const PrettyQrDecoration(
                background: Colors.white,
                image: PrettyQrDecorationImage(
                  image: AssetImage("assets/images/logo.png"),
                ),
              ),
              qrImage: QrImage(
                QrCode.fromData(
                  data: myQR ?? payKey.value,
                  errorCorrectLevel: QrErrorCorrectLevel.H,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  void _loadLastGeneratedTime() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? lastGeneratedTime = prefs.getInt('lastGeneratedTime');

    if (lastGeneratedTime != null) {
      int currentTime = DateTime.now().millisecondsSinceEpoch;
      remainingTime.value = (lastGeneratedTime + (1 * 60 * 1000)) - currentTime;

      if (remainingTime.value < 0) {
        remainingTime.value = 0;
        isButtonDisabled.value = false;
      } else if (remainingTime.value > 0) {
        isButtonDisabled.value = true;
        showTimerMsg.value = true;
        _startTimer();
      }
    } else {
      isButtonDisabled.value = false;
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (remainingTime.value > 0) {
        remainingTime.value -= 1000;
        isButtonDisabled.value = true;
        SharedPreferences.getInstance().then((prefs) {
          prefs.setInt('remainingTime', remainingTime.value);
        });
      } else {
        _timer?.cancel();
        isButtonDisabled.value = false;
        showTimerMsg.value = false;
      }
    });
  }
}
