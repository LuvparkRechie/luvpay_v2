import 'package:get/get.dart'; 

import 'controller.dart';

class BillersBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BillersController>(() => BillersController());
  }
}
