// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'index.dart';

class SplashScreen extends GetView<SplashController> {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
                  color: cs.onBackground,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Your digital wallet is ready to use",
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: cs.onBackground.withOpacity(0.75),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
