import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:luvpay/custom_widgets/app_color_v2.dart';

class StatusBarManager {
  static const SystemUiOverlayStyle _defaultLightStyle = SystemUiOverlayStyle(
    statusBarColor: Color(0xFF0078FF),
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
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

  static SystemUiOverlayStyle get defaultStyle => _defaultLightStyle;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setSystemUIOverlayStyle(
        systemOverlayStyle ?? StatusBarManager.defaultStyle,
      );
    });

    return child;
  }
}
