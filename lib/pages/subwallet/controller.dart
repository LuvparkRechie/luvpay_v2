import 'package:get/get.dart';
import '../../functions/functions.dart';

class SubWalletController extends GetxController
    with GetSingleTickerProviderStateMixin {
  RxList userData = [].obs;
  RxDouble numericBalance = 0.0.obs;
  RxString luvpayBal = '0.00'.obs;

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
      numericBalance.value = double.parse(luvpayBal.value);
    } catch (e) {
      print('Error fetching LuvPay balance: $e');
    }
  }

  Future<void> updateMainBalance(double amountToDeduct) async {
    try {
      numericBalance.value -= amountToDeduct;
      luvpayBal.value = numericBalance.value.toStringAsFixed(2);

      print(
        'Deducted $amountToDeduct from main balance. New balance: ${luvpayBal.value}',
      );
    } catch (e) {
      print('Error updating main balance: $e');
    }
  }

  Future<void> returnToMainBalance(double amountToAdd) async {
    try {
      numericBalance.value += amountToAdd;
      luvpayBal.value = numericBalance.value.toStringAsFixed(2);

      print(
        'Added $amountToAdd to main balance. New balance: ${luvpayBal.value}',
      );
    } catch (e) {
      print('Error updating main balance: $e');
    }
  }

  @override
  void onClose() {
    userData.clear();
    luvpayBal.value = '0.0';
    numericBalance.value = 0.0;
    super.onClose();
  }
}
