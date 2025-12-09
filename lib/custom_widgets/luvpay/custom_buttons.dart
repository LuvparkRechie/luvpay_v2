// ignore_for_file: deprecated_member_use

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../app_color_v2.dart';

class CustomButtons extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color textColor;
  final Color borderColor;
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
    this.borderColor = Colors.blue,
    this.backgroundColor = Colors.transparent,
    this.borderRadius = 8.0,
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
      borderColor: Colors.green,
      backgroundColor: Colors.green,
      borderRadius: 12.0,
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
      textColor: Colors.red,
      borderColor: Colors.red,
      backgroundColor: Colors.transparent,
      borderRadius: 12.0,
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
      textColor: isActive ? Colors.white : Colors.grey,
      borderColor: isActive ? Colors.blue : Colors.grey,
      backgroundColor: isActive ? Colors.blue : Colors.grey.shade300,
      borderRadius: 12.0,
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
      textColor: isActive ? Colors.white : Colors.grey,
      borderColor: isActive ? Colors.blue : Colors.grey,
      backgroundColor: isActive ? Colors.blue : Colors.grey.shade300,
      borderRadius: 12.0,
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
      borderColor: Colors.transparent,
      backgroundColor: isActive ? activeColor : inactiveColor.withOpacity(0.4),
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
      borderColor: Colors.transparent,
      backgroundColor: isActive ? activeColor : inactiveColor.withOpacity(0.2),
      borderRadius: size / 2,
      padding: EdgeInsets.zero,
      isActive: isActive,
      icon: Icons.arrow_back_ios_new_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color effectiveTextColor =
        isActive ? textColor : Colors.grey.shade400;

    final Color effectiveBorderColor =
        isActive ? borderColor : Colors.transparent;

    final Color effectiveBgColor =
        isActive ? backgroundColor : Colors.grey.shade200;

    return OutlinedButton(
      onPressed: isActive ? onPressed : null,
      style: OutlinedButton.styleFrom(
        backgroundColor: effectiveBgColor,
        foregroundColor: effectiveTextColor,
        side: BorderSide(color: effectiveBorderColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        padding: padding,
        minimumSize:
            padding is EdgeInsets && (padding as EdgeInsets).horizontal == 0
                ? Size(borderRadius * 2, borderRadius * 2)
                : null,
      ),
      child:
          text.isEmpty
              ? Icon(icon ?? Icons.circle, size: 20, color: effectiveTextColor)
              : Text(
                text,
                style: TextStyle(
                  color: effectiveTextColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
    );
  }
}

Widget iconWithBackground({
  required IconData icon,
  Color? backgroundColor,
  Color? iconColor,
  double? padding,
  double? iconSize,
  Color? shadowColor,
  double? blurRadius,
  Function()? onTap,
}) {
  return InkWell(
    highlightColor: Colors.transparent,
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.all(padding ?? 14),

      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor ?? AppColorV2.lpBlueBrand,
        boxShadow: [
          BoxShadow(
            color: (shadowColor ?? Colors.blueAccent).withOpacity(0.5),
            blurRadius: blurRadius ?? 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: iconColor ?? Colors.white, size: iconSize ?? 24),
    ),
  );
}
