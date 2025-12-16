import 'package:get/get.dart';
import 'package:luvpay/pages/bills_payment/index.dart';

class BillsPaymentBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BillsPaymentController>(() => BillsPaymentController());
  }
}
