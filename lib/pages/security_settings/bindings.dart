import 'package:get/get.dart';

import 'controller.dart';

class SecuritySettingsBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SecuritySettingsController>(() => SecuritySettingsController());
  }
}
