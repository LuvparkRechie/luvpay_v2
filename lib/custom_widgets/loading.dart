import 'package:flutter/material.dart';
import 'package:luvpay/custom_widgets/app_color_v2.dart';

class LoadingCard extends StatelessWidget {
  final double size;
  final double iconSize;
  final double elevation;
  final Color backgroundColor;
  final Color progressColor;
  final Color progressBgColor;
  final double strokeWidth;
  final BorderRadius borderRadius;

  const LoadingCard({
    super.key,
    this.size = 90,
    this.iconSize = 35,
    this.elevation = 3,
    this.backgroundColor = Colors.white,
    this.progressColor = Colors.blue,
    this.progressBgColor = const Color(0xFFB3E5FC),
    this.strokeWidth = 5,
    this.borderRadius = const BorderRadius.all(Radius.circular(15)),
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Material(
            elevation: elevation,
            borderRadius: borderRadius,
            shadowColor: AppColorV2.primaryTextColor.withAlpha(80),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: borderRadius,
              ),
              child: Center(
                child: SizedBox(
                  width: iconSize,
                  height: iconSize,
                  child: CircularProgressIndicator.adaptive(
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    backgroundColor: progressBgColor,
                    strokeWidth: strokeWidth,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
