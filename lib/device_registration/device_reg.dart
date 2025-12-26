import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:luvpay/custom_widgets/app_color_v2.dart';
import 'package:luvpay/custom_widgets/custom_button.dart';
import 'package:luvpay/custom_widgets/luvpay/custom_scaffold.dart';
import 'package:luvpay/custom_widgets/custom_text_v2.dart';
import 'package:luvpay/custom_widgets/spacing.dart';

import '../auth/authentication.dart';
import '../custom_widgets/alert_dialog.dart';
import '../functions/functions.dart';
import '../http/api_keys.dart';
import '../http/http_request.dart';
import '../otp_field/view.dart';
import '../pages/routes/routes.dart';
import 'package:get_storage/get_storage.dart';

class DeviceRegScreen extends StatefulWidget {
  final String mobileNo;
  final String? userId;
  final String pwd;
  final String? sessionId;
  const DeviceRegScreen({
    super.key,
    required this.mobileNo,
    this.userId,
    this.sessionId,
    required this.pwd,
  });

  @override
  State<DeviceRegScreen> createState() => _DeviceRegScreenState();
}

class _DeviceRegScreenState extends State<DeviceRegScreen> {
  final args = Get.arguments;
  bool isVerifiedOtp = false;

  @override
  void initState() {
    super.initState();
  }

  void onRegisterDev() async {
    CustomDialogStack.showLoading(context);
    DateTime timeNow = await Functions.getTimeNow();
    Get.back();
    Map<String, String> reqParam = {
      "mobile_no": widget.mobileNo.toString(),
      "pwd": widget.pwd,
    };
    // "req_type": "SR",
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
          "mobile_no": widget.mobileNo.toString(),
          "otp": obj["otp"].toString(),
          "req_type": "SR",
        };
        Object args = {
          "time_duration": difference,
          "mobile_no": widget.mobileNo,
          "req_otp_param": reqParam,
          "verify_param": putParam,
          "callback": (otp) async {
            final uData = await Authentication().getUserData2();
            if (otp != null) {
              if (widget.sessionId == null) {
                registerDevice();
                return;
              }
              Functions.logoutUser(
                uData == null
                    ? widget.sessionId.toString()
                    : uData["session_id"].toString(),
                (isSuccess) async {
                  if (isSuccess["is_true"]) {
                    registerDevice();
                  }
                },
              );
            } else {
              isVerifiedOtp = false;
            }
          },
        };
        final response = await Get.to(
          OtpFieldScreen(arguments: args),
          transition: Transition.rightToLeftWithFade,
          duration: Duration(milliseconds: 400),
        );
        Get.back(result: response);
      }
    });
  }

  Future<void> registerDevice() async {
    final userId =
        widget.userId == null
            ? args["data"]["user_id"]
            : widget.userId.toString();

    isVerifiedOtp = true;
    FocusManager.instance.primaryFocus?.unfocus();

    CustomDialogStack.showLoading(Get.context!);

    final devKey = await Functions().getUniqueDeviceId();
    Map<String, String> postParamRegDev = {
      "user_id": userId.toString(),
      "device_key": devKey.toString(),
    };

    final response =
        await HttpRequestApi(
          api: ApiKeys.postRegDevice,
          parameters: postParamRegDev,
        ).postBody();

    if (response == "No Internet") {
      Get.back(result: {"success": false});
      CustomDialogStack.showConnectionLost(Get.context!, () {
        Get.back();
      });
      return;
    }
    if (response == null) {
      Get.back(result: {"success": false});
      CustomDialogStack.showError(
        Get.context!,
        "Error",
        "Error while connecting to server, Please try again.",
        () {
          Get.back();
        },
      );
      return;
    }
    if (response["success"] == 'Y') {
      final box = GetStorage();

      box.writeIfNull('isFirstLogin', true);

      Get.back(result: {"success": true});

      if (args["cb"] == null) {
        CustomDialogStack.showSuccess(
          Get.context!,
          "Success!",
          "Device registration complete. Please login to continue.",
          leftText: "Okay",
          () {
            Get.offAndToNamed(Routes.login);
          },
        );
      } else {
        args["cb"]();
      }
    } else {
      Get.back(result: {"success": false});
      CustomDialogStack.showError(Get.context!, "Error", response["msg"], () {
        Get.back();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffoldV2(
      canPop: false,
      enableToolBar: false,

      scaffoldBody: Column(
        children: [
          SizedBox(height: 30),
          Image(
            image: AssetImage("assets/images/onboardluvpay.png"),
            width: 180,
          ),
          spacing(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                DefaultText(
                  maxLines: 1,
                  text: "New sign-in detected",
                  textAlign: TextAlign.center,
                  style: AppTextStyle.h1,
                ),
                SizedBox(height: 5),
                DefaultText(
                  maxLines: 2,
                  text:
                      "Would you like to register your phone\nnumber to this device?",
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          SvgPicture.asset("assets/images/register_device.svg"),
          spacing(height: 50),
          CustomButton(
            text: "Register this device",
            onPressed: isVerifiedOtp ? registerDevice : onRegisterDev,
          ),
          spacing(height: 18),
          CustomButton(
            bordercolor: AppColorV2.lpBlueBrand,
            btnColor: Colors.transparent,
            text: "Later",
            textColor: AppColorV2.lpBlueBrand,
            onPressed: () {
              Get.back();
            },
          ),
          spacing(height: 30),
        ],
      ),
    );
  }
}
