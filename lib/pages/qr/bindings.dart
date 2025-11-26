import 'package:get/get.dart';

import 'controller.dart';

class QRBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<QRController>(() => QRController());
  }
}
