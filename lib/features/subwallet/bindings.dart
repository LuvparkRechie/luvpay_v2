import 'package:get/get.dart';

import 'index.dart';

class SubWalletBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SubWalletController>(() => SubWalletController());
  }
}
