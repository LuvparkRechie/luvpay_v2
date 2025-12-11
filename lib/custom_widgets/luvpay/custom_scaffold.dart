import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:luvpay/custom_widgets/app_color_v2.dart';

import '../custom_text_v2.dart';
import 'custom_buttons.dart';

class CustomGradientBackground extends StatelessWidget {
  final Widget? child;
  final List<Color> gradientColors;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final double blurSigma;
  final Color? bodyColor;

  const CustomGradientBackground({
    super.key,
    this.child,
    this.gradientColors = const [Color(0xFF007BFF), Color(0xFF00BFA6)],
    this.borderRadius,
    this.padding,
    this.blurSigma = 0,
    this.bodyColor,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      width: double.infinity,
      height: double.infinity,
      padding: padding ?? EdgeInsets.zero,
      decoration: BoxDecoration(
        color: bodyColor ?? Colors.transparent,
        borderRadius: borderRadius,
      ),
      child: child,
    );

    if (blurSigma > 0) {
      content = ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: content,
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradientColors,
        ),
      ),
      child: content,
    );
  }
}

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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: onPopInvokedWithResult,
      canPop: canPop,
      child: Scaffold(
        key: scaffKey,
        extendBodyBehindAppBar: extendBodyBehindAppbar,
        drawerEnableOpenDragGesture: false,
        backgroundColor: backgroundColor ?? Colors.transparent,
        drawer: drawer,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        bottomNavigationBar: bottomNavigationBar,
        floatingActionButton: floatingButton,
        persistentFooterButtons: persistentFooterButtons,
        appBar: showAppBar ? (appBar ?? _buildDefaultAppBar(context)) : null,

        body:
            useNormalBody
                ? SafeArea(
                  bottom: false,
                  child: Padding(
                    padding:
                        padding ?? const EdgeInsets.fromLTRB(19, 20, 19, 0),
                    child: scaffoldBody,
                  ),
                )
                : Stack(
                  children: [
                    CustomGradientBackground(
                      blurSigma: 80,
                      gradientColors: [
                        AppColorV2.lpBlueBrand.withAlpha(150),
                        AppColorV2.background,
                        AppColorV2.background,
                        AppColorV2.background,
                        AppColorV2.background,
                      ],
                      bodyColor: Colors.transparent,
                      borderRadius:
                          removeBorderRadius
                              ? null
                              : const BorderRadius.only(
                                topLeft: Radius.circular(30),
                                topRight: Radius.circular(30),
                              ),
                      padding: EdgeInsets.zero,
                    ),
                    SafeArea(
                      bottom: false,
                      child: Padding(
                        padding:
                            padding ?? const EdgeInsets.fromLTRB(19, 20, 19, 0),
                        child: scaffoldBody,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  AppBar _buildDefaultAppBar(BuildContext context) {
    return AppBar(
      bottom: bottom,
      backgroundColor: appBarBackgroundColor ?? Colors.transparent,
      centerTitle: centerTitle ?? false,
      title: DefaultText(
        text: appBarTitle ?? "",
        style: AppTextStyle.h3,
        color: AppColorV2.background,
        maxLines: 1,
      ),
      leading:
          leading ??
          Padding(
            padding: const EdgeInsets.only(left: 14.0),
            child: Row(
              children: [
                CustomButtons.backCircle(
                  onPressed:
                      onPressedLeading ?? () => canPop ? Get.back() : null,
                  activeColor: AppColorV2.background,
                  activeIconColor: AppColorV2.primaryTextColor,
                ),
                if (leadingText != null)
                  DefaultText(
                    color: AppColorV2.background,
                    text: leadingText!,
                    style: AppTextStyle.h3_semibold,
                  ),
              ],
            ),
          ),
      leadingWidth: appBarLeadingWidth ?? 100,
      elevation: 0,
      toolbarHeight: enableToolBar ? 56 : 0,
      actions: appBarAction,
      systemOverlayStyle:
          systemOverlayStyle ??
          const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
          ),
    );
  }
}
