// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as dtTime;
import 'package:luvpay/http/http_request.dart';
import '../../custom_widgets/app_color_v2.dart';
import '../../custom_widgets/custom_button.dart';
import '../../custom_widgets/luvpay/custom_scaffold.dart';
import '../../custom_widgets/custom_text_v2.dart';
import '../../custom_widgets/loading.dart';
import '../../custom_widgets/no_internet.dart';
import '../../custom_widgets/spacing.dart';
import '../../custom_widgets/vertical_height.dart';
import 'package:pinput/pinput.dart';

import '../../auth/authentication.dart';
import '../../custom_widgets/alert_dialog.dart';
import '../../functions/functions.dart';
import '../../http/api_keys.dart';

class OtpFieldScreen extends StatefulWidget {
  final dynamic arguments;
  const OtpFieldScreen({super.key, this.arguments});

  @override
  State<OtpFieldScreen> createState() => _OtpFieldScreenState();
}

class _OtpFieldScreenState extends State<OtpFieldScreen> {
  TextEditingController pinController = TextEditingController();
  Duration countdownDuration = const Duration(minutes: 2);

  Timer? timer;
  bool isLoading = false;
  bool isRequested = false;
  bool isNetConn = true;
  bool isLoadingPage = true;
  String inputPin = "";
  bool isOtpValid = true;
  bool isRunning = false;
  int otpCode = 0;
  Duration paramOtpExp = Duration(seconds: 0);
  bool _hasError = false;

  @override
  void initState() {
    pinController = TextEditingController();

    paramOtpExp =
        widget.arguments["time_duration"] ?? Duration(minutes: 3, seconds: 59);

    startCountdown();

    super.initState();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void startCountdown() {
    if (paramOtpExp.inMilliseconds <= 0) return;
    timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (paramOtpExp.inSeconds <= 0) {
        t.cancel();
      } else {
        setState(() {
          paramOtpExp -= const Duration(seconds: 1);
        });
      }
    });
  }

  String formatDuration(Duration d) {
    String minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    String seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');

    return "$minutes:$seconds";
  }

  void getTmrStat() async {
    await Authentication().enableTimer(false);
  }

  void getOtpRequest() async {
    setState(() {
      inputPin = "";
      _hasError = false;
    });
    CustomDialogStack.showLoading(Get.context!);
    DateTime timeNow = await Functions.getTimeNow();
    var otpData = widget.arguments["req_otp_param"];

    HttpRequestApi(
      api: ApiKeys.postGenerateOtp,
      parameters: otpData,
    ).postBody().then((returnData) async {
      if (returnData == "No Internet") {
        setState(() {
          inputPin = "";
          isLoadingPage = false;
          isNetConn = false;
          _hasError = false;
        });
        Get.back();
        CustomDialogStack.showError(
          Get.context!,
          "luvpay",
          "Please check your internet connection and try again.",
          () {
            Get.back();
          },
        );

        return;
      }
      if (returnData == null) {
        setState(() {
          inputPin = "";
          isLoadingPage = false;
          isNetConn = true;
        });
        Get.back();
        CustomDialogStack.showError(
          Get.context!,
          "luvpay",
          "Error while connecting to server, Please try again.",
          () {
            Get.back();
          },
        );

        return;
      }

      if (returnData["success"] == 'Y') {
        Get.back();
        DateTime timeExp = dtTime.DateFormat(
          "yyyy-MM-dd hh:mm:ss a",
        ).parse(returnData["otp_exp_dt"].toString());
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

        setState(() {
          isLoadingPage = false;
          isNetConn = true;

          inputPin = "";

          otpCode = int.parse(returnData["otp"].toString());
          isRequested = true;
          paramOtpExp = difference;
          _hasError = false;
        });

        startCountdown();

        getTmrStat();
      } else {
        setState(() {
          inputPin = "";
          isLoadingPage = false;
          isNetConn = true;
          _hasError = true;
        });
        Get.back();
        CustomDialogStack.showError(
          Get.context!,
          "luvpay",
          returnData["msg"],
          () {
            Get.back();
          },
        );
        return;
      }
    });
  }

  void onInputChanged(String value) {
    inputPin = value;
    _hasError = false;
    if (value.isNotEmpty && int.tryParse(value) != null) {
      if (int.parse(value) == otpCode) {
      } else {
        isOtpValid = false;
      }
    } else {
      isOtpValid = false;
    }
    setState(() {});
  }

  void restartTimer() {
    if (timer != null && timer!.isActive) {
      timer!.cancel();
    }
    setState(() {
      getOtpRequest();
    });
  }

  Future<void> verifyAccount() async {
    if (inputPin.length != 6) {
      CustomDialogStack.showError(
        Get.context!,
        "Invalid OTP",
        "Please complete the 6-digits OTP",
        () {
          setState(() {
            isLoading = false;
            _hasError = false;
          });
          Get.back();
        },
      );
      return;
    }
    if (widget.arguments["is_forget_vfd_pass"] != null &&
        widget.arguments["is_forget_vfd_pass"]) {
      widget.arguments["callback"](int.parse(pinController.text));
      return;
    } else {
      List paramData = [widget.arguments["verify_param"]];
      paramData.map((e) {
        e["otp"] = pinController.text;
        return e;
      }).toList();

      CustomDialogStack.showLoading(Get.context!);

      HttpRequestApi(
        api: ApiKeys.putVerifyOtp,
        parameters: paramData[0],
      ).putBody().then((returnData) async {
        if (returnData == "No Internet") {
          Get.back();

          CustomDialogStack.showError(
            Get.context!,
            "luvpay",
            'Please check your internet connection and try again.',
            () {
              Get.back();
            },
          );

          return;
        }
        if (returnData == null) {
          Get.back();
          CustomDialogStack.showError(
            Get.context!,
            "luvpay",
            "Error while connecting to server, Please try again.",
            () {
              Get.back();
            },
          );

          return;
        }
        if (returnData["success"] == 'Y') {
          Get.back();
          Get.back();
          setState(() {
            _hasError = false;
          });
          widget.arguments["callback"](int.parse(pinController.text));
          return;
        } else {
          String subtitle =
              !returnData["msg"].toString().toLowerCase().contains("invalid")
                  ? "Your OTP has expired. Request a new one to continue."
                  : "Hmm, that code doesn’t look right. Please try again.";
          String title =
              !returnData["msg"].toString().toLowerCase().contains("invalid")
                  ? "Code expired"
                  : "Invalid OTP";
          Get.back();
          setState(() {
            _hasError = true;
          });
          CustomDialogStack.showError(Get.context!, title, subtitle, () {
            setState(() {
              _hasError = true;
            });
            Get.back();
          });
          return;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Color borderColor;
    if (_hasError) {
      borderColor = AppColorV2.incorrectState;
    } else if (inputPin.length == 6) {
      borderColor = AppColorV2.lpBlueBrand;
    } else {
      borderColor = AppColorV2.boxStroke;
    }

    Color textColor =
        _hasError
            ? AppColorV2.incorrectState
            : (inputPin.length == 6 ? AppColorV2.lpBlueBrand : Colors.black);

    PinTheme getDefaultPinTheme({Color? borderColor, Color? textColor}) {
      return PinTheme(
        width: 50,
        height: 50,
        textStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          height: 22 / 18,
          color: textColor ?? Colors.black,
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: borderColor ?? AppColorV2.boxStroke,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(6),
          color: AppColorV2.background,
        ),
      );
    }

    return CustomScaffoldV2(
      enableToolBar: true,
      scaffoldBody:
          isLoading
              ? LoadingCard()
              : !isNetConn
              ? NoInternetConnected(onTap: getOtpRequest)
              : ScrollConfiguration(
                behavior: ScrollBehavior().copyWith(overscroll: false),
                child: StretchingOverscrollIndicator(
                  axisDirection: AxisDirection.down,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        spacing(height: 20),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Center(
                              child: Image(
                                image: AssetImage(
                                  "assets/images/otp_image.png",
                                ),
                                fit: BoxFit.contain,
                                width: 200,
                                height: 200,
                              ),
                            ),
                            Center(
                              child: DefaultText(
                                text: "OTP Verification",
                                style: AppTextStyle.h2,
                                height: 28 / 24,
                              ),
                            ),
                            SizedBox(height: 8),
                            RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text:
                                        "We have sent an OTP to your registered\nmobile number",
                                    style: GoogleFonts.openSans(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                      height: 18 / 14,
                                      color: AppColorV2.bodyTextColor,
                                    ),
                                    children: <TextSpan>[
                                      TextSpan(
                                        text:
                                            " +${widget.arguments["mobile_no"].toString()}",
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w700,
                                          color: AppColorV2.lpBlueBrand,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        spacing(height: 28),
                        Center(
                          child: Directionality(
                            textDirection: TextDirection.ltr,
                            child: Pinput(
                              pinAnimationType: PinAnimationType.slide,
                              autofocus: true,
                              showCursor: false,
                              keyboardType:
                                  Platform.isAndroid
                                      ? TextInputType.phone
                                      : TextInputType.numberWithOptions(
                                        signed: true,
                                        decimal: false,
                                      ),
                              textInputAction: TextInputAction.done,
                              length: 6,
                              controller: pinController,
                              defaultPinTheme: getDefaultPinTheme(
                                borderColor: borderColor,
                                textColor: textColor,
                              ),
                              hapticFeedbackType:
                                  HapticFeedbackType.lightImpact,
                              onCompleted: (pin) {
                                if (pin.length == 6) {
                                  onInputChanged(pin);
                                }
                              },
                              onChanged: (value) {
                                if (value.isEmpty) {
                                  onInputChanged(value);
                                } else {
                                  onInputChanged(value);
                                }
                              },
                              focusedPinTheme: getDefaultPinTheme(
                                borderColor: AppColorV2.lpBlueBrand,
                                textColor: textColor,
                              ).copyWith(
                                decoration: getDefaultPinTheme(
                                  borderColor: AppColorV2.lpBlueBrand,
                                  textColor: textColor,
                                ).decoration!.copyWith(
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(
                                    color: AppColorV2.lpBlueBrand,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const VerticalHeight(height: 30),
                        CustomButton(
                          isInactive:
                              pinController.text.isEmpty ||
                              pinController.text.length != 6,
                          text: "Verify",
                          onPressed: verifyAccount,
                        ),
                        spacing(height: 40),
                        Center(
                          child: DefaultText(
                            text: "Didn’t receive any code?",
                            style: AppTextStyle.paragraph2,
                            color: AppColorV2.primaryTextColor,
                          ),
                        ),
                        spacing(height: 2),
                        InkWell(
                          onTap:
                              paramOtpExp.inSeconds <= 0
                                  ? () {
                                    restartTimer();
                                    pinController.clear();
                                  }
                                  : null,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              DefaultText(
                                text:
                                    paramOtpExp.inSeconds <= 0
                                        ? "Resend OTP"
                                        : "Resend OTP in",
                                color: AppColorV2.lpBlueBrand,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                              if (paramOtpExp.inSeconds > 0)
                                DefaultText(
                                  text: " (${formatDuration(paramOtpExp)})",
                                  color: AppColorV2.lpBlueBrand,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                            ],
                          ),
                        ),
                        spacing(height: 39),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }
}
