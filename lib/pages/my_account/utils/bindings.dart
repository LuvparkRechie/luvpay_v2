import 'package:get/get.dart';
import 'package:luvpay/pages/my_account/utils/index.dart';

class UpdateProfileBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<UpdateProfileController>(() => UpdateProfileController());
  }
}
