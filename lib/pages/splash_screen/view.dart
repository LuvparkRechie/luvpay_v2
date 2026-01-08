import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:luvpay/custom_widgets/app_color_v2.dart';

import 'index.dart';

class SplashScreen extends GetView<SplashController> {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScaleTransition(
        scale: controller.animation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset("assets/images/luvpay.png", height: 80),
              const SizedBox(height: 24),
              Text(
                "Welcome to luvpay!",
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColorV2.primaryTextColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Your digital wallet is ready to use",
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: AppColorV2.bodyTextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
