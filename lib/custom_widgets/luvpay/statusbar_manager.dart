import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:luvpay/custom_widgets/app_color_v2.dart';

class StatusBarManager {
  static const SystemUiOverlayStyle defaultLightStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  );

  static const SystemUiOverlayStyle _defaultDarkStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.black,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: Colors.black,
    systemNavigationBarIconBrightness: Brightness.light,
  );
  static SystemUiOverlayStyle get defaultStyle => defaultLightStyle;

  static void setStatusBarColor({
    Color? statusBarColor,
    Brightness? statusBarIconBrightness,
    Color? systemNavigationBarColor,
    Brightness? systemNavigationBarIconBrightness,
  }) {
    final currentStyle = SystemUiOverlayStyle.light;

    SystemChrome.setSystemUIOverlayStyle(
      currentStyle.copyWith(
        statusBarColor: statusBarColor ?? AppColorV2.lpBlueBrand,
        statusBarIconBrightness: statusBarIconBrightness ?? Brightness.light,
        systemNavigationBarColor: systemNavigationBarColor ?? Colors.white,
        systemNavigationBarIconBrightness:
            systemNavigationBarIconBrightness ?? Brightness.dark,
      ),
    );
  }

  static void resetToDefault() {
    SystemChrome.setSystemUIOverlayStyle(defaultStyle);
  }
}

class ConsistentStatusBarWrapper extends StatelessWidget {
  final Widget child;
  final SystemUiOverlayStyle? systemOverlayStyle;

  const ConsistentStatusBarWrapper({
    super.key,
    required this.child,
    this.systemOverlayStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final fallback =
        isDark
            ? StatusBarManager._defaultDarkStyle
            : StatusBarManager.defaultLightStyle.copyWith(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
              statusBarBrightness: Brightness.light,
            );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemOverlayStyle ?? fallback,
      child: child,
    );
  }
}
