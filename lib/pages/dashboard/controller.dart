import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class DashboardController extends GetxController {
  final PageController pageController = PageController();
  var currentIndex = 0.obs;

  void changePage(int index) {
    pageController.jumpToPage(index);
    currentIndex.value = index;
  }
}
