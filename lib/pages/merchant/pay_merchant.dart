// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:luvpay/custom_widgets/app_color_v2.dart';
import 'package:luvpay/custom_widgets/custom_textfield.dart';
import 'package:luvpay/custom_widgets/luvpay/custom_scaffold.dart';
import 'package:luvpay/custom_widgets/luvpay/luvpay_loading.dart';
import 'package:luvpay/custom_widgets/spacing.dart';
import 'package:luvpay/http/api_keys.dart';
import 'package:luvpay/http/http_request.dart';
import 'package:luvpay/pages/routes/routes.dart';

import '../../auth/authentication.dart';
import '../../custom_widgets/alert_dialog.dart';
import '../../custom_widgets/luvpay/custom_button.dart';
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

  List userData = [];
  bool isLoadingMerch = true;
  bool hasNet = true;

  @override
  void initState() {
    super.initState();
    getUserBalance();
    WidgetsBinding.instance.addPostFrameCallback((_) => _setCursorToEnd());
  }

  @override
  void dispose() {
    amountController.dispose();
    orderNumberController.dispose();
    super.dispose();
  }

  Future<void> getUserBalance() async {
    setState(() {
      isLoadingMerch = true;
      hasNet = true;
    });

    Functions.getUserBalance2(Get.context!, (dataBalance) async {
      if (!mounted) return;

      if (!dataBalance[0]["has_net"]) {
        setState(() {
          isLoadingMerch = false;
          hasNet = false;
        });
        return;
      }

      setState(() {
        isLoadingMerch = false;
        hasNet = true;
        userData = dataBalance[0]["items"];
      });
    });
  }

  void _setCursorToEnd() {
    amountController.selection = TextSelection.fromPosition(
      TextPosition(offset: amountController.text.length),
    );
  }

  String? _validateAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter an amount';
    }

    final amount = double.tryParse(value);
    if (amount == null || amount <= 0) {
      return 'Please enter a valid amount greater than zero';
    }

    if (userData.isEmpty) return 'Balance unavailable';

    final balanceRaw = userData[0]["amount_bal"];
    final balance =
        balanceRaw is num
            ? balanceRaw.toDouble()
            : (double.tryParse(balanceRaw.toString()) ?? 0.0);

    if (amount > balance) return 'Insufficient balance';
    return null;
  }

  Future<void> payMerchantVerify({dynamic isAuth}) async {
    CustomDialogStack.showLoading(Get.context!);

    final int? userid = await Authentication().getUserId();

    final postParam = <String, dynamic>{
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
        CustomDialogStack.showConnectionLost(Get.context!, () => Get.back());
        return;
      }
      if (retvalue == null) {
        CustomDialogStack.showServerError(Get.context!, () => Get.back());
        return;
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
        CustomDialogStack.showServerError(Get.context!, () => Get.back());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // your rule
    final borderOpacity = isDark ? 0.05 : 0.01;

    return CustomScaffoldV2(
      appBarTitle: "Pay Merchant",
      onPressedLeading: () {
        Get.back();
        Get.back();
      },
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      scaffoldBody:
          isLoadingMerch
              ? const LoadingCard(text: "Loading…")
              : !hasNet
              ? NoInternetConnected()
              : Column(
                children: [
                  _merchantHeaderCard(context, cs, borderOpacity),
                  spacing(height: 12),
                  Expanded(
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _balanceCard(context, cs, borderOpacity),
                          spacing(height: 18),

                          DefaultText(
                            text: "Amount",
                            style: AppTextStyle.h3(context),
                          ),
                          spacing(height: 10),
                          CustomTextField(
                            hintText: "Enter payment amount",
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            controller: amountController,
                            inputFormatters: [AutoDecimalInputFormatter()],
                            validator: _validateAmount,
                          ),

                          spacing(height: 14),

                          DefaultText(
                            text: "Order Number (Optional)",
                            style: AppTextStyle.h3(context),
                          ),
                          spacing(height: 10),
                          CustomTextField(
                            hintText: "Enter order number",
                            keyboardType: TextInputType.number,
                            controller: orderNumberController,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(20),
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),

                          spacing(height: 22),

                          CustomButton(
                            text: "Pay now",
                            onPressed: () async {
                              FocusManager.instance.primaryFocus?.unfocus();

                              if (!(_formKey.currentState?.validate() ??
                                  false)) {
                                return;
                              }

                              final isEnabledBioTrans =
                                  await Authentication().getBiometricStatus();
                              final data =
                                  await Authentication().getEncryptedKeys();
                              final uData =
                                  await Authentication().getUserData2();

                              if (isEnabledBioTrans == true) {
                                final ok = await AppSecurity.authenticateBio();
                                if (ok) {
                                  await payMerchantVerify(isAuth: data["pwd"]);
                                }
                                return;
                              }

                              // OTP path
                              CustomDialogStack.showLoading(Get.context!);
                              final timeNow = await Functions.getTimeNow();
                              final requestParam = <String, String>{
                                "mobile_no": data["mobile_no"],
                                "pwd": data["pwd"],
                              };
                              Get.back();

                              Functions().requestOtp(requestParam, (
                                objData,
                              ) async {
                                final timeExp = DateFormat(
                                  "yyyy-MM-dd hh:mm:ss a",
                                ).parse(objData["otp_exp_dt"].toString());

                                final otpExpiry = DateTime(
                                  timeExp.year,
                                  timeExp.month,
                                  timeExp.day,
                                  timeExp.hour,
                                  timeExp.minute,
                                  timeExp.second,
                                );

                                final difference = otpExpiry.difference(
                                  timeNow,
                                );

                                if (objData["success"] == "Y" ||
                                    objData["status"] == "PENDING") {
                                  final putParam = <String, String>{
                                    "mobile_no": uData["mobile_no"].toString(),
                                    "otp": objData["otp"].toString(),
                                    "req_type": "SR",
                                  };

                                  final args = {
                                    "time_duration": difference,
                                    "mobile_no": uData["mobile_no"].toString(),
                                    "req_otp_param": requestParam,
                                    "verify_param": putParam,
                                    "callback": (otp) async {
                                      if (otp != null) {
                                        await payMerchantVerify();
                                      }
                                    },
                                  };

                                  Get.to(
                                    OtpFieldScreen(arguments: args),
                                    transition: Transition.rightToLeftWithFade,
                                    duration: const Duration(milliseconds: 400),
                                  );
                                }
                              });
                            },
                          ),

                          spacing(height: 24),
                          _hintCard(context, cs, borderOpacity),
                          spacing(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _merchantHeaderCard(
    BuildContext context,
    ColorScheme cs,
    double borderOpacity,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final merchantName = _capitalize(
      (widget.data[0]["data"]?["merchant_name"] ??
              widget.data[0]["merchant_name"] ??
              "Merchant")
          .toString(),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.onSurface.withOpacity(borderOpacity)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(isDark ? 0.28 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(isDark ? 0.18 : 0.10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: cs.onSurface.withOpacity(borderOpacity),
              ),
            ),
            child: Icon(LucideIcons.store, color: cs.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DefaultText(
                  text: merchantName,
                  style: AppTextStyle.h3(
                    context,
                  ).copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.2),
                  color: cs.onSurface,
                  maxLines: 1,
                ),
                const SizedBox(height: 3),
                DefaultText(
                  text: "Enter amount and confirm payment",
                  style: AppTextStyle.body2(
                    context,
                  ).copyWith(fontWeight: FontWeight.w700),
                  color: cs.onSurface.withOpacity(0.65),
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _balanceCard(
    BuildContext context,
    ColorScheme cs,
    double borderOpacity,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final raw = userData.isNotEmpty ? userData[0]["amount_bal"] : "0";
    final balText = toCurrencyString(raw.toString());

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        image: const DecorationImage(
          fit: BoxFit.cover,
          image: AssetImage("assets/images/booking_wallet_bg.png"),
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.onSurface.withOpacity(borderOpacity)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(isDark ? 0.22 : 0.10),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Symbols.wallet, color: cs.onPrimary),
          const SizedBox(width: 10),
          Expanded(
            child: DefaultText(
              text: balText,
              style: AppTextStyle.body1(
                context,
              ).copyWith(fontWeight: FontWeight.w900),
              color: cs.onPrimary,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _hintCard(BuildContext context, ColorScheme cs, double borderOpacity) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withOpacity(borderOpacity)),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.shieldCheck,
            size: 18,
            color: cs.primary.withOpacity(isDark ? 0.95 : 1),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DefaultText(
              text: "You may be asked to verify via biometrics or OTP.",
              style: AppTextStyle.body2(
                context,
              ).copyWith(fontWeight: FontWeight.w700),
              color: cs.onSurface.withOpacity(0.70),
              maxLines: 2,
            ),
          ),
        ],
      ),
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

    final numericValue = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
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
