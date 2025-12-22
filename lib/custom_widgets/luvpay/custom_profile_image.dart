import 'package:flutter/material.dart';
import 'package:luvpay/custom_widgets/app_color_v2.dart';

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
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          width: borderWidth,
          color: AppColorV2.lpBlueBrand.withAlpha(50),
        ),
      ),
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
    );
  }
}
