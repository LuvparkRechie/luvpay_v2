import 'package:flutter/material.dart';
import 'package:luvpay/custom_widgets/app_color_v2.dart';

class CustomScrollbarSingleChild extends StatefulWidget {
  final bool isSingleChildScrollViewEnabled;
  final EdgeInsetsGeometry? padding;
  final Widget child;

  const CustomScrollbarSingleChild({
    Key? key,
    required this.child,
    this.isSingleChildScrollViewEnabled = false,
    this.padding,
  }) : super(key: key);

  @override
  State<CustomScrollbarSingleChild> createState() =>
      _CustomScrollbarSingleChildState();
}

class _CustomScrollbarSingleChildState
    extends State<CustomScrollbarSingleChild> {
  @override
  Widget build(BuildContext context) {
    return RawScrollbar(
      thumbColor: AppColorV2.lpBlueBrand.withAlpha(80),
      radius: Radius.circular(8),
      thickness: 5,
      child:
          widget.isSingleChildScrollViewEnabled
              ? SingleChildScrollView(
                padding: widget.padding ?? EdgeInsets.fromLTRB(19, 20, 19, 0),
                physics: BouncingScrollPhysics(),
                child: widget.child,
              )
              : widget.child,
    );
  }
}
