// ignore_for_file: deprecated_member_use

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:luvpay/shared/widgets/colors.dart';

import 'package:luvpay/shared/widgets/neumorphism.dart';
import 'anim.dart';
import 'luvpay_text.dart';

class CustomScaffoldV2 extends StatelessWidget {
  final AppBar? appBar;
  final Widget scaffoldBody;
  final Widget? bottomNavigationBar;
  final Widget? floatingButton;
  final bool canPop;
  final VoidCallback? onPressedLeading;
  final String? leadingText;
  final bool enableToolBar;
  final List<Widget>? appBarAction;
  final String? appBarTitle;
  final bool? centerTitle;
  final EdgeInsetsGeometry? padding;
  final PopInvokedWithResultCallback<dynamic>? onPopInvokedWithResult;
  final bool enableCustom;
  final Widget? drawer;
  final Key? scaffKey;
  final Color? backgroundColor;
  final Color? bodyColor;
  final SystemUiOverlayStyle? systemOverlayStyle;
  final bool removeBorderRadius;
  final bool extendBodyBehindAppbar;
  final Widget? leading;
  final List<Widget>? persistentFooterButtons;
  final Color? appBarBackgroundColor;
  final PreferredSizeWidget? bottom;
  final bool resizeToAvoidBottomInset;
  final double? appBarLeadingWidth;
  final bool showAppBar;
  final bool useNormalBody;

  const CustomScaffoldV2({
    super.key,
    this.appBar,
    required this.scaffoldBody,
    this.bottomNavigationBar,
    this.floatingButton,
    this.canPop = true,
    this.onPressedLeading,
    this.leadingText,
    this.enableToolBar = true,
    this.appBarAction,
    this.appBarTitle,
    this.centerTitle,
    this.padding,
    this.onPopInvokedWithResult,
    this.enableCustom = true,
    this.drawer,
    this.scaffKey,
    this.backgroundColor,
    this.bodyColor,
    this.systemOverlayStyle,
    this.removeBorderRadius = false,
    this.extendBodyBehindAppbar = true,
    this.leading,
    this.persistentFooterButtons,
    this.appBarBackgroundColor,
    this.bottom,
    this.resizeToAvoidBottomInset = true,
    this.appBarLeadingWidth,
    this.showAppBar = true,
    this.useNormalBody = false,
  });
  Color _safeIconColorOn(Color bg, ColorScheme cs) {
    final b = ThemeData.estimateBrightnessForColor(bg);
    return b == Brightness.light ? cs.onSurface : cs.onPrimary;
  }

  Color _stroke(ColorScheme cs, bool isDark) =>
      cs.onSurface.withOpacity(isDark ? 0.05 : 0.01);

  Color _appBarBg(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (appBarBackgroundColor != null) return appBarBackgroundColor!;
    return isDark ? cs.surface : cs.primary;
  }

  Color _appBarFg(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return isDark ? cs.onSurface : cs.onPrimary;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return PopScope(
      onPopInvokedWithResult: onPopInvokedWithResult,
      canPop: canPop,
      child: Scaffold(
        key: scaffKey,
        extendBodyBehindAppBar: extendBodyBehindAppbar,
        drawerEnableOpenDragGesture: false,
        backgroundColor: backgroundColor ?? cs.surface,
        drawer: drawer,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        bottomNavigationBar: bottomNavigationBar,
        floatingActionButton: floatingButton,
        persistentFooterButtons: persistentFooterButtons,
        appBar: showAppBar ? (appBar ?? _buildModernAppBar(context)) : null,
        body: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return LuvPayDiagonalLinesBackground(
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: padding ?? const EdgeInsets.all(24),
          child: scaffoldBody,
        ),
      ),
    );
  }

  AppBar _buildModernAppBar(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final bg = _appBarBg(context);
    final fg = _appBarFg(context);

    final iconBrightness =
        ThemeData.estimateBrightnessForColor(bg) == Brightness.dark
            ? Brightness.light
            : Brightness.dark;

    return AppBar(
      bottom: bottom,
      backgroundColor: bg,
      surfaceTintColor: Colors.transparent,
      centerTitle: centerTitle ?? true,
      title: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: LuvpayText(
          key: ValueKey(appBarTitle ?? ""),
          text: appBarTitle ?? "",
          style: AppTextStyle.h3(context).copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
          color: fg,
          maxLines: 1,
        ),
      ),
      iconTheme: IconThemeData(color: fg),
      actionsIconTheme: IconThemeData(color: fg),
      leading: leading ?? _buildModernLeading(context),
      leadingWidth: appBarLeadingWidth ?? 80,
      elevation: 0,
      toolbarHeight: enableToolBar ? 64 : 0,
      actions: appBarAction != null
          ? [
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: Row(children: appBarAction!),
              ),
            ]
          : null,
      shape: null,
      bottomOpacity: 1,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: _stroke(cs, isDark), width: 1),
          ),
        ),
      ),
      systemOverlayStyle: systemOverlayStyle ??
          SystemUiOverlayStyle(
            statusBarColor: bg,
            statusBarBrightness: iconBrightness == Brightness.light
                ? Brightness.dark
                : Brightness.light,
            statusBarIconBrightness: iconBrightness,
            systemNavigationBarColor: null,
            systemNavigationBarIconBrightness: null,
          ),
    );
  }

  Widget _buildModernLeading(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final bg = _appBarBg(context);
    final iconColor = _safeIconColorOn(bg, cs);

    final canGoBack = (canPop &&
        (Navigator.of(context).canPop() ||
            Get.key.currentState?.canPop() == true));

    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: Row(
        children: [
          NeoNavIcon.icon(
            size: 40,
            iconColor: AppColorV2.lpBlueBrand,
            padding: const EdgeInsets.all(8),
            iconSize: 20,
            iconData: Icons.arrow_back_ios_new_rounded,
            onTap: onPressedLeading ??
                () {
                  if (canGoBack) Get.back();
                },
          ),
          if (leadingText != null)
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: LuvpayText(
                color: iconColor,
                text: leadingText!,
                style: AppTextStyle.h3_semibold(
                  context,
                ).copyWith(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
        ],
      ),
    );
  }
}
