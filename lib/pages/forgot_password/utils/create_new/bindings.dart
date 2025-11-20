import 'package:get/get.dart';

import 'controller.dart';

class CreateNewPasswordBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CreateNewPassController>(() => CreateNewPassController());
  }
}
