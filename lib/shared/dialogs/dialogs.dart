// ignore_for_file: deprecated_member_use

import 'package:flutter_auto_size_text/flutter_auto_size_text.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:luvpay/shared/widgets/colors.dart';
import 'package:luvpay/shared/widgets/luvpay_text.dart';

class CustomDialogStack {
  static bool _isSnackBarActive = false;

  static bool _trackedDialogLock = false;

  static Future<T?> _trackedShowDialog<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool barrierDismissible = false,
    Color? barrierColor,
  }) {
    if (_trackedDialogLock) return Future.value(null);

    _trackedDialogLock = true;

    final future = showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      builder: builder,
    );

    future.whenComplete(() {
      _trackedDialogLock = false;
    });

    return future;
  }

  static Future<T?> _plainShowDialog<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool barrierDismissible = false,
    Color? barrierColor,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      builder: builder,
    );
  }

  static void _showBaseDialogTracked(
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    _trackedShowDialog<void>(
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
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: cs.onSurface.withOpacity(isDark ? 0.12 : 0.06),
                      width: 0.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.35 : 0.10),
                        blurRadius: isDark ? 22 : 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 30),
                      LuvpayText(
                        text: title,
                        style: AppTextStyle.h2(context),
                        fontSize: 22,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 5),
                      AutoSizeText(
                        subtitle,
                        minFontSize: 12,
                        textAlign: textAlign ?? TextAlign.center,
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 18 / 14,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _dialogNeumorphicButton(
                              context: context,
                              text: leftText,
                              onPressed: leftButtonAction,
                              fg:
                                  !showRightButton
                                      ? cs.onPrimary
                                      : (leftTextColor ??
                                          AppColorV2.lpBlueBrand),
                              bg:
                                  !showRightButton
                                      ? AppColorV2.lpBlueBrand
                                      : (leftBtnColor ??
                                          AppColorV2.lpBlueBrand.withOpacity(
                                            0.12,
                                          )),
                            ),
                          ),
                          if (showRightButton) const SizedBox(width: 10),
                          if (showRightButton)
                            Expanded(
                              child: _dialogNeumorphicButton(
                                context: context,
                                text: rightText,
                                onPressed: rightButtonAction!,
                                fg:
                                    isAllBlueColor
                                        ? cs.onPrimary
                                        : (rightTextColor ??
                                            AppColorV2.incorrectState),
                                bg:
                                    isAllBlueColor
                                        ? AppColorV2.lpBlueBrand
                                        : (rightBtnColor ??
                                            AppColorV2.incorrectState
                                                .withOpacity(0.12)),
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
    _showBaseDialogTracked(
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
    _showBaseDialogTracked(
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
    _showBaseDialogTracked(
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
    _showBaseDialogTracked(
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
    _showBaseDialogTracked(
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
    _showBaseDialogTracked(
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
    _showBaseDialogTracked(
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

  static void showUnderDevelopment(BuildContext context, VoidCallback onClose) {
    _showBaseDialogTracked(
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
    _showBaseDialogTracked(
      context,
      "Coming Soon",
      "This feature isn’t available yet.",
      "dialog_information",
      onClose,
      leftText: "Okay",
      showRightButton: false,
    );
  }

  static void showSnackBar(
    BuildContext context,
    String text,
    Color? color,
    VoidCallback? onTap,
  ) {
    if (_isSnackBarActive) return;

    final cs = Theme.of(context).colorScheme;
    _isSnackBarActive = true;

    final snackBar = SnackBar(
      backgroundColor: color ?? cs.error,
      content: Text(text, style: TextStyle(color: cs.onError)),
      duration: const Duration(seconds: 1),
      action: SnackBarAction(
        textColor: cs.onError,
        label: 'Okay',
        onPressed: () {
          if (onTap != null) onTap();
        },
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar).closed.then((_) {
      _isSnackBarActive = false;
    });
  }

  static void showLoading(BuildContext context, {String text = "Loading..."}) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    _plainShowDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(isDark ? 0.55 : 0.25),
      builder: (context) {
        return Material(
          color: Colors.transparent,
          child: PopScope(
            canPop: false,
            // canPop: true,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.35 : 0.10),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                  border: Border.all(
                    color: cs.onSurface.withOpacity(isDark ? 0.12 : 0.06),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    LuvpayText(
                      text: text,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                      color: cs.onSurface.withOpacity(0.75),
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

  static Widget _dialogNeumorphicButton({
    required BuildContext context,
    required String text,
    required VoidCallback onPressed,
    required Color bg,
    required Color fg,
  }) {
    final radius = BorderRadius.circular(14);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return NeumorphicButton(
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      style: NeumorphicStyle(
        color: bg,
        shape: NeumorphicShape.flat,
        boxShape: NeumorphicBoxShape.roundRect(radius),
        depth: isDark ? 0.8 : 1.5,
        intensity: isDark ? 0.35 : 0.45,
        surfaceIntensity: isDark ? 0.10 : 0.12,
      ),
      child: SizedBox(
        height: 46,
        child: Center(
          child: LuvpayText(
            text: text,
            color: fg,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
          ),
        ),
      ),
    );
  }
}
