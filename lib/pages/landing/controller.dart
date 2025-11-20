import 'package:get/get.dart';

class LandingController extends GetxController {
  RxBool isAgree = false.obs;

  void onPageChanged(bool agree) {
    isAgree.value = agree;
    update();
  }

  LandingController();
}
