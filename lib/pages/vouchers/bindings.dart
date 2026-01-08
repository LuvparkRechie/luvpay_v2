import 'package:get/get.dart';

import 'index.dart';

class VouchersBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<VouchersController>(() => VouchersController());
  }
}
