import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DashboardController extends GetxController {
  RxBool isLoadingPage = false.obs;
  RxInt pageIndex = 0.obs;
  late PageController pageController;

  @override
  void onInit() {
    initialize();
    super.onInit();
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }

  void initialize() {
    pageController = PageController(initialPage: 0);
    pageIndex.value = 0;
  }

  void onPageChanged(int index) async {
    if (pageIndex.value == index) return;
    pageController.jumpToPage(index);

    pageIndex.value = index;
  }

  DashboardController();
}
