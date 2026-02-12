import 'package:get/get.dart';
import 'package:luvpay/features/my_account/utils/index.dart';

class UpdateProfileBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<UpdateProfileController>(() => UpdateProfileController());
  }
}
