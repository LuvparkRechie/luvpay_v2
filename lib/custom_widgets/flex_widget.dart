import 'package:flutter/material.dart';

class FlexWidget extends StatelessWidget {
  final double width;
  final double height;
  final Color color;
  final double constrainDivisor;
  final Axis direction;
  const FlexWidget({
    super.key,
    required this.width,
    required this.height,
    required this.color,
    required this.constrainDivisor,
    required this.direction,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      return Flex(
        direction: direction,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.max,
        children: List.generate(
            ((direction == Axis.horizontal
                        ? constraints.constrainWidth()
                        : constraints.constrainHeight()) /
                    constrainDivisor)
                .floor(),
            (index) => Container(
                  width: width,
                  height: height,
                  color: color,
                )),
      );
    });
  }
}
