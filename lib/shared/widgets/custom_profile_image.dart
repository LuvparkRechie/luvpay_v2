import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:luvpay/shared/widgets/colors.dart';

import 'neumorphism.dart';

class LpProfileAvatar extends StatelessWidget {
  final ImageProvider? imageProvider;
  final double size;
  final double borderWidth;

  const LpProfileAvatar({
    super.key,
    required this.imageProvider,
    required this.size,
    required this.borderWidth,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = AppColorV2.lpBlueBrand.withOpacity(0.25);

    return Neumorphic(
      style: LuvNeu.circle(
        color: AppColorV2.background,
        borderColor: borderColor,
        borderWidth: borderWidth,
      ),
      child: SizedBox(
        width: size,
        height: size,
        child: ClipOval(
          child:
              imageProvider == null
                  ? Image.asset(
                    "assets/images/d_unverified_img.png",
                    fit: BoxFit.cover,
                  )
                  : Image(
                    image: imageProvider!,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                  ),
        ),
      ),
    );
  }
}
