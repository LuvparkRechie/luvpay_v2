import 'package:get/get.dart';
import 'package:luvpay/features/bills_payment/index.dart';

class BillsPaymentBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BillsPaymentController>(() => BillsPaymentController());
  }
}
