import 'package:get/get.dart';

import 'index.dart';

class RegistrationBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RegistrationController>(() => RegistrationController());
  }
}
