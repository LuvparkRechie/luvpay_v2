import 'package:get/get.dart';

class WalletRefreshBus {
  static final refresh = RxInt(0);

  static void refresher() {
    refresh.value++;
  }
}
