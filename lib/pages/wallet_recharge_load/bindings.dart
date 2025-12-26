import 'package:get/get.dart';

import 'controller.dart';

class WalletRechargeLoadBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WalletRechargeLoadController>(
        () => WalletRechargeLoadController());
  }
}
