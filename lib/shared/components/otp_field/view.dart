// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, deprecated_member_use

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as dtTime;
import 'package:luvpay/shared/widgets/colors.dart';
import 'package:luvpay/shared/widgets/luvpay_conn.dart';
import 'package:luvpay/shared/widgets/spacing.dart' show spacing;
import 'package:pinput/pinput.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../../../auth/authentication.dart';
import '../../../core/utils/functions/functions.dart';
import '../../../core/network/http/api_keys.dart';
import '../../../core/network/http/http_request.dart';
import '../../../features/security_settings/utils/in_app_otp_service.dart';
import '../../dialogs/dialogs.dart';
import '../../widgets/custom_scaffold.dart';
import '../../widgets/luvpay_text.dart';
import '../../widgets/luvpay_loading.dart';
import 'package:luvpay/shared/widgets/neumorphism.dart';

import '../../widgets/vertical_height.dart';

class OtpFieldScreen extends StatefulWidget {
  final dynamic arguments;
  const OtpFieldScreen({super.key, this.arguments});

  @override
  State<OtpFieldScreen> createState() => _OtpFieldScreenState();
}

class _OtpFieldScreenState extends State<OtpFieldScreen> {
  TextEditingController pinController = TextEditingController();

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
    super.initState();
    getOtpRequest(showLoader: false);
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void startCountdown() {
    if (paramOtpExp.inMilliseconds <= 0) return;

    timer?.cancel();

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

  void getTmrStat() async {
    await Authentication().enableTimer(false);
  }

  void getOtpRequest({bool showLoader = true}) async {
    if (showLoader) {
      CustomDialogStack.showLoading(Get.context!);
    }

    setState(() {
      inputPin = "";
      _hasError = false;
    });

    var otpData = widget.arguments["req_otp_param"];

    HttpRequestApi(
      api: ApiKeys.postGenerateOtp,
      parameters: otpData,
    ).postBody().then((returnData) async {
      print("returnData $returnData");

      if (returnData == "No Internet") {
        if (showLoader) Get.back();
        setState(() => isNetConn = false);
        return;
      }

      if (returnData == null) {
        if (showLoader) Get.back();
        return;
      }

      if (returnData["success"] == 'Y' || returnData["status"] == "PENDING") {
        if (showLoader) Get.back();

        DateTime timeExp = dtTime.DateFormat(
          "yyyy-MM-dd hh:mm:ss a",
        ).parse(returnData["otp_exp_dt"].toString());

        Duration difference = timeExp.difference(DateTime.now());

        setState(() {
          paramOtpExp = difference.isNegative ? Duration.zero : difference;
          _hasError = false;
        });

        startCountdown();
      } else {
        if (showLoader) Get.back();
        setState(() => _hasError = true);
      }
    });
  }

  void onInputChanged(String value) {
    inputPin = value;
    _hasError = false;

    setState(() {});
  }

  void restartTimer() {
    timer?.cancel();
    getOtpRequest();
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final brand = cs.primary;
    final danger = cs.error;
    final stroke = cs.outlineVariant.withOpacity(isDark ? 0.05 : 0.04);

    Color borderColor;
    if (_hasError) {
      borderColor = danger;
    } else if (inputPin.length == 6) {
      borderColor = brand;
    } else {
      borderColor = stroke;
    }

    final textColor =
        _hasError ? danger : (inputPin.length == 6 ? brand : cs.onSurface);

    final pinFill = cs.surface;
    final pinShadow = cs.shadow.withOpacity(isDark ? 0.35 : 0.08);

    PinTheme getDefaultPinTheme({Color? borderColor, Color? textColor}) {
      return PinTheme(
        width: 52,
        height: 54,
        textStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          height: 22 / 18,
          color: textColor ?? cs.onSurface,
        ),
        decoration: BoxDecoration(
          color: pinFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor ?? stroke, width: 1.8),
          boxShadow: [
            BoxShadow(
              blurRadius: 10,
              spreadRadius: 0,
              offset: Offset(0, 6),
              color: pinShadow,
            ),
          ],
        ),
      );
    }

    return CustomScaffoldV2(
      backgroundColor: cs.surface,
      useNormalBody: true,
      enableToolBar: true,
      scaffoldBody: isLoading
          ? LoadingCard()
          : !isNetConn
              ? ConnectionInterruption(
                  onPressed: () => getOtpRequest(),
                )
              : ScrollConfiguration(
                  behavior: ScrollBehavior().copyWith(overscroll: false),
                  child: StretchingOverscrollIndicator(
                    axisDirection: AxisDirection.down,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          spacing(height: 18),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Center(
                                child: Container(
                                  height: 92,
                                  width: 92,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: cs.surface,
                                    boxShadow: [
                                      BoxShadow(
                                        blurRadius: 18,
                                        offset: Offset(0, 10),
                                        color: cs.shadow.withOpacity(
                                          isDark ? 0.35 : 0.10,
                                        ),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.verified_user_rounded,
                                      size: 46,
                                      color: brand,
                                    ),
                                  ),
                                ),
                              ),
                              spacing(height: 14),
                              Center(
                                child: LuvpayText(
                                  text: "OTP Verification",
                                  style: AppTextStyle.h2(context),
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
                                        color: cs.onSurfaceVariant,
                                      ),
                                      children: <TextSpan>[
                                        TextSpan(
                                          text:
                                              " +${widget.arguments["mobile_no"].toString()}",
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w800,
                                            color: brand,
                                            fontSize: 14,
                                            height: 18 / 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          spacing(height: 26),
                          Center(
                            child: Directionality(
                              textDirection: TextDirection.ltr,
                              child: Pinput(
                                length: 6,
                                controller: pinController,
                                autofocus: true,
                                showCursor: true,
                                closeKeyboardWhenCompleted: false,
                                smsRetriever: null,
                                autofillHints: const [],
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.done,
                                defaultPinTheme: getDefaultPinTheme(
                                  borderColor: borderColor,
                                  textColor: textColor,
                                ),
                                hapticFeedbackType:
                                    HapticFeedbackType.lightImpact,
                                onChanged: (value) => onInputChanged(value),
                                onCompleted: (pin) => onInputChanged(pin),
                                focusedPinTheme: getDefaultPinTheme(
                                  borderColor: brand,
                                  textColor: textColor,
                                ).copyWith(
                                  decoration: getDefaultPinTheme(
                                    borderColor: brand,
                                    textColor: textColor,
                                  ).decoration!.copyWith(
                                        border:
                                            Border.all(color: brand, width: 2),
                                      ),
                                ),
                                errorPinTheme: getDefaultPinTheme(
                                  borderColor: danger,
                                  textColor: danger,
                                ),
                              ),
                            ),
                          ),
                          const VerticalHeight(height: 26),
                          CustomButton(
                            isInactive: pinController.text.isEmpty ||
                                pinController.text.length != 6,
                            text: "Verify",
                            onPressed: verifyAccount,
                          ),
                          spacing(height: 34),
                          Center(
                            child: LuvpayText(
                              text: "Didn’t receive any code?",
                              style: AppTextStyle.paragraph2(context),
                              color: cs.onSurface,
                            ),
                          ),
                          spacing(height: 6),
                          Center(
                            child: InkWell(
                              onTap: paramOtpExp.inSeconds <= 0
                                  ? () {
                                      restartTimer();
                                      pinController.clear();
                                    }
                                  : null,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  LuvpayText(
                                    text: paramOtpExp.inSeconds <= 0
                                        ? "Resend OTP"
                                        : "Resend OTP in",
                                    color: AppColorV2.lpBlueBrand,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  if (paramOtpExp.inSeconds > 0)
                                    LuvpayText(
                                      text: " (${formatDuration(paramOtpExp)})",
                                      color: AppColorV2.lpBlueBrand,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                ],
                              ),
                            ),
                          ),
                          spacing(height: 34),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  String formatDuration(Duration d) {
    String minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    String seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');

    return "$minutes:$seconds";
  }
}
