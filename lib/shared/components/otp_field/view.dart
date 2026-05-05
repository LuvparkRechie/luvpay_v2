// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, deprecated_member_use

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as dt_time;
import 'package:pinput/pinput.dart';

import '../../../../auth/authentication.dart';
import '../../../core/network/http/api_keys.dart';
import '../../../core/utils/functions/functions.dart';
import '../../../features/security_settings/utils/in_app_otp_service.dart';
import '../../dialogs/dialogs.dart';
import '../../widgets/colors.dart';
import '../../widgets/custom_scaffold.dart';
import '../../widgets/luvpay_conn.dart';
import '../../widgets/luvpay_loading.dart';
import '../../widgets/luvpay_text.dart';
import '../../widgets/neumorphism.dart';
import '../../widgets/spacing.dart' show spacing;
import '../../widgets/vertical_height.dart';

enum _OtpMethod { sms, inApp }

class OtpFieldScreen extends StatefulWidget {
  final dynamic arguments;
  const OtpFieldScreen({super.key, this.arguments});

  @override
  State<OtpFieldScreen> createState() => _OtpFieldScreenState();
}

class _OtpFieldScreenState extends State<OtpFieldScreen> {
  final TextEditingController pinController = TextEditingController();

  Timer? timer;
  bool isLoading = false;
  bool isNetConn = true;
  bool _hasError = false;
  bool _isInitializing = true;
  String inputPin = "";
  Duration paramOtpExp = Duration.zero;
  DateTime? _inAppExpiryAt;
  bool _allowInAppOtp = false;
  _OtpMethod _selectedMethod = _OtpMethod.sms;

  bool get _isInAppMode => _selectedMethod == _OtpMethod.inApp;

  bool get _forceSmsOnly {
    if (widget.arguments["allow_in_app_otp"] == false) {
      return true;
    }

    final reqOtpParam = widget.arguments["req_otp_param"];
    if (reqOtpParam is Map && reqOtpParam["use_sms"] != null) {
      return reqOtpParam["use_sms"].toString().toUpperCase() == "Y";
    }

    return false;
  }

  @override
  void initState() {
    super.initState();
    _initializeOtpFlow();
  }

  @override
  void dispose() {
    timer?.cancel();
    pinController.dispose();
    super.dispose();
  }

  Future<void> _initializeOtpFlow() async {
    final initialDuration = widget.arguments["time_duration"];

    if (initialDuration is Duration) {
      paramOtpExp =
          initialDuration.isNegative ? Duration.zero : initialDuration;
    }

    final canUseInAppOtp =
        !_forceSmsOnly && await Authentication().canUseInAppOtp();

    if (!mounted) {
      return;
    }

    setState(() {
      _allowInAppOtp = canUseInAppOtp;
      _selectedMethod = canUseInAppOtp ? _OtpMethod.inApp : _OtpMethod.sms;
      _isInitializing = false;
    });

    if (_isInAppMode) {
      await _activateInAppOtp();
      return;
    }

    if (paramOtpExp > Duration.zero) {
      _startSmsCountdown();
      return;
    }

    await getOtpRequest(showLoader: false, useSms: true);
  }

  void _startSmsCountdown() {
    if (paramOtpExp.inMilliseconds <= 0) {
      return;
    }

    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (!mounted) {
        t.cancel();
        return;
      }

      if (paramOtpExp.inSeconds <= 0) {
        t.cancel();
        return;
      }

      setState(() {
        paramOtpExp -= const Duration(seconds: 1);
      });
    });
  }

  Future<void> _activateInAppOtp() async {
    timer?.cancel();

    try {
      final code = await InAppOtpService().getOtp();
      final remaining = InAppOtpService().getRemainingTime();

      if (!mounted) {
        return;
      }

      pinController.text = code;

      setState(() {
        inputPin = code;
        _hasError = false;
        paramOtpExp = remaining;
        _inAppExpiryAt = DateTime.now().add(remaining);
      });

      _startInAppCountdown();
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _allowInAppOtp = false;
        _selectedMethod = _OtpMethod.sms;
      });

      CustomDialogStack.showInfo(context, "In-App OTP unavailable",
          "This account does not have an active in-app OTP secret yet. SMS OTP will be used instead.",
          () {
        Get.back();
      });

      await getOtpRequest(useSms: true);
    }
  }

  void _startInAppCountdown() {
    timer?.cancel();

    if (_inAppExpiryAt == null) {
      return;
    }

    timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (!mounted || _inAppExpiryAt == null) {
        t.cancel();
        return;
      }

      final remaining = _inAppExpiryAt!.difference(DateTime.now());

      if (remaining.inMilliseconds <= 0) {
        t.cancel();
        if (mounted) {
          Get.back(result: null);
        }
        return;
      }

      setState(() {
        paramOtpExp = remaining;
      });
    });
  }

  Future<void> getOtpRequest({
    bool showLoader = true,
    bool useSms = true,
  }) async {
    if (!mounted) return;

    if (showLoader) {
      CustomDialogStack.showLoading(context);
    }

    setState(() {
      inputPin = "";
      _hasError = false;
      pinController.clear();
    });

    try {
      final otpData = Map<String, dynamic>.from(
        (widget.arguments["req_otp_param"] ?? {}) as Map,
      );

      otpData["use_sms"] = useSms ? "Y" : "N";

      final returnData = await Functions().requestHandler(
        apiKey: ApiKeys.postGenerateOtp,
        parameters: otpData,
        method: "POST",
      );

      if (!mounted) return;

      if (returnData == "No Internet") {
        setState(() => isNetConn = false);
        return;
      }

      if (returnData == null) {
        setState(() => _hasError = true);
        CustomDialogStack.showError(
          context,
          "luvpay",
          "Error while connecting to server. Please try again.",
          () => Get.back(),
        );
        return;
      }

      if (returnData["success"] == 'Y' || returnData["status"] == "PENDING") {
        final timeExp = dt_time.DateFormat("yyyy-MM-dd hh:mm:ss a")
            .parse(returnData["otp_exp_dt"].toString());

        final difference = timeExp.difference(DateTime.now());

        setState(() {
          isNetConn = true;
          paramOtpExp = difference.isNegative ? Duration.zero : difference;
          _hasError = false;
        });

        _startSmsCountdown();
      } else {
        setState(() => _hasError = true);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => _hasError = true);

      CustomDialogStack.showError(
        context,
        "luvpay",
        "Unable to resend OTP. Please try again.",
        () => Get.back(),
      );
    } finally {
      if (showLoader && Get.isDialogOpen == true) {
        Get.back();
      }
    }
  }

  Future<void> _switchOtpMethod(_OtpMethod method) async {
    if (_selectedMethod == method) {
      return;
    }

    setState(() {
      _selectedMethod = method;
      _hasError = false;
      inputPin = "";
      pinController.clear();
    });

    if (_isInAppMode) {
      await _activateInAppOtp();
      return;
    }

    await getOtpRequest(useSms: true);
  }

  void onInputChanged(String value) {
    inputPin = value;
    _hasError = false;
    setState(() {});
  }

  bool _isResendingOtp = false;

  Future<void> restartTimer() async {
    if (_isResendingOtp) return;

    timer?.cancel();

    setState(() {
      _isResendingOtp = true;
    });

    try {
      await getOtpRequest(useSms: true);
    } finally {
      if (mounted) {
        setState(() {
          _isResendingOtp = false;
        });
      }
    }
  }

  Future<void> verifyAccount() async {
    if (pinController.text.length != 6) {
      CustomDialogStack.showError(
          Get.context!, "Invalid OTP", "Please complete the 6-digit OTP.", () {
        setState(() {
          isLoading = false;
          _hasError = false;
        });
        Get.back();
      });
      return;
    }

    if (widget.arguments["is_forget_vfd_pass"] != null &&
        widget.arguments["is_forget_vfd_pass"] &&
        !_isInAppMode) {
      widget.arguments["callback"](int.parse(pinController.text));
      return;
    }

    final verifyPayload = Map<String, dynamic>.from(
        (widget.arguments["verify_param"] ?? {}) as Map);
    verifyPayload["otp"] = pinController.text;
    verifyPayload["use_sms"] = _isInAppMode ? "N" : "Y";
    verifyPayload["otp_method"] = _isInAppMode ? "IN_APP" : "SMS";

    CustomDialogStack.showLoading(Get.context!);

    Functions()
        .requestHandler(
            apiKey: ApiKeys.putVerifyOtp,
            parameters: verifyPayload,
            method: "PUT")
        .then((returnData) async {
      if (returnData == "No Internet") {
        Get.back();
        CustomDialogStack.showError(Get.context!, "luvpay",
            'Please check your internet connection and try again.', () {
          Get.back();
        });
        return;
      }

      if (returnData == null) {
        Get.back();
        CustomDialogStack.showError(Get.context!, "luvpay",
            "Error while connecting to server, Please try again.", () {
          Get.back();
        });
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
      }

      final isInvalid =
          returnData["msg"].toString().toLowerCase().contains("invalid");
      final subtitle = isInvalid
          ? "Hmm, that code doesn’t look right. Please try again."
          : "Your OTP has expired. Request a new one to continue.";
      final title = isInvalid ? "Invalid OTP" : "Code expired";

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
    });
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
    } else if (inputPin.length == 6 || _isInAppMode) {
      borderColor = brand;
    } else {
      borderColor = stroke;
    }

    final textColor = _hasError
        ? danger
        : (inputPin.length == 6 || _isInAppMode)
            ? brand
            : cs.onSurface;

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
              color: textColor ?? cs.onSurface),
          decoration: BoxDecoration(
              color: pinFill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor ?? stroke, width: 1.8),
              boxShadow: [
                BoxShadow(
                    blurRadius: 10,
                    spreadRadius: 0,
                    offset: Offset(0, 6),
                    color: pinShadow),
              ]));
    }

    Widget methodSwitcher() {
      if (!_allowInAppOtp) {
        return SizedBox.shrink();
      }

      Widget methodChip(_OtpMethod method, String label) {
        final isActive = _selectedMethod == method;
        return Expanded(
            child: CustomButton(
                btnColor: isActive ? brand : cs.surface,
                textColor: isActive ? cs.onPrimary : cs.onSurface,
                bordercolor:
                    isActive ? brand : cs.outlineVariant.withOpacity(0.5),
                text: label,
                onPressed: () => _switchOtpMethod(method)));
      }

      return Column(children: [
        Row(children: [
          methodChip(_OtpMethod.inApp, "In-App OTP"),
          SizedBox(width: 10),
          methodChip(_OtpMethod.sms, "SMS OTP"),
        ]),
        spacing(height: 14),
      ]);
    }

    Widget topNotice() {
      if (!_isInAppMode) {
        return SizedBox.shrink();
      }

      return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: brand.withOpacity(isDark ? 0.18 : 0.10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: brand.withOpacity(0.18))),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.shield_rounded, color: brand, size: 20),
            SizedBox(width: 10),
            Expanded(
                child: LuvpayText(
                    text:
                        "Confirm before the timer ends. For security, this screen closes when the in-app OTP expires.",
                    style:
                        AppTextStyle.paragraph2(context).copyWith(height: 1.35),
                    color: cs.onSurface)),
          ]));
    }

    Widget instructionText() {
      if (_isInAppMode) {
        return Center(
            child: LuvpayText(
                text:
                    "Use the in-app OTP generated from this registered device to approve this request.",
                textAlign: TextAlign.center,
                style: GoogleFonts.openSans(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    height: 18 / 14,
                    color: cs.onSurfaceVariant)));
      }

      return RichText(
          textAlign: TextAlign.center,
          text: TextSpan(children: [
            TextSpan(
                text: "We have sent an OTP to your registered\nmobile number",
                style: GoogleFonts.openSans(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    height: 18 / 14,
                    color: cs.onSurfaceVariant),
                children: <TextSpan>[
                  TextSpan(
                      text: " +${widget.arguments["mobile_no"].toString()}",
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800,
                          color: brand,
                          fontSize: 14,
                          height: 18 / 14)),
                ]),
          ]));
    }

    return CustomScaffoldV2(
        backgroundColor: cs.surface,
        useNormalBody: true,
        enableToolBar: true,
        scaffoldBody: _isInitializing || isLoading
            ? LoadingCard()
            : !isNetConn
                ? ConnectionInterruption(
                    onPressed: () => getOtpRequest(useSms: true))
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
                              topNotice(),
                              if (_isInAppMode) spacing(height: 18),
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
                                                      color: cs.shadow
                                                          .withOpacity(isDark
                                                              ? 0.35
                                                              : 0.10)),
                                                ]),
                                            child: Center(
                                                child: Icon(
                                                    Icons.verified_user_rounded,
                                                    size: 46,
                                                    color: brand)))),
                                    spacing(height: 14),
                                    Center(
                                        child: LuvpayText(
                                            text: "OTP Verification",
                                            style: AppTextStyle.h2(context),
                                            height: 28 / 24)),
                                    SizedBox(height: 8),
                                    instructionText(),
                                  ]),
                              spacing(height: 26),
                              methodSwitcher(),
                              Center(
                                  child: Directionality(
                                      textDirection: TextDirection.ltr,
                                      child: Pinput(
                                          length: 6,
                                          controller: pinController,
                                          autofocus: !_isInAppMode,
                                          readOnly: _isInAppMode,
                                          showCursor: !_isInAppMode,
                                          closeKeyboardWhenCompleted: false,
                                          smsRetriever: null,
                                          autofillHints: const [],
                                          keyboardType: TextInputType.number,
                                          textInputAction: TextInputAction.done,
                                          defaultPinTheme: getDefaultPinTheme(
                                              borderColor: borderColor,
                                              textColor: textColor),
                                          hapticFeedbackType:
                                              HapticFeedbackType.lightImpact,
                                          onChanged: (value) =>
                                              onInputChanged(value),
                                          onCompleted: (pin) =>
                                              onInputChanged(pin),
                                          focusedPinTheme:
                                              getDefaultPinTheme(borderColor: brand, textColor: textColor).copyWith(
                                                  decoration: getDefaultPinTheme(
                                                          borderColor: brand,
                                                          textColor: textColor)
                                                      .decoration!
                                                      .copyWith(
                                                          border: Border.all(
                                                              color: brand,
                                                              width: 2))),
                                          errorPinTheme: getDefaultPinTheme(
                                              borderColor: danger,
                                              textColor: danger)))),
                              const VerticalHeight(height: 26),
                              CustomButton(
                                  isInactive: pinController.text.isEmpty ||
                                      pinController.text.length != 6,
                                  text: _isInAppMode ? "Confirm" : "Verify",
                                  onPressed: verifyAccount),
                              spacing(height: 34),
                              Center(
                                  child: LuvpayText(
                                      text: _isInAppMode
                                          ? "This confirmation window ends in"
                                          : "Didn’t receive any code?",
                                      style: AppTextStyle.paragraph2(context),
                                      color: cs.onSurface)),
                              spacing(height: 6),
                              Center(
                                  child: InkWell(
                                      onTap: _isInAppMode
                                          ? null
                                          : paramOtpExp.inSeconds <= 0 &&
                                                  !_isResendingOtp
                                              ? () {
                                                  restartTimer();
                                                }
                                              : null,
                                      child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            LuvpayText(
                                                text: _isResendingOtp
                                                    ? "Resending OTP..."
                                                    : _isInAppMode
                                                        ? "Code expires in"
                                                        : paramOtpExp
                                                                    .inSeconds <=
                                                                0
                                                            ? "Resend OTP"
                                                            : "Resend OTP in",
                                                color: AppColorV2.lpBlueBrand,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700),
                                            if (paramOtpExp.inSeconds > 0 ||
                                                _isInAppMode)
                                              LuvpayText(
                                                  text:
                                                      " (${formatDuration(paramOtpExp)})",
                                                  color: AppColorV2.lpBlueBrand,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 14),
                                          ]))),
                              spacing(height: 34),
                            ])))));
  }

  String formatDuration(Duration d) {
    final safeDuration =
        d.isNegative ? Duration.zero : Duration(seconds: d.inSeconds);
    final minutes =
        safeDuration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds =
        safeDuration.inSeconds.remainder(60).toString().padLeft(2, '0');

    return "$minutes:$seconds";
  }
}
