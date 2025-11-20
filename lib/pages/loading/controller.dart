import 'package:get/get.dart';

class LoadingController extends GetxController {
  RxBool isAgree = false.obs;

  void onPageChanged(bool agree) {
    isAgree.value = agree;
    update();
  }

  LoadingController();
}
