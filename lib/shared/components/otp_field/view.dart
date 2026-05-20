// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, deprecated_member_use

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as dt_time;
import 'package:pinput/pinput.dart';

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
import 'otp_delivery_policy.dart';

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
  bool _isRequestingOtp = false;
  bool _isGeneratorSheetOpen = false;
  bool _isRefreshingInAppOtp = false;
  String inputPin = "";
  String? _generatedInAppOtp;
  Duration paramOtpExp = Duration.zero;
  DateTime? _inAppExpiryAt;
  StateSetter? _generatorSheetSetState;
  OtpDeliveryMethod _deliveryMethod = OtpDeliveryMethod.sms;
  bool _inAppOtpAvailable = false;

  bool get _isInAppMode => _deliveryMethod == OtpDeliveryMethod.inApp;

  bool get _forceSmsOnly {
    if (widget.arguments["allow_in_app_otp"] == false) {
      return true;
    }

    final reqOtpParam = widget.arguments["req_otp_param"];
    if (reqOtpParam is Map && reqOtpParam["use_sms"] != null) {
      return OtpDeliveryPolicy.isSmsFlag(reqOtpParam["use_sms"].toString());
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
    _generatorSheetSetState = null;
    pinController.dispose();
    super.dispose();
  }

  Future<void> _initializeOtpFlow() async {
    final initialDuration = widget.arguments["time_duration"];

    if (initialDuration is Duration) {
      paramOtpExp =
          initialDuration.isNegative ? Duration.zero : initialDuration;
    }

    final deliveryMethod =
        await OtpDeliveryPolicy().resolve(allowInAppOtp: !_forceSmsOnly);

    if (!mounted) {
      return;
    }

    setState(() {
      _deliveryMethod = deliveryMethod;
      _inAppOtpAvailable = deliveryMethod == OtpDeliveryMethod.inApp;
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

  void _closeOtpScreen() {
    _cleanupOtpOverlays();
    Get.back(result: null);
  }

  void _cleanupOtpOverlays() {
    timer?.cancel();
    _generatorSheetSetState = null;
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

  Future<void> _activateInAppOtp({bool showGenerator = true}) async {
    if (_isRefreshingInAppOtp) {
      return;
    }

    timer?.cancel();

    try {
      _isRefreshingInAppOtp = true;
      final code = await InAppOtpService().getOtp();
      final remaining = InAppOtpService().getRemainingTime();

      if (!mounted) {
        return;
      }

      setState(() {
        _generatedInAppOtp = code;
        inputPin = "";
        pinController.clear();
        _hasError = false;
        paramOtpExp = remaining;
        _inAppExpiryAt = DateTime.now().add(remaining);
      });
      _generatorSheetSetState?.call(() {});

      _startInAppCountdown();

      if (showGenerator) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showInAppOtpGenerator();
          }
        });
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _generatedInAppOtp = null;
        _hasError = true;
      });

      CustomDialogStack.showError(
        context,
        "OTP Generator unavailable",
        "Unable to generate a code on this device. Please refresh your account or turn off OTP Generator.",
        () {
          Get.back();
        },
      );
    } finally {
      _isRefreshingInAppOtp = false;
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
          _activateInAppOtp(showGenerator: false);
        }
        return;
      }

      setState(() {
        paramOtpExp = remaining;
      });
      _generatorSheetSetState?.call(() {});
    });
  }

  Future<void> _showInAppOtpGenerator() async {
    if (!_isInAppMode || _isGeneratorSheetOpen || !mounted) {
      return;
    }

    if (_generatedInAppOtp == null || paramOtpExp.inMilliseconds <= 0) {
      await _activateInAppOtp(showGenerator: false);
    }

    if (!mounted || _generatedInAppOtp == null) {
      return;
    }

    _isGeneratorSheetOpen = true;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            _generatorSheetSetState = setSheetState;
            return _buildInAppGeneratorSheet(sheetContext);
          },
        );
      },
    );

    _isGeneratorSheetOpen = false;
    _generatorSheetSetState = null;
  }

  Widget _buildInAppGeneratorSheet(BuildContext sheetContext) {
    final theme = Theme.of(sheetContext);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final accent = cs.primary;
    final remainingSeconds =
        _displayRemainingSeconds(paramOtpExp, maxSeconds: 30);
    final progress = (remainingSeconds / 30).clamp(0.0, 1.0).toDouble();
    final bottomPadding = MediaQuery.of(sheetContext).padding.bottom;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, 0, 16, 20 + bottomPadding),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(isDark ? 0.50 : 0.16),
            blurRadius: 24,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.translate(
            offset: const Offset(0, -30),
            child: Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.primaryContainer,
                boxShadow: [
                  BoxShadow(
                    color: accent.withOpacity(0.30),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                Icons.phone_android_rounded,
                color: cs.onPrimaryContainer,
                size: 30,
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -12),
            child: Column(
              children: [
                LuvpayText(
                  text: "One-Time Password",
                  style: AppTextStyle.h3(sheetContext).copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  color: cs.onSurface.withOpacity(0.72),
                ),
                const SizedBox(height: 16),
                Text(
                  _formatGeneratedOtp(_generatedInAppOtp),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 7,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: 58,
                  height: 58,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 4,
                        backgroundColor: accent.withOpacity(0.12),
                        valueColor: AlwaysStoppedAnimation<Color>(accent),
                      ),
                      LuvpayText(
                        text: remainingSeconds.toString(),
                        style: AppTextStyle.paragraph2(sheetContext).copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        color: cs.onSurface.withOpacity(0.54),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: "Cancel",
                        filled: false,
                        borderRadius: 28,
                        textColor: cs.onSurface.withOpacity(0.70),
                        bordercolor: cs.outlineVariant.withOpacity(0.35),
                        onPressed: () => Navigator.of(sheetContext).pop(),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: CustomButton(
                        text: "Continue",
                        borderRadius: 28,
                        btnColor: accent,
                        textColor: cs.onPrimary,
                        onPressed: () =>
                            _continueWithGeneratedOtp(sheetContext),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatGeneratedOtp(String? value) {
    final code = value ?? "";
    if (code.length != 6) {
      return code;
    }

    return code.split("").join(" ");
  }

  void _continueWithGeneratedOtp(BuildContext sheetContext) {
    final code = _generatedInAppOtp;
    if (code == null || code.length != 6 || paramOtpExp.inMilliseconds <= 0) {
      _activateInAppOtp(showGenerator: false);
      return;
    }

    Navigator.of(sheetContext).pop();
    if (!mounted) {
      return;
    }

    setState(() {
      pinController.text = code;
      inputPin = code;
      _hasError = false;
    });

    verifyAccount();
  }

  Future<void> getOtpRequest({
    bool showLoader = true,
    bool useSms = true,
  }) async {
    if (_isRequestingOtp) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isRequestingOtp = true;
      inputPin = "";
      _hasError = false;
      pinController.clear();
    });

    try {
      final rawOtpData = widget.arguments["req_otp_param"];
      final otpData = rawOtpData is Map
          ? Map<String, dynamic>.from(rawOtpData)
          : <String, dynamic>{};
      otpData["use_sms"] =
          useSms ? OtpDeliveryPolicy.smsFlag : OtpDeliveryPolicy.inAppFlag;
      final backendOtpData = Map<String, dynamic>.from(otpData)
        ..remove("use_sms")
        ..remove("otp_method");

      final returnData = await Functions().requestHandler(
        apiKey: ApiKeys.postGenerateOtp,
        parameters: backendOtpData,
        method: "POST",
      );

      if (!mounted) {
        return;
      }

      if (returnData == "No Internet") {
        setState(() => isNetConn = false);
        return;
      }

      if (returnData is! Map) {
        setState(() => _hasError = true);
        return;
      }

      if (returnData["success"] == 'Y' || returnData["status"] == "PENDING") {
        final timeExp = _parseOtpExpiry(returnData["otp_exp_dt"]?.toString());
        if (timeExp == null) {
          setState(() => _hasError = true);
          return;
        }

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
    } catch (_) {
      if (mounted) {
        setState(() => _hasError = true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRequestingOtp = false;
        });
      }
    }
  }

  DateTime? _parseOtpExpiry(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    try {
      return dt_time.DateFormat("yyyy-MM-dd hh:mm:ss a").parse(value);
    } catch (_) {}

    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }

  void onInputChanged(String value) {
    inputPin = value;
    _hasError = false;
    setState(() {});
  }

  void restartTimer() {
    if (_isRequestingOtp) {
      return;
    }

    timer?.cancel();
    getOtpRequest(useSms: true);
  }

  Future<void> _switchOtpMethod(OtpDeliveryMethod method) async {
    if (_deliveryMethod == method || _isRequestingOtp) {
      return;
    }

    if (method == OtpDeliveryMethod.inApp && !_inAppOtpAvailable) {
      return;
    }

    timer?.cancel();

    setState(() {
      _deliveryMethod = method;
      _hasError = false;
      inputPin = "";
      pinController.clear();
      paramOtpExp = Duration.zero;
      _inAppExpiryAt = null;
    });

    if (method == OtpDeliveryMethod.inApp) {
      await _activateInAppOtp();
      return;
    }

    await getOtpRequest(useSms: true);
  }

  Future<void> verifyAccount() async {
    if (pinController.text.length != 6) {
      CustomDialogStack.showError(
        Get.context!,
        "Invalid OTP",
        "Please complete the 6-digit OTP.",
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
        widget.arguments["is_forget_vfd_pass"] &&
        !_isInAppMode) {
      widget.arguments["callback"](int.parse(pinController.text));
      return;
    }

    if (_isInAppMode) {
      await _verifyLocalInAppOtp();
      return;
    }

    final verifyPayload = Map<String, dynamic>.from(
      (widget.arguments["verify_param"] ?? {}) as Map,
    );
    verifyPayload["otp"] = pinController.text;

    CustomDialogStack.showLoading(Get.context!);

    Functions()
        .requestHandler(
      apiKey: ApiKeys.putVerifyOtp,
      parameters: verifyPayload,
      method: "PUT",
    )
        .then((returnData) async {
      if (returnData == "No Internet") {
        Get.back();
        CustomDialogStack.showError(
          Get.context!,
          "Luvpay",
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
          "Luvpay",
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
      }

      final isInvalid = returnData["msg"].toString().toLowerCase().contains(
            "invalid",
          );
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

  Future<void> _verifyLocalInAppOtp() async {
    final submittedOtp = pinController.text;
    final generatedOtp = _generatedInAppOtp;
    final isExpired = paramOtpExp.inMilliseconds <= 0;

    if (generatedOtp == null || submittedOtp != generatedOtp || isExpired) {
      setState(() {
        _hasError = true;
      });

      CustomDialogStack.showError(
        Get.context!,
        isExpired ? "Code expired" : "Invalid OTP",
        isExpired
            ? "The generated code expired. Open OTP Generator to get a new code."
            : "Hmm, that code doesn’t look right. Please try again.",
        () {
          Get.back();
        },
      );
      return;
    }

    setState(() {
      _hasError = false;
    });

    Get.back();
    widget.arguments["callback"](int.parse(submittedOtp));
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

    Widget topNotice() {
      if (!_inAppOtpAvailable) {
        return SizedBox.shrink();
      }

      final noticeText = _isInAppMode
          ? "OTP Generator is active for this request. You can switch to SMS if needed."
          : "SMS OTP is selected for this request.";

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: brand.withOpacity(isDark ? 0.18 : 0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: brand.withOpacity(0.18)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.shield_rounded, color: brand, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: LuvpayText(
                text: noticeText,
                style: AppTextStyle.paragraph2(context).copyWith(height: 1.35),
                color: cs.onSurface,
              ),
            ),
          ],
        ),
      );
    }

    Widget methodSwitcher() {
      if (!_inAppOtpAvailable) {
        return SizedBox.shrink();
      }

      Widget option(OtpDeliveryMethod method, String label) {
        final isActive = _deliveryMethod == method;
        return Expanded(
          child: CustomButton(
            text: label,
            btnHeight: 46,
            btnColor: isActive ? brand : cs.surface,
            textColor: isActive ? cs.onPrimary : cs.onSurface,
            bordercolor: isActive ? brand : cs.outlineVariant.withOpacity(0.45),
            onPressed: () => _switchOtpMethod(method),
          ),
        );
      }

      return Row(
        children: [
          option(OtpDeliveryMethod.inApp, "OTP Generator"),
          SizedBox(width: 10),
          option(OtpDeliveryMethod.sms, "SMS"),
        ],
      );
    }

    Widget instructionText() {
      if (_isInAppMode) {
        return Center(
          child: LuvpayText(
            text:
                "Use the code generated on this device to approve this request.",
            textAlign: TextAlign.center,
            style: GoogleFonts.openSans(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              height: 18 / 14,
              color: cs.onSurfaceVariant,
            ),
          ),
        );
      }

      return RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          children: [
            TextSpan(
              text: "We have sent an OTP to your registered\nmobile number",
              style: GoogleFonts.openSans(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                height: 18 / 14,
                color: cs.onSurfaceVariant,
              ),
              children: <TextSpan>[
                TextSpan(
                  text: " +${widget.arguments["mobile_no"].toString()}",
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
      );
    }

    return CustomScaffoldV2(
      backgroundColor: cs.surface,
      useNormalBody: true,
      enableToolBar: true,
      onPressedLeading: _closeOtpScreen,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _cleanupOtpOverlays();
        }
      },
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
                              instructionText(),
                            ],
                          ),
                          spacing(height: 26),
                          methodSwitcher(),
                          if (_inAppOtpAvailable) spacing(height: 18),
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
                                        border: Border.all(
                                          color: brand,
                                          width: 2,
                                        ),
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
                            isInactive: _isInAppMode
                                ? _isRequestingOtp
                                : pinController.text.isEmpty ||
                                    pinController.text.length != 6,
                            text:
                                _isInAppMode ? "Open OTP Generator" : "Verify",
                            onPressed: _isInAppMode
                                ? _showInAppOtpGenerator
                                : verifyAccount,
                          ),
                          spacing(height: 34),
                          Center(
                            child: LuvpayText(
                              text: _isInAppMode
                                  ? "Generator code refreshes in"
                                  : "Didn’t receive any code?",
                              style: AppTextStyle.paragraph2(context),
                              color: cs.onSurface,
                            ),
                          ),
                          spacing(height: 6),
                          Center(
                            child: InkWell(
                              onTap: _isInAppMode
                                  ? _showInAppOtpGenerator
                                  : _isRequestingOtp
                                      ? null
                                      : paramOtpExp.inSeconds <= 0
                                          ? () {
                                              restartTimer();
                                              pinController.clear();
                                            }
                                          : null,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  LuvpayText(
                                    text: _isInAppMode
                                        ? "Open OTP Generator"
                                        : _isRequestingOtp
                                            ? "Requesting OTP"
                                            : paramOtpExp.inSeconds <= 0
                                                ? "Resend OTP"
                                                : "Resend OTP in",
                                    color: AppColorV2.lpBlueBrand,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  if (paramOtpExp.inSeconds > 0 || _isInAppMode)
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
    final safeDuration = d.isNegative
        ? Duration.zero
        : Duration(seconds: _displayRemainingSeconds(d));
    final minutes =
        safeDuration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds =
        safeDuration.inSeconds.remainder(60).toString().padLeft(2, '0');

    return "$minutes:$seconds";
  }

  int _displayRemainingSeconds(Duration duration, {int? maxSeconds}) {
    if (duration.inMilliseconds <= 0) {
      return 0;
    }

    final seconds = (duration.inMilliseconds + 999) ~/ 1000;
    if (maxSeconds == null) {
      return seconds;
    }

    return seconds.clamp(1, maxSeconds).toInt();
  }
}
