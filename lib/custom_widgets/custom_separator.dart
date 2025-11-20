import 'package:flutter/material.dart';

class MySeparator extends StatelessWidget {
  final double height;
  final double? width;
  final Color? color;

  const MySeparator(
      {super.key, this.width, this.height = 1, this.color = Colors.black});

  @override
  Widget build(BuildContext context) {
    final boxWidth = MediaQuery.of(context).size.width;
    const dashWidth = 5.0;
    final dashHeight = height;
    final dashCount = (boxWidth / (2 * dashWidth)).floor();
    return Padding(
      padding: const EdgeInsets.only(left: 5.0, right: 5.0),
      child: Flex(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        direction: Axis.horizontal,
        children: List.generate(dashCount, (_) {
          return SizedBox(
            width: dashWidth,
            height: dashHeight,
            child: DecoratedBox(
              decoration: BoxDecoration(color: color!),
            ),
          );
        }),
      ),
    );
  }
}

class DynamicDashLine extends StatelessWidget {
  final Color color;
  final double height;
  final double dashWidth;
  final double dashGap;

  const DynamicDashLine({
    required this.color,
    this.height = 1,
    this.dashWidth = 3,
    this.dashGap = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          double contWidht = constraints.maxWidth;
          final dashCount = (contWidht / (dashWidth + dashGap)).floor();
          final dashLine = Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(dashCount, (_) {
              return SizedBox(
                width: dashWidth,
                height: height,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: color),
                ),
              );
            }),
          );

          return dashLine;
        },
      ),
    );
  }
}
