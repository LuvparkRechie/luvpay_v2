import 'package:get/get.dart';

import 'controller.dart';

class WalletSendBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WalletSendController>(() => WalletSendController());
  }
}
