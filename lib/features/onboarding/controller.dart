import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luvpay/auth/authentication.dart';

import '../routes/routes.dart';

class OnboardingController extends GetxController {
  RxInt currentPage = 0.obs;
  PageController pageController = PageController();
  OnboardingController();
  RxList<Map<String, dynamic>> sliderData = RxList([
    {
      "title": "Need parking?",
      "subTitle":
          "luvpay finds nearby spots in real-time based on your destination and location.",
      "icon": "onboard1",
    },
    {
      "title": "Easy booking",
      "subTitle":
          "Book your parking spot with ease using luvpay's state-of-the-art parking system.",
      "icon": "onboard2",
    },
    {
      "title": "Pick & Park",
      "subTitle":
          "Discover the perfect parking spot with luvpay—tailored just for you!",
      "icon": "onboard3",
    },
  ]);

  void onPageChanged(int index) {
    currentPage.value = index;
    update();
  }

  @override
  void onInit() {
    super.onInit();
    pageController = PageController();
    clearStoredData();
  }

  @override
  void onClose() {
    super.onClose();
    pageController.dispose();
  }

  void clearStoredData() {
    Authentication().clearStoredData();
  }

  void btnTap() {
    FocusScope.of(Get.context!).requestFocus(FocusNode());

    switch (currentPage.value) {
      case 0 || 1:
        pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );

        break;
      case 2:
        Get.offAllNamed(Routes.login);
        break;
    }
  }
}
