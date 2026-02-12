import 'package:get/get.dart';

import 'controller.dart';

class LockScreenBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LockScreenController>(() => LockScreenController());
  }
}
