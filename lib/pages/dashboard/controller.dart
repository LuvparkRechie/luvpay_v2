import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../subwallet/controller.dart';

class DashboardController extends GetxController {
  final currentIndex = 0.obs;
  final pageController = PageController();

  void changePage(int index) {
    currentIndex.value = index;
    pageController.jumpToPage(index);
  }
}
