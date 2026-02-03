// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:luvpay/custom_widgets/app_color_v2.dart';
import '../../custom_widgets/luvpay/confetti.dart';

class DashboardController extends GetxController {
  final currentIndex = 0.obs;
  final pageController = PageController();
  final box = GetStorage();
  final notifCount = 0.obs;
  @override
  void onInit() {
    super.onInit();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFirstLogin();
    });
  }

  void changePage(int index) {
    currentIndex.value = index;
    pageController.jumpToPage(index);
  }

  void _checkFirstLogin() {
    final isFirstLogin = box.read('isFirstLogin') ?? true;
    if (!isFirstLogin) return;

    Get.to(
      () => CelebrationScreen(
        title: "Welcome to luvpay!",
        message:
            "This looks like your first time logging in on this device.\nStart exploring now.",
        buttonText: "Let's Go!",
        icon: Icons.waving_hand_rounded,
        iconColor: AppColorV2.lpBlueBrand,
        showConfetti: true,
        onButtonPressed: () {
          box.write('isFirstLogin', false);
          Get.back();
        },
      ),
      transition: Transition.fadeIn,
      duration: const Duration(milliseconds: 260),
    );
  }
}
