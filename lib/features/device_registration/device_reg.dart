// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:luvpay/shared/widgets/colors.dart';
import 'package:luvpay/shared/widgets/luvpay_text.dart';

import '../../auth/authentication.dart';
import 'package:luvpay/shared/widgets/neumorphism.dart';

import '../../core/utils/functions/functions.dart';
import '../../core/network/http/api_keys.dart';
import '../../core/network/http/http_request.dart';
import '../../shared/dialogs/dialogs.dart';
import '../../shared/components/otp_field/view.dart';
import '../routes/routes.dart';

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

  Future<void> onRegisterDev() async {
    final ctx = Get.overlayContext ?? context;

    CustomDialogStack.showLoading(ctx);
    DateTime timeNow;
    try {
      timeNow = await Functions.getTimeNow();
    } finally {
      if (Get.isDialogOpen == true) {
        Navigator.of(ctx, rootNavigator: true).pop();
      }
    }

    final reqParam = {
      "mobile_no": widget.mobileNo.toString(),
      "pwd": widget.pwd,
    };

    Functions().requestOtp(reqParam, (obj) async {
      final timeExp = DateFormat(
        "yyyy-MM-dd hh:mm:ss a",
      ).parse(obj["otp_exp_dt"].toString());

      final otpExpiry = DateTime(
        timeExp.year,
        timeExp.month,
        timeExp.day,
        timeExp.hour,
        timeExp.minute,
        timeExp.millisecond,
      );

      final difference = otpExpiry.difference(timeNow);

      if (obj["success"] == "Y" || obj["status"] == "PENDING") {
        final putParam = {
          "mobile_no": widget.mobileNo.toString(),
          "otp": obj["otp"].toString(),
          "req_type": "SR",
        };

        final navArgs = {
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
          OtpFieldScreen(arguments: navArgs),
          transition: Transition.rightToLeftWithFade,
          duration: const Duration(milliseconds: 350),
        );
        Get.back(result: response);
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

    final ctx = Get.overlayContext ?? Get.context!;
    CustomDialogStack.showLoading(ctx, text: "Registering device...");

    try {
      final devKey = await Functions().getUniqueDeviceId();
      final postParamRegDev = {
        "user_id": userId.toString(),
        "device_key": devKey.toString(),
      };

      final response =
          await HttpRequestApi(
            api: ApiKeys.postRegDevice,
            parameters: postParamRegDev,
          ).postBody();

      if (Get.isDialogOpen == true) {
        Navigator.of(ctx, rootNavigator: true).pop();
      }

      if (response == "No Internet") {
        Get.back(result: {"success": false});
        CustomDialogStack.showConnectionLost(Get.context!, () => Get.back());
        return;
      }

      if (response == null) {
        Get.back(result: {"success": false});
        CustomDialogStack.showError(
          Get.context!,
          "Error",
          "Error while connecting to server, Please try again.",
          () => Get.back(),
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
            () => Get.offAndToNamed(Routes.login),
            leftText: "Okay",
          );
        } else {
          args["cb"]();
        }
      } else {
        Get.back(result: {"success": false});
        CustomDialogStack.showError(
          Get.context!,
          "Error",
          response["msg"],
          () => Get.back(),
        );
      }
    } catch (_) {
      if (Get.isDialogOpen == true) {
        Navigator.of(ctx, rootNavigator: true).pop();
      }
      CustomDialogStack.showError(
        ctx,
        "luvpay",
        "Something went wrong. Please try again.",
        () => Get.back(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final brand = AppColorV2.lpBlueBrand;
    final surface = cs.surface;
    final onSurface = cs.onSurface;
    final onSurfaceVar = cs.onSurfaceVariant;
    final outline = cs.outlineVariant.withOpacity(isDark ? 0.55 : 0.75);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
          .copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: surface,
            systemNavigationBarIconBrightness:
                isDark ? Brightness.light : Brightness.dark,
          ),
      child: Scaffold(
        backgroundColor: surface,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          SvgPicture.asset(
                            "assets/images/register_device.svg",
                            height: 180,
                          ),
                          const SizedBox(height: 18),

                          LuvpayText(
                            maxLines: 1,
                            text: "New sign-in detected",
                            textAlign: TextAlign.center,
                            style: AppTextStyle.h1(context),
                            color: onSurface,
                          ),
                          const SizedBox(height: 8),

                          LuvpayText(
                            maxLines: 3,
                            text:
                                "Register this device to keep your account secure.\nYou can always do this later.",
                            textAlign: TextAlign.center,
                            style: AppTextStyle.paragraph2(context).copyWith(
                              height: 1.35,
                              color: onSurfaceVar.withOpacity(0.85),
                            ),
                          ),

                          const SizedBox(height: 16),

                          InfoRowTile(
                            title: "Mobile number",
                            onTap: () {},
                            icon: Icons.phone_iphone_rounded,
                            subtitle: widget.mobileNo,
                          ),

                          const SizedBox(height: 18),

                          SizedBox(
                            width: double.infinity,
                            child: CustomButton(
                              bordercolor: outline,
                              text: "Register this device",
                              onPressed:
                                  isVerifiedOtp
                                      ? registerDevice
                                      : onRegisterDev,
                            ),
                          ),

                          const SizedBox(height: 10),

                          CustomButton(
                            bordercolor: outline,
                            btnColor: Colors.transparent,
                            text: "Later",
                            textColor: brand,
                            onPressed: () => Get.back(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: LuvpayText(
                    text: "Tip: Registering helps prevent unauthorized access.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: onSurfaceVar.withOpacity(0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
