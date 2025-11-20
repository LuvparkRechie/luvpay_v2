import 'package:flutter/material.dart';
import 'package:luvpay/custom_widgets/app_color_v2.dart';

class CustomScaffold extends StatelessWidget {
  final Widget children;
  final AppBar? appBar;
  final Color? bodyColor;
  final Widget? bottomNavigationBar;
  final Widget? floatingButton;
  final bool canPop;
  const CustomScaffold({
    super.key,
    required this.children,
    this.appBar,
    this.bodyColor,
    this.canPop = true,
    this.bottomNavigationBar,
    this.floatingButton,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: canPop,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: AppColorV2.background,
        appBar: appBar ?? appBar,
        body: SafeArea(
          child: Container(
            width: MediaQuery.of(context).size.width,
            color: bodyColor ?? AppColorV2.background,
            height: MediaQuery.of(context).size.height,
            child: children,
          ),
        ),
        resizeToAvoidBottomInset: true,
        bottomNavigationBar: bottomNavigationBar ?? bottomNavigationBar,
        floatingActionButton: floatingButton,
      ),
    );
  }
}
