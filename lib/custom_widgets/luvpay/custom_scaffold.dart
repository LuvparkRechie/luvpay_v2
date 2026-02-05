// ignore_for_file: deprecated_member_use

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:luvpay/custom_widgets/app_color_v2.dart';
import '../custom_text_v2.dart';

class CustomGradientBackground extends StatelessWidget {
  final Widget? child;
  final List<Color>? gradientColors;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final double blurSigma;
  final Color? bodyColor;

  final bool blendIntoStatusBar;

  const CustomGradientBackground({
    super.key,
    this.child,
    this.gradientColors,
    this.borderRadius,
    this.padding,
    this.blurSigma = 0,
    this.bodyColor,
    this.blendIntoStatusBar = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final fallbackGradient =
        isDark
            ? <Color>[
              cs.primary.withOpacity(0.25),
              cs.surface,
              cs.surface,
              cs.surface,
              cs.surface,
              cs.surface,
              cs.surface,
              cs.surface,
              cs.surface,
            ]
            : <Color>[
              AppColorV2.lpBlueBrand,
              cs.surface,
              cs.surface,
              cs.surface,
              cs.surface,
              cs.surface,
              cs.surface,
              cs.surface,
              cs.surface,
            ];

    final colors = gradientColors ?? fallbackGradient;

    final topColor = colors.isNotEmpty ? colors.first : cs.surface;
    final iconBrightness =
        ThemeData.estimateBrightnessForColor(topColor) == Brightness.dark
            ? Brightness.light
            : Brightness.dark;

    final statusBarBrightness =
        iconBrightness == Brightness.light ? Brightness.dark : Brightness.light;

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

    final gradientLayer = Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ),
      ),
      child: content,
    );

    if (!blendIntoStatusBar) return gradientLayer;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: iconBrightness,
        statusBarBrightness: statusBarBrightness,
      ),
      child: gradientLayer,
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
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (useNormalBody) {
      return SafeArea(
        bottom: false,
        child: Padding(
          padding: padding ?? const EdgeInsets.fromLTRB(19, 20, 19, 0),
          child: scaffoldBody,
        ),
      );
    }

    final radius =
        removeBorderRadius
            ? null
            : const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            );

    return Stack(
      children: [
        CustomGradientBackground(
          blurSigma: 40,
          gradientColors: [
            cs.primary.withOpacity(isDark ? 0.18 : 0.12),
            cs.surface,
            cs.surface,
            cs.surface,
            cs.surface,
            cs.surface,
          ],
          bodyColor: Colors.transparent,
          borderRadius: radius,
          padding: EdgeInsets.zero,
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: (backgroundColor ?? cs.surface).withOpacity(0.98),
              borderRadius: radius,
              boxShadow: [
                BoxShadow(
                  color: cs.shadow.withOpacity(isDark ? 0.25 : 0.08),
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
        child: DefaultText(
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
      actions:
          appBarAction != null
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
      systemOverlayStyle:
          systemOverlayStyle ??
          SystemUiOverlayStyle(
            statusBarColor: bg,
            statusBarBrightness:
                iconBrightness == Brightness.light
                    ? Brightness.dark
                    : Brightness.light,
            statusBarIconBrightness: iconBrightness,
            systemNavigationBarColor: null,
            systemNavigationBarIconBrightness: null,
          ),
    );
  }

  Widget _buildModernLeading(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final fg = _appBarFg(context);

    final chipBg = fg.withOpacity(isDark ? 0.10 : 0.14);
    final chipBorder = fg.withOpacity(isDark ? 0.18 : 0.20);

    return Padding(
      padding: const EdgeInsets.only(left: 16.0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: chipBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: chipBorder, width: 1),
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
                    color: fg,
                  ),
                ),
              ),
            ),
          ),
          if (leadingText != null)
            Padding(
              padding: const EdgeInsets.only(left: 12.0),
              child: DefaultText(
                color: fg,
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

  Color _stroke(ColorScheme cs, bool isDark) =>
      cs.onSurface.withOpacity(isDark ? 0.05 : 0.01);

  Color _bg(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return appBarBackgroundColor ?? (isDark ? cs.surface : cs.primary);
  }

  Color _fg(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return isDark ? cs.onSurface : cs.onPrimary;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      onPopInvokedWithResult: onPopInvokedWithResult,
      canPop: canPop,
      child: Scaffold(
        key: scaffKey,
        drawerEnableOpenDragGesture: false,
        backgroundColor: backgroundColor ?? cs.surface,
        drawer: drawer,
        bottomNavigationBar: bottomNavigationBar,
        floatingActionButton: floatingButton,
        body: NestedScrollView(
          physics: const BouncingScrollPhysics(),
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            final bg = _bg(context);
            final fg = _fg(context);

            final iconBrightness =
                ThemeData.estimateBrightnessForColor(bg) == Brightness.dark
                    ? Brightness.light
                    : Brightness.dark;

            return [
              if (showAppBar)
                SliverAppBar(
                  pinned: pinned,
                  floating: floating,
                  snap: snap,
                  stretch: stretch,
                  expandedHeight: expandedHeight,
                  toolbarHeight: toolbarHeight,
                  backgroundColor: bg,
                  surfaceTintColor: Colors.transparent,
                  leading: _buildSliverLeading(context),
                  leadingWidth: appBarLeadingWidth ?? 80,
                  title:
                      (centerTitle ?? true)
                          ? AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child:
                                innerBoxIsScrolled
                                    ? DefaultText(
                                      key: ValueKey(appBarTitle ?? ""),
                                      text: appBarTitle ?? "",
                                      style: AppTextStyle.h3(context).copyWith(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: -0.3,
                                      ),
                                      color: fg,
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
                  flexibleSpace: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: _stroke(cs, isDark),
                          width: 1,
                        ),
                      ),
                    ),
                    child: flexibleSpace,
                  ),
                  elevation: 0,
                  shape: null,
                  systemOverlayStyle:
                      systemOverlayStyle ??
                      SystemUiOverlayStyle(
                        statusBarColor: bg,
                        statusBarBrightness:
                            iconBrightness == Brightness.light
                                ? Brightness.dark
                                : Brightness.light,
                        statusBarIconBrightness: iconBrightness,
                      ),
                ),
            ];
          },
          body: Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: cs.shadow.withOpacity(isDark ? 0.25 : 0.10),
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
                  const SliverPadding(padding: EdgeInsets.only(top: 16)),
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
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final fg = _fg(context);
    final chipBg = fg.withOpacity(isDark ? 0.10 : 0.14);
    final chipBorder = fg.withOpacity(isDark ? 0.18 : 0.20);

    return Padding(
      padding: const EdgeInsets.only(left: 16.0),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: chipBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: chipBorder, width: 1),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onPressedLeading ?? () => canPop ? Get.back() : null,
            borderRadius: BorderRadius.circular(12),
            child: Center(
              child: Icon(Icons.arrow_back_ios_new_rounded, color: fg),
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
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: margin ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? cs.surface,
        borderRadius: borderRadius ?? BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(isDark ? 0.28 : 0.12),
            blurRadius: 40,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: cs.onSurface.withOpacity(isDark ? 0.12 : 0.06),
          width: 1,
        ),
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
                  color: cs.onSurface.withOpacity(isDark ? 0.25 : 0.15),
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
