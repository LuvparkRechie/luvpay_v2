// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:luvpay/auth/authentication.dart';
import 'package:luvpay/custom_widgets/alert_dialog.dart';
import 'package:luvpay/custom_widgets/luvpay/custom_button.dart';
import 'package:luvpay/custom_widgets/custom_text_v2.dart';
import 'package:luvpay/custom_widgets/custom_textfield.dart';
import 'package:luvpay/custom_widgets/luvpay/custom_scaffold.dart';
import 'package:luvpay/custom_widgets/spacing.dart';
import 'package:luvpay/custom_widgets/upper_case_formatter.dart';
import 'package:luvpay/functions/functions.dart';
import 'package:luvpay/http/api_keys.dart';
import 'package:luvpay/http/http_request.dart';
import 'package:luvpay/pages/biller_screen/bill_receipt.dart';

import '../../otp_field/view.dart';

class BillerScreen extends StatefulWidget {
  final List data;
  final String paymentHk;
  const BillerScreen({super.key, required this.data, required this.paymentHk});

  @override
  State<BillerScreen> createState() => _BillerScreenState();
}

class _BillerScreenState extends State<BillerScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _billAcctController = TextEditingController();
  final TextEditingController _billNoController = TextEditingController();
  final TextEditingController _accountNameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  bool isLoading = false;
  double _walletBal = 0.0;

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  @override
  void dispose() {
    _billAcctController.dispose();
    _billNoController.dispose();
    _accountNameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> getUserData() async {
    if (isLoading || !mounted) return;
    setState(() => isLoading = true);

    try {
      final data = await Functions.getUserBalance();

      double bal = 0.0;
      if (data.isNotEmpty) {
        final root = data[0];
        if (root is Map &&
            root["items"] is List &&
            (root["items"] as List).isNotEmpty) {
          final item0 = (root["items"] as List)[0];
          if (item0 is Map) {
            final raw = item0["amount_bal"];
            bal =
                raw is num
                    ? raw.toDouble()
                    : (double.tryParse(raw?.toString() ?? "") ?? 0.0);
          }
        }
      }

      if (!mounted) return;
      setState(() => _walletBal = bal);
    } catch (e) {
      debugPrint("Error fetching user data: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _requestOtpThenPay(VoidCallback onVerified) async {
    try {
      final data = await Authentication().getEncryptedKeys();
      final uData = await Authentication().getUserData2();

      final requestParam = <String, String>{
        "mobile_no": uData["mobile_no"].toString(),
        "pwd": data["pwd"],
      };

      CustomDialogStack.showLoading(Get.context!);
      final timeNow = await Functions.getTimeNow();
      Get.back();

      Functions().requestOtp(requestParam, (objData) async {
        if (objData == null) return;

        final isOk =
            (objData["success"] == "Y" || objData["status"] == "PENDING");
        if (!isOk) {
          CustomDialogStack.showError(
            Get.context!,
            "Error",
            objData["msg"]?.toString() ?? "Failed to request OTP",
            () => Get.back(),
          );
          return;
        }

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

        final difference = otpExpiry.difference(timeNow);

        final putParam = <String, String>{
          "mobile_no": uData["mobile_no"].toString(),
          "otp": objData["otp"].toString(),
        };

        final args = {
          "time_duration": difference,
          "mobile_no": uData["mobile_no"].toString(),
          "req_otp_param": requestParam,
          "verify_param": putParam,
          "callback": (otp) async {
            if (otp != null) onVerified();
          },
        };

        Get.to(
          OtpFieldScreen(arguments: args),
          transition: Transition.rightToLeftWithFade,
          duration: const Duration(milliseconds: 400),
        );
      });
    } catch (e) {
      CustomDialogStack.showServerError(Get.context!, () => Get.back());
    }
  }

  String? _validateAmount(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please enter an amount';

    final amount = double.tryParse(value);
    if (amount == null || amount <= 0)
      return 'Please enter a valid amount greater than zero';

    if (amount > _walletBal) return 'Insufficient balance';
    return null;
  }

  void _submitForm() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    CustomDialogStack.showLoading(Get.context!);

    final billAcct = _billAcctController.text.trim();
    final billNo = _billNoController.text.trim();
    final accountName = _accountNameController.text.trim();
    final amount = _amountController.text.trim();

    final serviceFee =
        double.tryParse(widget.data[0]['service_fee'].toString()) ?? 0.0;
    final userAmount = double.tryParse(amount) ?? 0.0;
    final totalAmount = (serviceFee + userAmount).toStringAsFixed(2);

    final userId = await Authentication().getUserId();

    final parameter = {
      "luvpay_id": userId.toString(),
      "biller_id": widget.data[0]["biller_id"].toString(),
      "bill_acct_no": billAcct,
      "amount": totalAmount,
      "payment_hk": widget.paymentHk,
      "bill_no": billNo,
      "account_name": accountName,
      "original_amount": amount,
    };

    HttpRequestApi(
      api: ApiKeys.postPayBills,
      parameters: parameter,
    ).postBody().then((returnPost) async {
      Get.back();

      if (returnPost == "No Internet") {
        CustomDialogStack.showConnectionLost(Get.context!, () => Get.back());
        return;
      }

      if (returnPost == null) {
        CustomDialogStack.showServerError(Get.context!, () => Get.back());
        return;
      }

      if (returnPost["success"] == 'Y') {
        _billAcctController.clear();
        _billNoController.clear();
        _accountNameController.clear();
        _amountController.clear();

        final result = await Get.to(
          BillPaymentReceipt(apiResponse: returnPost, paymentParams: parameter),
        );

        if (result != null) Get.back();
        return;
      }

      CustomDialogStack.showError(
        Get.context!,
        "Error",
        returnPost["msg"],
        () => Get.back(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final borderOpacity = isDark ? 0.05 : 0.01;

    final billerName = _capitalize(
      (widget.data[0]["biller_name"] ?? "Biller").toString(),
    );
    final serviceFeeText = (widget.data[0]["service_fee"] ?? "0").toString();
    final hasServiceFee = serviceFeeText.isNotEmpty && serviceFeeText != "0";

    return CustomScaffoldV2(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      appBarTitle: "Pay Bill",
      onPressedLeading: () {
        Get.back();
        Get.back();
      },
      scaffoldBody: Column(
        children: [
          _headerCard(
            context,
            cs: cs,
            isDark: isDark,
            borderOpacity: borderOpacity,
            title: billerName,
          ),
          spacing(height: 12),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  _balanceCard(
                    context,
                    cs: cs,
                    isDark: isDark,
                    borderOpacity: borderOpacity,
                    isLoading: isLoading,
                    balanceText: toCurrencyString(_walletBal.toString()),
                  ),
                  spacing(height: 18),

                  DefaultText(
                    text: "Bill Account Number",
                    style: AppTextStyle.h3(context),
                  ),
                  spacing(height: 10),
                  CustomTextField(
                    keyboardType: TextInputType.number,
                    controller: _billAcctController,
                    hintText: 'Enter bill account number',
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(15),
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return "Account number is required";
                      if (value.length < 5)
                        return "Account number must be at least 5 digits";
                      if (value.length > 15)
                        return "Account number must not exceed 15 digits";
                      return null;
                    },
                  ),

                  spacing(height: 14),
                  DefaultText(
                    text: "Bill Number",
                    style: AppTextStyle.h3(context),
                  ),
                  spacing(height: 10),
                  CustomTextField(
                    controller: _billNoController,
                    hintText: 'Enter bill number',
                    inputFormatters: [
                      UpperCaseTextFormatter(),
                      LengthLimitingTextInputFormatter(15),
                    ],
                    validator:
                        (value) =>
                            (value == null || value.isEmpty)
                                ? 'Please enter bill number'
                                : null,
                  ),

                  spacing(height: 14),
                  DefaultText(
                    text: "Account Name",
                    style: AppTextStyle.h3(context),
                  ),
                  spacing(height: 10),
                  CustomTextField(
                    controller: _accountNameController,
                    hintText: 'Enter account name',
                    keyboardType: TextInputType.name,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(30),
                      TextInputFormatter.withFunction((oldValue, newValue) {
                        final filtered = newValue.text
                            .toUpperCase()
                            .replaceAll(RegExp(r'[^A-Z\s]'), '')
                            .replaceAll(RegExp(r'\s+'), ' ');
                        return TextEditingValue(
                          text: filtered,
                          selection: TextSelection.collapsed(
                            offset: filtered.length,
                          ),
                        );
                      }),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return "Account name is required";
                      if (value.startsWith(' ') || value.endsWith(' ')) {
                        return "Account name cannot start or end with a space";
                      }
                      return null;
                    },
                  ),

                  spacing(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: DefaultText(
                          text: "Amount",
                          style: AppTextStyle.h3(context),
                        ),
                      ),
                      if (hasServiceFee)
                        DefaultText(
                          text: "+$serviceFeeText Service Fee",
                          style: AppTextStyle.body2(
                            context,
                          ).copyWith(fontWeight: FontWeight.w800),
                          color: cs.onSurface.withOpacity(0.60),
                        ),
                    ],
                  ),
                  spacing(height: 10),
                  CustomTextField(
                    controller: _amountController,
                    hintText: "Enter payment amount",
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      AutoDecimalInputFormatter(),
                      LengthLimitingTextInputFormatter(10),
                    ],
                    validator: _validateAmount,
                  ),

                  spacing(height: 18),
                  _reviewHintCard(context, cs, borderOpacity),
                  spacing(height: 18),

                  CustomButton(
                    text: "Pay now",
                    onPressed: () async {
                      FocusManager.instance.primaryFocus?.unfocus();
                      if (!(_formKey.currentState?.validate() ?? false)) return;

                      await _requestOtpThenPay(() {
                        _submitForm();
                      });
                    },
                  ),

                  spacing(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerCard(
    BuildContext context, {
    required ColorScheme cs,
    required bool isDark,
    required double borderOpacity,
    required String title,
  }) {
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
            child: Icon(Iconsax.receipt_text, color: cs.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DefaultText(
              text: title,
              style: AppTextStyle.h3(
                context,
              ).copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.2),
              color: cs.onSurface,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _balanceCard(
    BuildContext context, {
    required ColorScheme cs,
    required bool isDark,
    required double borderOpacity,
    required bool isLoading,
    required String balanceText,
  }) {
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
              text: isLoading ? "Loading…" : balanceText,
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

  Widget _reviewHintCard(
    BuildContext context,
    ColorScheme cs,
    double borderOpacity,
  ) {
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
          Icon(Iconsax.info_circle, size: 18, color: cs.primary),
          const SizedBox(width: 10),
          Expanded(
            child: DefaultText(
              text: "Please review your details before you proceed.",
              style: AppTextStyle.body2(
                context,
              ).copyWith(fontWeight: FontWeight.w800),
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

String toCurrencyString(String amount) {
  final number = double.tryParse(amount) ?? 0.0;
  return '₱${number.toStringAsFixed(2)}';
}
