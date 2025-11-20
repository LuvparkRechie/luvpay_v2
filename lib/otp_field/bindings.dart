import 'package:get/get.dart';

import 'controller.dart';

class OtpFieldScreenBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OtpFieldScreenController>(() => OtpFieldScreenController());
  }
}
