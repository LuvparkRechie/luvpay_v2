import 'package:get/get.dart';

import 'controller.dart';

class ForgotVerifiedAcctBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ForgotVerifiedAcctController>(
        () => ForgotVerifiedAcctController());
  }
}
