import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class DashboardController extends GetxController {
  final currentIndex = 0.obs;
  final pageController = PageController();
  final box = GetStorage();

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
    final isFirstLogin = box.read('isFirstLogin') ?? false;

    debugPrint('CHECK isFirstLogin = $isFirstLogin');

    if (isFirstLogin) {
      _showWelcomePopup();
      box.write('isFirstLogin', false);
    }
  }

  void _showWelcomePopup() {
    Get.dialog(
      AlertDialog(
        title: const Text("Welcome 🎉"),
        content: const Text("Welcome to LuvPay! Your account is ready to use."),
      ),
      barrierDismissible: false,
    );
  }
}
