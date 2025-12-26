// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:luvpay/custom_widgets/app_color_v2.dart';
import '../custom_text_v2.dart';

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
    this.gradientColors = const [
      Color(0xFF0078FF),
      Color(0xFFFFFFFF),
      Color(0xFFFFFFFF),
      Color(0xFFFFFFFF),
      Color(0xFFFFFFFF),
      Color(0xFFFFFFFF),
      Color(0xFFFFFFFF),
      Color(0xFFFFFFFF),
      Color(0xFFFFFFFF),
    ],
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
        appBar: showAppBar ? (appBar ?? _buildModernAppBar(context)) : null,
        body: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (useNormalBody) {
      return SafeArea(
        bottom: false,
        child: Padding(
          padding: padding ?? const EdgeInsets.fromLTRB(19, 20, 19, 0),
          child: scaffoldBody,
        ),
      );
    }

    return Stack(
      children: [
        CustomGradientBackground(
          blurSigma: 40,
          gradientColors: [
            AppColorV2.lpBlueBrand.withAlpha(40),
            AppColorV2.background,
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
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
          padding: EdgeInsets.zero,
        ),

        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: AppColorV2.background.withOpacity(0.98),
              borderRadius:
                  removeBorderRadius
                      ? null
                      : const BorderRadius.only(
                        topLeft: Radius.circular(28),
                        topRight: Radius.circular(28),
                      ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
          ),
        ),

        SafeArea(
          bottom: false,
          child: Padding(
            padding: padding ?? const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: scaffoldBody,
          ),
        ),
      ],
    );
  }

  AppBar _buildModernAppBar(BuildContext context) {
    return AppBar(
      bottom: bottom,
      backgroundColor: appBarBackgroundColor ?? AppColorV2.lpBlueBrand,
      centerTitle: centerTitle ?? true,
      title: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: DefaultText(
          key: ValueKey(appBarTitle ?? ""),
          text: appBarTitle ?? "",
          style: AppTextStyle.h3.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
          color: AppColorV2.background,
          maxLines: 1,
        ),
      ),
      leading: leading ?? _buildModernLeading(context),
      leadingWidth: appBarLeadingWidth ?? 80,
      elevation: 0,
      toolbarHeight: enableToolBar ? 64 : 0,
      actions:
          appBarAction != null
              ? [
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Row(children: appBarAction!),
                ),
              ]
              : null,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      systemOverlayStyle:
          systemOverlayStyle ??
          SystemUiOverlayStyle.light.copyWith(
            statusBarColor: AppColorV2.lpBlueBrand,
            statusBarIconBrightness: Brightness.light,
          ),
    );
  }

  Widget _buildModernLeading(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: onPressedLeading ?? () => canPop ? Get.back() : null,
                borderRadius: BorderRadius.circular(12),
                child: Center(
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 20,
                    color: AppColorV2.background,
                  ),
                ),
              ),
            ),
          ),
          if (leadingText != null)
            Padding(
              padding: const EdgeInsets.only(left: 12.0),
              child: DefaultText(
                color: AppColorV2.background,
                text: leadingText!,
                style: AppTextStyle.h3_semibold.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class CustomSliverScaffold extends StatelessWidget {
  final Widget? flexibleSpace;
  final List<Widget> slivers;
  final Widget? bottomNavigationBar;
  final Widget? floatingButton;
  final bool canPop;
  final VoidCallback? onPressedLeading;
  final String? leadingText;
  final bool enableToolBar;
  final List<Widget>? appBarAction;
  final String? appBarTitle;
  final bool? centerTitle;
  final PopInvokedWithResultCallback<dynamic>? onPopInvokedWithResult;
  final Widget? drawer;
  final Key? scaffKey;
  final Color? backgroundColor;
  final SystemUiOverlayStyle? systemOverlayStyle;
  final bool pinned;
  final bool floating;
  final bool snap;
  final bool stretch;
  final double expandedHeight;
  final double toolbarHeight;
  final Color? appBarBackgroundColor;
  final double? appBarLeadingWidth;
  final bool showAppBar;

  const CustomSliverScaffold({
    super.key,
    this.flexibleSpace,
    required this.slivers,
    this.bottomNavigationBar,
    this.floatingButton,
    this.canPop = true,
    this.onPressedLeading,
    this.leadingText,
    this.enableToolBar = true,
    this.appBarAction,
    this.appBarTitle,
    this.centerTitle,
    this.onPopInvokedWithResult,
    this.drawer,
    this.scaffKey,
    this.backgroundColor,
    this.systemOverlayStyle,
    this.pinned = true,
    this.floating = false,
    this.snap = false,
    this.stretch = false,
    this.expandedHeight = 180,
    this.toolbarHeight = 64,
    this.appBarBackgroundColor,
    this.appBarLeadingWidth,
    this.showAppBar = true,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: onPopInvokedWithResult,
      canPop: canPop,
      child: Scaffold(
        key: scaffKey,
        drawerEnableOpenDragGesture: false,
        backgroundColor: backgroundColor ?? Colors.white,
        drawer: drawer,
        bottomNavigationBar: bottomNavigationBar,
        floatingActionButton: floatingButton,
        body: NestedScrollView(
          physics: const BouncingScrollPhysics(),
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              if (showAppBar)
                SliverAppBar(
                  pinned: pinned,
                  floating: floating,
                  snap: snap,
                  stretch: stretch,
                  expandedHeight: expandedHeight,
                  toolbarHeight: toolbarHeight,
                  backgroundColor:
                      appBarBackgroundColor ?? AppColorV2.lpBlueBrand,
                  leading: _buildSliverLeading(context),
                  leadingWidth: appBarLeadingWidth ?? 80,
                  title:
                      centerTitle ?? true
                          ? AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child:
                                innerBoxIsScrolled
                                    ? DefaultText(
                                      key: ValueKey(appBarTitle ?? ""),
                                      text: appBarTitle ?? "",
                                      style: AppTextStyle.h3.copyWith(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: -0.3,
                                      ),
                                      color: AppColorV2.background,
                                      maxLines: 1,
                                    )
                                    : const SizedBox.shrink(),
                          )
                          : null,
                  centerTitle: centerTitle ?? true,
                  actions:
                      appBarAction != null
                          ? [
                            Container(
                              margin: const EdgeInsets.only(right: 16),
                              child: Row(children: appBarAction!),
                            ),
                          ]
                          : null,
                  flexibleSpace: flexibleSpace,
                  elevation: 0,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  systemOverlayStyle:
                      systemOverlayStyle ??
                      SystemUiOverlayStyle.light.copyWith(
                        statusBarColor: AppColorV2.lpBlueBrand,
                        statusBarIconBrightness: Brightness.light,
                      ),
                ),
            ];
          },
          body: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 30,
                  spreadRadius: 0,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverPadding(padding: const EdgeInsets.only(top: 16)),
                  ...slivers,
                  SliverPadding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).padding.bottom + 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSliverLeading(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onPressedLeading ?? () => canPop ? Get.back() : null,
            borderRadius: BorderRadius.circular(12),
            child: Center(
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColorV2.background,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CozyModalOverlay extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final BorderRadiusGeometry? borderRadius;
  final bool showHandle;
  final EdgeInsetsGeometry? margin;

  const CozyModalOverlay({
    super.key,
    required this.child,
    this.backgroundColor,
    this.borderRadius,
    this.showHandle = true,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: borderRadius ?? BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColorV2.primaryTextColor.withAlpha(20),
            blurRadius: 40,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showHandle)
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          child,
        ],
      ),
    );
  }
}
