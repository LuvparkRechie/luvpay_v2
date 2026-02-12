import 'package:get/get.dart';

import 'controller.dart';

class FaqPageBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FaqPageController>(() => FaqPageController());
  }
}
