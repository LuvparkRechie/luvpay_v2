// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_auto_size_text/flutter_auto_size_text.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:luvpay/custom_widgets/app_color_v2.dart';
import 'package:luvpay/custom_widgets/custom_button.dart';
import 'package:luvpay/custom_widgets/custom_text_v2.dart';
import 'package:luvpay/custom_widgets/loading.dart';

class CustomDialogStack {
  static bool _isSnackBarActive = false;

  static void _showBaseDialog(
    BuildContext context,
    String title,
    String subtitle,
    String image,
    VoidCallback leftButtonAction, {
    VoidCallback? rightButtonAction,
    String leftText = "Back",
    String rightText = "Confirm",
    TextAlign? textAlign,
    Color? leftBtnColor,
    Color? rightBtnColor,
    Color? leftTextColor,
    Color? rightTextColor,
    required bool showRightButton,
    bool isAllBlueColor = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return PopScope(
          canPop: false,
          child: Dialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 40,
              vertical: 24,
            ),
            backgroundColor: Colors.transparent,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(19, 30, 19, 19),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 30),
                      DefaultText(
                        text: title,
                        style: AppTextStyle.h2,
                        fontSize: 22,
                        maxLines: 1,
                      ),
                      SizedBox(height: 5),
                      AutoSizeText(
                        subtitle,
                        minFontSize: 12,
                        textAlign: textAlign ?? TextAlign.center,
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 18 / 14,
                          color: AppColorV2.bodyTextColor,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _dialogNeumorphicButton(
                              text: leftText,
                              onPressed: leftButtonAction,
                              fg:
                                  !showRightButton
                                      ? AppColorV2.background
                                      : (leftTextColor ??
                                          AppColorV2.lpBlueBrand),
                              bg:
                                  !showRightButton
                                      ? AppColorV2.lpBlueBrand
                                      : (leftBtnColor ??
                                          AppColorV2.lpBlueBrand.withAlpha(20)),
                            ),
                          ),
                          if (showRightButton) const SizedBox(width: 10),
                          if (showRightButton)
                            Expanded(
                              child: _dialogNeumorphicButton(
                                text: rightText,
                                onPressed: rightButtonAction!,
                                fg:
                                    isAllBlueColor
                                        ? AppColorV2.background
                                        : (rightTextColor ??
                                            AppColorV2.incorrectState),
                                bg:
                                    isAllBlueColor
                                        ? AppColorV2.lpBlueBrand
                                        : (rightBtnColor ??
                                            AppColorV2.incorrectState.withAlpha(
                                              20,
                                            )),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: -30,
                  left: 0,
                  right: 0,
                  child: Align(
                    alignment: Alignment.center,
                    child: SvgPicture.asset("assets/images/$image.svg"),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  showOneButtonRaw({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String image,
    required VoidCallback leftButtonAction,
    String leftText = "Back",
    TextAlign? textAlign,
    Color? leftBtnColor,
    Color? leftTextColor,
  }) {
    _showBaseDialog(
      context,
      title,
      subtitle,
      image,
      leftButtonAction,
      leftText: leftText,
      textAlign: textAlign,
      leftBtnColor: leftBtnColor,
      leftTextColor: leftTextColor,
      showRightButton: false,
    );
  }

  static void showConfirmationRaw({
    required BuildContext context,
    required String title,
    required String subtitle,
    required VoidCallback leftButtonAction,
    required VoidCallback rightButtonAction,

    String leftText = "Cancel",
    String rightText = "Confirm",
    TextAlign? textAlign,
    String? image,
    Color? leftBtnColor,
    Color? rightBtnColor,
    Color? leftTextColor,
    Color? rightTextColor,
  }) {
    _showBaseDialog(
      context,
      title,
      subtitle,
      image ?? "dialog_confirmation",
      leftButtonAction,
      rightButtonAction: rightButtonAction,
      leftText: leftText,
      rightText: rightText,

      leftTextColor: leftTextColor,
      rightTextColor: rightTextColor,
      showRightButton: true,
    );
  }

  static void showInfo(
    BuildContext context,
    String title,
    String subtitle,
    VoidCallback leftButtonAction, {
    String? image,
    String leftText = "Back",
  }) {
    _showBaseDialog(
      context,
      title,
      subtitle,
      image ?? "dialog_information",
      leftButtonAction,
      leftText: leftText,
      showRightButton: false,
    );
  }

  static void showSuccess(
    BuildContext context,
    String title,
    String subtitle,
    VoidCallback leftButtonAction, {
    String? image,
    String leftText = "Okay",
  }) {
    _showBaseDialog(
      context,
      title,
      subtitle,
      image ?? "dialog_success2",
      leftButtonAction,
      leftText: leftText,
      showRightButton: false,
    );
  }

  static void showError(
    BuildContext context,
    String title,
    String subtitle,
    VoidCallback leftButtonAction,
  ) {
    _showBaseDialog(
      context,
      title,
      subtitle,
      "dialog_notice",
      leftButtonAction,
      leftText: "Okay",
      showRightButton: false,
    );
  }

  static void showServerError(
    BuildContext context,
    VoidCallback leftButtonAction,
  ) {
    _showBaseDialog(
      context,
      "Server error",
      "Unable to process your\nrequest right now",
      "dialog_server_error",
      leftButtonAction,
      leftText: "Okay",
      showRightButton: false,
    );
  }

  static void showConnectionLost(
    BuildContext context,
    VoidCallback leftButtonAction,
  ) {
    _showBaseDialog(
      context,
      "Connnection lost",
      "No internet connection.\nTry again later.",
      "dialog_no_nets",
      leftButtonAction,
      leftText: "Okay",
      showRightButton: false,
    );
  }

  static void showConfirmation(
    BuildContext context,
    String title,
    String subtitle,
    VoidCallback leftButtonAction,
    VoidCallback rightButtonAction, {
    String? image,
    String leftText = "Cancel",
    String rightText = "Confirm",
    TextAlign? textAlign,
    Color? leftBtnColor,
    Color? rightBtnColor,
    Color? leftTextColor,
    Color? rightTextColor,
    bool isAllBlueColor = true,
  }) {
    _showBaseDialog(
      context,
      title,
      subtitle,
      image ?? "dialog_confirmation",
      leftButtonAction,
      rightButtonAction: rightButtonAction,
      leftText: leftText,
      rightText: rightText,
      textAlign: textAlign,
      leftBtnColor: leftBtnColor,
      rightBtnColor: rightBtnColor,
      leftTextColor: leftTextColor,
      rightTextColor: rightTextColor,
      showRightButton: true,
      isAllBlueColor: isAllBlueColor,
    );
  }

  static void showSnackBar(
    BuildContext context,
    String text,
    Color? color,
    VoidCallback? onTap,
  ) {
    if (_isSnackBarActive) return;

    _isSnackBarActive = true;

    final snackBar = SnackBar(
      backgroundColor: color ?? Colors.red,
      content: Text(text),
      duration: const Duration(seconds: 1),
      action: SnackBarAction(
        textColor: Colors.white,
        label: 'Okay',
        onPressed: () {
          if (onTap != null) {
            onTap();
          }
        },
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar).closed.then((_) {
      _isSnackBarActive = false;
    });
  }

  static void showLoading(BuildContext context, {String text = "Loading..."}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColorV2.bodyTextColor.withAlpha(50),
      builder: (context) {
        return Material(
          color: Colors.transparent,
          child: PopScope(
            canPop: false,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColorV2.background,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.10),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                  border: Border.all(
                    color: const Color(0xFF0F172A).withOpacity(.06),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    DefaultText(
                      text: text,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                      color: Colors.black.withOpacity(.70),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static void showLocationDialog(
    BuildContext context,
    String title,
    String paragraph,
    VoidCallback onTapConfirm, {
    Color? btnOkBackgroundColor,
    Color? btnOkTextColor,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return PopScope(
          canPop: false,
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 40,
              vertical: 24,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(19, 30, 19, 19),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 30),
                      DefaultText(
                        text: title,
                        style: AppTextStyle.h2,
                        fontSize: 22,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 5),
                      AutoSizeText(
                        paragraph,
                        minFontSize: 12,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 18 / 14,
                          color: AppColorV2.bodyTextColor,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: CustomButton(
                          text: "Enable location",
                          onPressed: onTapConfirm,
                          btnColor:
                              btnOkBackgroundColor ?? AppColorV2.lpBlueBrand,
                          textColor: btnOkTextColor ?? AppColorV2.background,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: -30,
                  left: 0,
                  right: 0,
                  child: Align(
                    alignment: Alignment.center,
                    child: SvgPicture.asset("assets/images/info.svg"),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static void showMapLoading(String title) {
    showDialog(
      context: Get.context!,
      barrierDismissible: false,
      builder: (context) {
        return PopScope(
          canPop: false,
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 40,
              vertical: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: 150,
                      width: MediaQuery.of(context).size.width,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(14),
                        ),
                        image: const DecorationImage(
                          image: AssetImage('assets/dashboard_icon/loadBg.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: Image.asset(
                        'assets/dashboard_icon/loading_map.gif',
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(14),
                    ),
                  ),
                  width: MediaQuery.of(context).size.width,
                  child: AutoSizeText(
                    "Getting nearest parking within \n$title, please wait...",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 18 / 14,
                      color: AppColorV2.bodyTextColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static void showUnderDevelopment(BuildContext context, VoidCallback onClose) {
    _showBaseDialog(
      context,
      "Under Development",
      "This feature is currently under development. Thank you for your patience.",
      "dialog_information",
      onClose,
      leftText: "Okay",
      showRightButton: false,
    );
  }

  static void showComingSoon(BuildContext context, VoidCallback onClose) {
    _showBaseDialog(
      context,
      "Coming Soon",
      "This feature isn’t available yet.",
      "dialog_information",
      onClose,
      leftText: "Okay",
      showRightButton: false,
    );
  }

  static Widget _dialogNeumorphicButton({
    required String text,
    required VoidCallback onPressed,
    required Color bg,
    required Color fg,
  }) {
    final radius = BorderRadius.circular(14);

    return NeumorphicButton(
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      style: NeumorphicStyle(
        color: bg,
        shape: NeumorphicShape.flat,
        boxShape: NeumorphicBoxShape.roundRect(radius),
        depth: 1.5,
        intensity: 0.45,
        surfaceIntensity: 0.12,
      ),
      child: SizedBox(
        height: 46,
        child: Center(
          child: DefaultText(
            text: text,
            color: fg,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
          ),
        ),
      ),
    );
  }
}
