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
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColorV2.lpBlueBrand, AppColorV2.lpTealBrand],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.account_balance_wallet,
                  color: AppColorV2.background,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Welcome to LuvPay!",
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColorV2.primaryTextColor,
                ),
              ),
              const SizedBox(height: 12),
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
