import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:luvpay/custom_widgets/app_color_v2.dart';

class LpProfileAvatar extends StatelessWidget {
  final String base64Image;
  final double size;
  final double borderWidth;
  const LpProfileAvatar({
    super.key,
    required this.base64Image,
    required this.size,
    required this.borderWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          width: borderWidth,
          color: AppColorV2.lpBlueBrand.withAlpha(50),
        ),
      ),
      child: ClipOval(
        child: Container(
          height: size,
          width: size,
          decoration: BoxDecoration(shape: BoxShape.circle),
          child:
              base64Image.isEmpty
                  ? Image.asset(
                    "assets/images/d_unverified_img.png",
                    height: size * 0.8,
                  )
                  : Image.memory(base64Decode(base64Image), fit: BoxFit.cover),
        ),
      ),
    );
  }
}
