// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../app_color_v2.dart';
import 'neumorphism.dart';

class CustomButtons extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color textColor;
  final Color backgroundColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final bool isActive;
  final IconData? icon;

  const CustomButtons({
    super.key,
    required this.text,
    required this.onPressed,
    this.textColor = Colors.blue,
    this.backgroundColor = Colors.transparent,
    this.borderRadius = 12.0,
    this.padding = const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
    this.isActive = true,
    this.icon,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final enabled = isActive && onPressed != null;

    final Color effectiveTextColor = enabled ? textColor : Colors.grey.shade400;

    final Color effectiveBgColor =
        enabled ? backgroundColor : Colors.grey.shade200;

    final r = BorderRadius.circular(borderRadius);

    final bool isCircle =
        padding == EdgeInsets.zero && (text.isEmpty || icon != null);

    final childWidget =
        text.isEmpty
            ? Icon(icon ?? Icons.circle, size: 20, color: effectiveTextColor)
            : Text(
              text,
              style: TextStyle(
                color: effectiveTextColor,
                fontWeight: FontWeight.w800,
              ),
            );

    return isCircle
        ? LuvNeuPress.circle(
          onTap: enabled ? onPressed : null,
          background: effectiveBgColor,
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
          background: effectiveBgColor,
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
