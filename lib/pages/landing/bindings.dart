import 'package:get/get.dart';

import 'controller.dart';

class LandingBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LandingController>(() => LandingController());
  }
}
