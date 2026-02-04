// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../app_color_v2.dart';
import 'neumorphism.dart';

class CustomButtons extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;

  final Color textColor;
  final Color backgroundColor;

  final Color? darkTextColor;
  final Color? darkBackgroundColor;

  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final bool isActive;
  final IconData? icon;
  final double iconSize;
  final double gap;

  final bool adaptive;

  const CustomButtons({
    super.key,
    required this.text,
    required this.onPressed,
    this.textColor = Colors.blue,
    this.backgroundColor = Colors.transparent,
    this.darkTextColor,
    this.darkBackgroundColor,
    this.borderRadius = 12.0,
    this.padding = const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
    this.isActive = true,
    this.icon,
    this.iconSize = 18,
    this.gap = 10,
    this.adaptive = true,
  });

  factory CustomButtons.yes({
    required String text,
    required VoidCallback onPressed,
    bool isActive = true,
  }) {
    return CustomButtons(
      text: text,
      onPressed: isActive ? onPressed : null,
      textColor: Colors.white,
      backgroundColor: Colors.green,
      borderRadius: 14.0,
      isActive: isActive,
      adaptive: true,
      darkTextColor: Colors.white,
      darkBackgroundColor: Colors.green,
    );
  }

  factory CustomButtons.no({
    required String text,
    required VoidCallback onPressed,
    bool isActive = true,
  }) {
    return CustomButtons(
      text: text,
      onPressed: isActive ? onPressed : null,
      textColor: AppColorV2.incorrectState,
      backgroundColor: AppColorV2.background,
      borderRadius: 14.0,
      isActive: isActive,
      adaptive: true,
      darkTextColor: AppColorV2.incorrectState,
      darkBackgroundColor: AppColorV2.background,
    );
  }

  factory CustomButtons.general({
    required String text,
    required VoidCallback onPressed,
    bool isActive = true,
  }) {
    return CustomButtons(
      text: text,
      onPressed: isActive ? onPressed : null,
      textColor: Colors.white,
      backgroundColor: isActive ? AppColorV2.lpBlueBrand : Colors.grey.shade300,
      borderRadius: 14.0,
      isActive: isActive,
      adaptive: true,
      darkTextColor: Colors.white,
      darkBackgroundColor:
          isActive ? AppColorV2.lpBlueBrand : Colors.grey.shade600,
    );
  }

  factory CustomButtons.next({
    required VoidCallback onPressed,
    bool isActive = true,
  }) {
    return CustomButtons(
      text: "",
      onPressed: isActive ? onPressed : null,
      textColor: Colors.white,
      backgroundColor: isActive ? AppColorV2.lpBlueBrand : Colors.grey.shade300,
      borderRadius: 14.0,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      isActive: isActive,
      icon: Icons.arrow_forward_ios_rounded,
      adaptive: true,
      darkTextColor: Colors.white,
      darkBackgroundColor:
          isActive ? AppColorV2.lpBlueBrand : Colors.grey.shade600,
    );
  }

  factory CustomButtons.nextCircle({
    required VoidCallback onPressed,
    bool isActive = true,
    double size = 52,
    Color activeColor = Colors.blue,
    Color inactiveColor = Colors.grey,
    Color activeIconColor = Colors.white,
    Color inactiveIconColor = Colors.white54,
  }) {
    return CustomButtons(
      text: "",
      onPressed: isActive ? onPressed : null,
      textColor: isActive ? activeIconColor : inactiveIconColor,
      backgroundColor: isActive ? activeColor : inactiveColor.withOpacity(0.35),
      borderRadius: size / 2,
      padding: EdgeInsets.zero,
      isActive: isActive,
      icon: Icons.arrow_forward_ios_rounded,
      adaptive: true,
      darkTextColor: isActive ? activeIconColor : inactiveIconColor,
      darkBackgroundColor:
          isActive ? activeColor : inactiveColor.withOpacity(0.35),
    );
  }

  factory CustomButtons.backCircle({
    required VoidCallback onPressed,
    bool isActive = true,
    double size = 52,
    Color activeColor = Colors.black12,
    Color inactiveColor = Colors.grey,
    Color activeIconColor = Colors.black,
    Color inactiveIconColor = Colors.grey,
  }) {
    return CustomButtons(
      text: "",
      onPressed: isActive ? onPressed : null,
      textColor: isActive ? activeIconColor : inactiveIconColor,
      backgroundColor: isActive ? activeColor : inactiveColor.withOpacity(0.25),
      borderRadius: size / 2,
      padding: EdgeInsets.zero,
      isActive: isActive,
      icon: Icons.arrow_back_ios_new_rounded,
      adaptive: true,
      darkTextColor: isActive ? activeIconColor : inactiveIconColor,
      darkBackgroundColor:
          isActive ? activeColor : inactiveColor.withOpacity(0.25),
    );
  }
  factory CustomButtons.cta({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,

    required Color lightBg,
    required Color lightFg,

    required Color darkBg,
    required Color darkFg,

    bool isActive = true,
    double borderRadius = 30,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
      horizontal: 18,
      vertical: 14,
    ),
    double iconSize = 20,
    double gap = 10,
  }) {
    return CustomButtons(
      text: text,
      icon: icon,
      onPressed: isActive ? onPressed : null,
      isActive: isActive,
      backgroundColor: lightBg,
      textColor: lightFg,
      darkBackgroundColor: darkBg,
      darkTextColor: darkFg,
      borderRadius: borderRadius,
      padding: padding,
      iconSize: iconSize,
      gap: gap,
      adaptive: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final enabled = isActive && onPressed != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bg = enabled ? backgroundColor : Colors.grey.shade200;
    Color fg = enabled ? textColor : Colors.grey.shade400;

    if (adaptive && isDark) {
      if (darkBackgroundColor != null) bg = enabled ? darkBackgroundColor! : bg;
      if (darkTextColor != null) fg = enabled ? darkTextColor! : fg;
    }

    final r = BorderRadius.circular(borderRadius);

    final bool isCircle =
        padding == EdgeInsets.zero && (text.isEmpty || icon != null);

    final childWidget =
        text.isEmpty
            ? Icon(icon ?? Icons.circle, size: iconSize, color: fg)
            : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: iconSize, color: fg),
                  SizedBox(width: gap),
                ],
                Text(
                  text,
                  style: TextStyle(color: fg, fontWeight: FontWeight.w800),
                ),
              ],
            );

    return isCircle
        ? LuvNeuPress.circle(
          onTap: enabled ? onPressed : null,
          background: bg,
          borderColor:
              (textColor == AppColorV2.incorrectState)
                  ? AppColorV2.incorrectState.withOpacity(0.18)
                  : null,
          child: SizedBox(
            width: borderRadius * 2,
            height: borderRadius * 2,
            child: Center(child: childWidget),
          ),
        )
        : LuvNeuPress.rectangle(
          radius: r,
          onTap: enabled ? onPressed : null,
          background: bg,
          borderColor:
              (textColor == AppColorV2.incorrectState)
                  ? AppColorV2.incorrectState.withOpacity(0.18)
                  : null,
          child: Padding(padding: padding, child: Center(child: childWidget)),
        );
  }
}

Widget iconWithBackground({
  required IconData icon,
  Color? backgroundColor,
  Color? iconColor,
  double? padding,
  double? iconSize,
  Function()? onTap,
}) {
  final size = ((padding ?? 14) * 2) + (iconSize ?? 24);

  return LuvNeuPress.circle(
    onTap: onTap,
    background: backgroundColor ?? AppColorV2.lpBlueBrand,
    borderColor: null,
    child: SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Icon(
          icon,
          color: iconColor ?? Colors.white,
          size: iconSize ?? 24,
        ),
      ),
    ),
  );
}
