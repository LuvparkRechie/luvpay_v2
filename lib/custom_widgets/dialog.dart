import 'package:flutter/material.dart';

// ignore: must_be_immutable
class CustomDialogPage extends StatelessWidget {
  late Color? color;
  late Widget child;
  CustomDialogPage({super.key, this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        color: color,
        child: child,
      ),
    );
  }
}
