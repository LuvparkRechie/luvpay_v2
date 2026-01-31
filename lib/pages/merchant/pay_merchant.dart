import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:luvpay/custom_widgets/app_color_v2.dart';
import 'package:luvpay/custom_widgets/custom_textfield.dart';
import 'package:luvpay/custom_widgets/loading.dart';
import 'package:luvpay/custom_widgets/luvpay/custom_scaffold.dart';
import 'package:luvpay/custom_widgets/spacing.dart';
import 'package:luvpay/http/api_keys.dart';
import 'package:luvpay/http/http_request.dart';
import 'package:luvpay/pages/routes/routes.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../auth/authentication.dart';
import '../../custom_widgets/alert_dialog.dart';
import '../../custom_widgets/custom_button.dart';
import '../../custom_widgets/custom_text_v2.dart';
import '../../custom_widgets/no_internet.dart';
import '../../functions/functions.dart';
import '../../otp_field/view.dart';
import '../../security/app_security.dart';

class PayMerchant extends StatefulWidget {
  final List data;
  const PayMerchant({super.key, required this.data});

  @override
  State<PayMerchant> createState() => _PayMerchantState();
}

class _PayMerchantState extends State<PayMerchant> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController orderNumberController = TextEditingController();
  final TextEditingController password = TextEditingController();
  final TextEditingController confirmPassword = TextEditingController();
  final GlobalKey<FormState> confirmFormKey = GlobalKey<FormState>();
  List userData = [];
  bool isLoadingMerch = true;
  bool hasNet = true;

  @override
  void initState() {
    super.initState();

    getUserBalance();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setCursorToEnd();
    });
  }

  Future<void> getUserBalance() async {
    setState(() {
      isLoadingMerch = true;
      hasNet = true;
    });
    Functions.getUserBalance2(Get.context!, (dataBalance) async {
      if (!dataBalance[0]["has_net"]) {
        return;
      } else {
        isLoadingMerch = false;
        hasNet = true;
        userData = dataBalance[0]["items"];
      }
      setState(() {});
    });
  }

  void _setCursorToEnd() {
    amountController.selection = TextSelection.fromPosition(
      TextPosition(offset: amountController.text.length),
    );
  }

  String? _validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter an amount';
    }

    final amount = double.tryParse(value);
    if (amount == null || amount <= 0) {
      return 'Please enter a valid amount greater than zero';
    }

    final balance = userData[0]["amount_bal"];
    final balanceAmount =
        balance is double
            ? balance
            : double.tryParse(balance.toString()) ?? 0.0;

    if (amount > balanceAmount) {
      return 'Insufficient balance';
    }

    return null;
  }

  Future<void> payMerchantVerify({isAuth}) async {
    CustomDialogStack.showLoading(Get.context!);
    int? userid = await Authentication().getUserId();

    Map<String, dynamic> postParam = {
      "merchant_name": widget.data[0]["merchant_name"],
      "amount": amountController.text,
      "order_no": orderNumberController.text,
      "merchant_key": widget.data[0]["merchant_key"],
      "payment_hk": widget.data[0]["payment_key"],
    };

    HttpRequestApi(
      api: ApiKeys.postMerchant,
      parameters: postParam,
    ).postBody().then((retvalue) {
      Get.back();

      if (retvalue == "No Internet") {
        CustomDialogStack.showConnectionLost(Get.context!, () {
          Get.back();
        });
        return;
      }
      if (retvalue == null) {
        CustomDialogStack.showServerError(Get.context!, () {
          Get.back();
        });
      }
      if (retvalue['success'] == "Y") {
        Get.offAndToNamed(
          Routes.merchantReceipt,
          arguments: {
            "isAuth": isAuth ?? "",
            "merchant_name": postParam["merchant_name"],
            "amount": postParam["amount"],
            "luvpay_id": userid,
            "payment_hk": postParam["payment_hk"],
            "reference_no": retvalue["lp_ref_no"],
            "date_time": retvalue["response_time"],
          },
        );
      } else {
        CustomDialogStack.showServerError(Get.context!, () {
          Get.back();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffoldV2(
      onPressedLeading: () {
        Get.back();
        Get.back();
      },
      scaffoldBody:
          isLoadingMerch
              ? LoadingCard()
              : !hasNet
              ? NoInternetConnected()
              : Column(
                children: [
                  _buildMerchantCard(),
                  spacing(height: 10),

                  Expanded(
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        children: [
                          spacing(height: 20),

                          buildWalletBalance(),
                          spacing(height: 20),
                          DefaultText(text: "Amount", style: AppTextStyle.h3),
                          CustomTextField(
                            hintText: "Enter payment amount",
                            keyboardType: TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            controller: amountController,
                            inputFormatters: [AutoDecimalInputFormatter()],
                            validator: _validateAmount,
                          ),
                          spacing(height: 14),
                          DefaultText(
                            text: "Order Number (Optional)",
                            style: AppTextStyle.h3,
                          ),
                          CustomTextField(
                            hintText: "Enter order number",
                            keyboardType: TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            controller: orderNumberController,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(20),
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                          spacing(height: 30),
                          CustomButton(
                            text: "Pay now",
                            onPressed: () async {
                              FocusManager.instance.primaryFocus?.unfocus();

                              if (_formKey.currentState?.validate() ?? false) {
                                bool? isEnabledBioTrans =
                                    await Authentication().getBiometricStatus();
                                Map<String, dynamic> data =
                                    await Authentication().getEncryptedKeys();
                                final uData =
                                    await Authentication().getUserData2();

                                //
                                if (isEnabledBioTrans!) {
                                  bool isEnabledBio =
                                      await AppSecurity.authenticateBio();

                                  if (isEnabledBio) {
                                    payMerchantVerify(isAuth: data["pwd"]);
                                  }
                                } else {
                                  CustomDialogStack.showLoading(Get.context!);
                                  DateTime timeNow =
                                      await Functions.getTimeNow();
                                  Map<String, String> requestParam = {
                                    "mobile_no": data["mobile_no"],
                                    "pwd": data["pwd"],
                                  };
                                  Get.back();

                                  Functions().requestOtp(requestParam, (
                                    objData,
                                  ) async {
                                    DateTime timeExp = DateFormat(
                                      "yyyy-MM-dd hh:mm:ss a",
                                    ).parse(objData["otp_exp_dt"].toString());
                                    DateTime otpExpiry = DateTime(
                                      timeExp.year,
                                      timeExp.month,
                                      timeExp.day,
                                      timeExp.hour,
                                      timeExp.minute,
                                      timeExp.millisecond,
                                    );

                                    // Calculate difference
                                    Duration difference = otpExpiry.difference(
                                      timeNow,
                                    );

                                    if (objData["success"] == "Y" ||
                                        objData["status"] == "PENDING") {
                                      Map<String, String> putParam = {
                                        "mobile_no":
                                            uData["mobile_no"].toString(),
                                        "otp": objData["otp"].toString(),
                                        "req_type": "SR",
                                      };

                                      Object args = {
                                        "time_duration": difference,
                                        "mobile_no":
                                            uData["mobile_no".toString()]
                                                .toString(),
                                        "req_otp_param": requestParam,
                                        "verify_param": putParam,
                                        "callback": (otp) async {
                                          if (otp != null) {
                                            payMerchantVerify();
                                          }
                                        },
                                      };

                                      Get.to(
                                        OtpFieldScreen(arguments: args),
                                        transition:
                                            Transition.rightToLeftWithFade,
                                        duration: Duration(milliseconds: 400),
                                      );
                                    }
                                  });
                                }
                              }
                            },
                          ),
                          // spacing(height: 90),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
    );
  }

  Widget buildWalletBalance() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DefaultText(text: "luvpay Balance", style: AppTextStyle.h3),
        spacing(height: 14),
        Container(
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: AppColorV2.lpBlueBrand.withAlpha(50)),
            image: DecorationImage(
              fit: BoxFit.cover,
              image: AssetImage("assets/images/booking_wallet_bg.png"),
            ),
          ),
          padding: const EdgeInsets.all(14),

          child: Row(
            children: [
              Icon(Symbols.wallet, color: AppColorV2.background),
              Container(width: 10),
              Expanded(
                child: DefaultText(
                  color: AppColorV2.background,
                  text:
                      "${toCurrencyString(userData[0]["amount_bal"].toString())}",
                  style: AppTextStyle.body1,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMerchantCard() {
    return Row(
      children: [
        Icon(LucideIcons.store, color: AppColorV2.lpBlueBrand, size: 24),
        SizedBox(width: 10),
        Expanded(
          child: DefaultText(
            color: AppColorV2.lpBlueBrand,
            text: _capitalize(widget.data[0]["data"]["merchant_name"]),
            style: AppTextStyle.h4,
          ),
        ),
      ],
    );
  }
}

class AutoDecimalInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    // Remove non-numeric characters
    final numericValue = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // Format as decimal (e.g., "123" -> "1.23")
    final value = double.tryParse(numericValue) ?? 0.0;
    final formattedValue = (value / 100).toStringAsFixed(2);

    return TextEditingValue(
      text: formattedValue,
      selection: TextSelection.collapsed(offset: formattedValue.length),
    );
  }
}

String _capitalize(String text) {
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1).toLowerCase();
}
