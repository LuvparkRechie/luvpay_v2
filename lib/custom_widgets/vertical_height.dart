import 'package:flutter/material.dart';

class VerticalHeight extends StatelessWidget {
  final double height;
  const VerticalHeight({super.key, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
    );
  }
}
