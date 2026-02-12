// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

import 'index.dart';
import 'package:luvpay/shared/widgets/colors.dart';
import 'package:luvpay/shared/widgets/luvpay_text.dart';

class SplashScreen extends GetView<SplashController> {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final surface = cs.surface;
    final subtleBorder = cs.outlineVariant.withOpacity(isDark ? 0.18 : 0.01);
    final shadow = Colors.black.withOpacity(isDark ? 0.35 : 0.08);

    return Scaffold(
      backgroundColor: surface,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.55, -0.55),
                  radius: 1.25,
                  colors: [
                    cs.surfaceVariant.withOpacity(isDark ? 0.55 : 0.75),
                    surface,
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            top: -110,
            left: -90,
            child: _GlowBlob(
              size: 260,
              color: AppColorV2.lpBlueBrand.withOpacity(isDark ? 0.16 : 0.10),
            ),
          ),
          Positioned(
            bottom: -130,
            right: -110,
            child: _GlowBlob(
              size: 300,
              color: AppColorV2.lpTealBrand.withOpacity(isDark ? 0.14 : 0.09),
            ),
          ),

          Positioned(
            top: 90,
            right: 30,
            child: _Dot(color: cs.onSurface.withOpacity(isDark ? 0.10 : 0.08)),
          ),
          Positioned(
            bottom: 120,
            left: 36,
            child: _Dot(color: cs.onSurface.withOpacity(isDark ? 0.10 : 0.07)),
          ),

          SafeArea(
            child: Center(
              child: ScaleTransition(
                scale: controller.animation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: surface.withOpacity(isDark ? 0.62 : 0.92),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: subtleBorder, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: shadow,
                              blurRadius: 28,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Image.asset("assets/images/luvpay.png", height: 72),
                          ],
                        ),
                      ),

                      const SizedBox(height: 22),

                      LuvpayText(
                        text: "luvpay",
                        style: AppTextStyle.h2_f26(context),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                      ),

                      const SizedBox(height: 6),

                      LuvpayText(
                        text: "Initializing secure session…",
                        style: AppTextStyle.paragraph2(context),
                        textAlign: TextAlign.center,
                        color: cs.onSurface.withOpacity(0.70),
                      ),

                      const SizedBox(height: 22),
                      RepaintBoundary(
                        child: Shimmer.fromColors(
                          baseColor: AppColorV2.lpBlueBrand.withOpacity(
                            isDark ? 0.22 : 0.28,
                          ),
                          highlightColor: (isDark
                                  ? AppColorV2.darkSurface2
                                  : Colors.grey[100]!)
                              .withOpacity(isDark ? 0.75 : 1.0),
                          child: Container(
                            width: 120,
                            height: 8,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color:
                                  isDark
                                      ? AppColorV2.darkSurface2
                                      : AppColorV2.inactiveButton,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      LuvpayText(
                        text: "Please wait",
                        style: AppTextStyle.body2(context),
                        textAlign: TextAlign.center,
                        color: cs.onSurface.withOpacity(0.55),
                      ),
                    ],
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

class _GlowBlob extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowBlob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
