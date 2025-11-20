import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:luvpay/custom_widgets/app_color_v2.dart';
import 'package:luvpay/custom_widgets/custom_text_v2.dart';

class CustomScaffoldV2 extends StatelessWidget {
  final AppBar? appBar;
  final Color? bodyColor;
  final Widget? bottomNavigationBar;
  final Widget? floatingButton;
  final bool? canPop;
  final Widget scaffoldBody;
  final double? appBarLeadingWidth;
  final VoidCallback? onPressedLeading;
  final String? leadingText;
  final bool enableToolBar;
  final List<Widget>? appBarAction;
  final String? appBarTitle;
  final bool? centerTitle;
  final EdgeInsetsGeometry? padding;
  final PopInvokedWithResultCallback<dynamic>? onPopInvokedWithResult;
  final bool? enableCustom;
  final Widget? drawer;
  final Key? scaffKey;
  final Color? backgroundColor;
  final SystemUiOverlayStyle? systemOverlayStyle;
  final bool? removeBorderRadius;
  final bool? extendBodyBehindAppbar;
  final Widget? leading;
  final List<Widget>? persistentFooterButtons;
  final Color? appBarBackgroundColor;
  final PreferredSizeWidget? bottom;
  final bool? resizeToAvoidBottomInset;
  const CustomScaffoldV2({
    super.key,
    this.appBar,
    this.bodyColor,
    this.bottomNavigationBar,
    this.floatingButton,
    this.canPop = true,
    required this.scaffoldBody,
    this.appBarLeadingWidth,
    this.onPressedLeading,
    this.leadingText,
    required this.enableToolBar,
    this.appBarAction,
    this.appBarTitle,
    this.centerTitle,
    this.padding,
    this.onPopInvokedWithResult,
    this.enableCustom = true,
    this.drawer,
    this.scaffKey,
    this.backgroundColor,
    this.systemOverlayStyle,
    this.removeBorderRadius = false,
    this.leading,
    this.persistentFooterButtons,
    this.appBarBackgroundColor,
    this.extendBodyBehindAppbar = false,
    this.bottom,
    this.resizeToAvoidBottomInset,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: onPopInvokedWithResult,
      canPop: canPop ?? true,
      child: Scaffold(
        extendBodyBehindAppBar: extendBodyBehindAppbar!,
        persistentFooterAlignment: AlignmentDirectional.bottomCenter,
        drawerEnableOpenDragGesture: false,
        backgroundColor: backgroundColor,
        key: scaffKey,
        drawer: drawer,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset ?? true,
        bottomNavigationBar: bottomNavigationBar ?? bottomNavigationBar,
        floatingActionButton: floatingButton,
        persistentFooterButtons: persistentFooterButtons,
        appBar:
            appBar ??
            AppBar(
              bottom: bottom,
              backgroundColor: appBarBackgroundColor,
              centerTitle: centerTitle ?? true,
              title: DefaultText(
                text: appBarTitle ?? "",
                style: AppTextStyle.h3,
                color: AppColorV2.background,
                maxLines: 1,
              ),
              leading:
                  leading ??
                  IconButton(
                    onPressed:
                        onPressedLeading ??
                        () {
                          if (canPop!) {
                            Get.back();
                          }
                        },
                    icon: Row(
                      children: [
                        Icon(CupertinoIcons.back, color: AppColorV2.background),
                        DefaultText(
                          color: AppColorV2.background,
                          text: leadingText ?? "Back",
                          style: AppTextStyle.h3_semibold,
                          height: 20 / 16,
                        ),
                      ],
                    ),
                  ),
              leadingWidth: appBarLeadingWidth ?? 100,
              elevation: 0,
              toolbarHeight: enableToolBar == false ? 0 : 56.0,
              actions: appBarAction,
              systemOverlayStyle: systemOverlayStyle,
            ),
        body: MediaQuery(
          data: MediaQuery.of(
            Get.context!,
          ).copyWith(textScaler: TextScaler.linear(1)),
          child:
              enableCustom!
                  ? Container(
                    width: double.infinity,
                    height: double.infinity,
                    color:
                        removeBorderRadius == true
                            ? null
                            : AppColorV2.lpBlueBrand,
                    child: Container(
                      padding: padding ?? EdgeInsets.fromLTRB(19, 20, 19, 0),
                      decoration: BoxDecoration(
                        color: bodyColor ?? AppColorV2.background,
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(30),
                          topLeft: Radius.circular(30),
                        ),
                      ),
                      width: double.infinity,
                      height: double.infinity,
                      child: scaffoldBody,
                    ),
                  )
                  : scaffoldBody,
        ),
      ),
    );
  }
}
