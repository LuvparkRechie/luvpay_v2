import 'package:get/get.dart';
import '../../functions/functions.dart';

class SubWalletController extends GetxController
    with GetSingleTickerProviderStateMixin {
  RxList userData = [].obs;
  RxString luvpayBal = '0.0'.obs;

  @override
  void onInit() {
    super.onInit();
    luvpayBalance();
  }

  Future<void> luvpayBalance() async {
    try {
      final data = await Functions.getUserBalance();
      userData.value = data;
      luvpayBal.value = userData[0]["items"][0]["amount_bal"];
    } catch (e) {
      print('Error fetching LuvPay balance: $e');
    }
  }

  @override
  void onClose() {
    userData.clear();
    luvpayBal.value = '0.0';

    super.onClose();
  }
}
