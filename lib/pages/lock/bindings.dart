import 'package:get/get.dart';
import 'index.dart';

class LockBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LockController>(() => LockController());
  }
}
