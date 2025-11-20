import 'package:get/get.dart';

import 'controller.dart';

class LoginScreenBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LoginScreenController>(() => LoginScreenController());
  }
}
