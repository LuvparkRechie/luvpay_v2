import 'package:get/get.dart';

import 'controller.dart';

class merchantQRRBindings implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MerchantQRRController>(() => MerchantQRRController());
  }
}
