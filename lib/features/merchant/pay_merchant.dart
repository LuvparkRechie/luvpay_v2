// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:luvpay/shared/widgets/custom_textfield.dart';
import 'package:luvpay/shared/widgets/custom_scaffold.dart';
import 'package:luvpay/shared/widgets/luvpay_loading.dart';
import 'package:luvpay/shared/widgets/spacing.dart';
import 'package:luvpay/core/network/http/api_keys.dart';
import 'package:luvpay/core/network/http/http_request.dart';
import 'package:luvpay/features/routes/routes.dart';

import '../../auth/authentication.dart';
import 'package:luvpay/shared/dialogs/dialogs.dart';
import 'package:luvpay/shared/widgets/neumorphism.dart';

import '../../shared/widgets/colors.dart';
import '../../shared/widgets/luvpay_text.dart';

import '../../core/utils/functions/functions.dart';
import '../../shared/components/otp_field/view.dart';
import '../subwallet/controller.dart';
import '../wallet/refresh_wallet.dart';

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
  bool selectedWalletIsShared = false;
  List userData = [];
  bool isLoadingMerch = true;
  bool hasNet = true;
  String _msg = "";
  String selectedWalletName = "Main Wallet";
  double selectedWalletBalance = 0.0;
  double mainWalletBalance = 0.0;
  List<Map<String, dynamic>> subWallets = [];
  String selectedWalletId = "";
  final subWalletController = Get.put(SubWalletController());
  bool isProcessing = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setCursorToEnd();
      _getUserBal();
    });

    amountController.addListener(() {
      setState(() {});
      _revalidateForm();
    });
  }

  @override
  void dispose() {
    amountController.dispose();
    orderNumberController.dispose();
    super.dispose();
  }

  bool get isAmountValid {
    final amount = double.tryParse(amountController.text) ?? 0;
    return amount > 0 && amount <= selectedWalletBalance;
  }

  void _setCursorToEnd() {
    amountController.selection = TextSelection.fromPosition(
      TextPosition(offset: amountController.text.length),
    );
  }

  Future<void> _getUserBal() async {
    try {
      final userId = await Authentication().getUserId();
      String subApi = "${ApiKeys.getUserBalance}$userId";

      final response = await HttpRequestApi(api: subApi).get();

      if (response == "No Internet") {
        if (mounted) setState(() => _msg = "No Internet");
        return;
      }

      if (response == null) {
        if (mounted) setState(() => _msg = "null");
        return;
      }

      final subWalletController = Get.put(SubWalletController());

      await subWalletController.getUserSubWallets();

      if (mounted) {
        final items = response["items"] ?? [];

        double mainBal = 0.0;

        if (items.isNotEmpty) {
          final raw = items[0]["amount_bal"];
          mainBal = double.tryParse(raw.toString()) ?? 0.0;
        }

        setState(() {
          userData = items;
          mainWalletBalance = mainBal;
          selectedWalletBalance = mainBal;
          selectedWalletName = "Main Wallet";

          subWallets = subWalletController.userSubWallets;

          isLoadingMerch = false;
          _msg = "";
        });
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
    }
  }

  void _revalidateForm() {
    if (_formKey.currentState != null) {
      _formKey.currentState!.validate();
    }
  }

  String? _validateAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter an amount';
    }

    final amount = double.tryParse(value);

    if (amount == null || amount <= 0) {
      return 'Please enter a valid amount greater than zero';
    }
    if (amount > selectedWalletBalance) {
      return 'Insufficient funds';
    }

    return null;
  }

  Future<void> payMerchantVerify({dynamic isAuth}) async {
    CustomDialogStack.showLoading(Get.context!);

    final int? userid = await Authentication().getUserId();

    final postParam = <String, dynamic>{
      "luvpay_id": userid,
      "merchant_id": widget.data[0]["data"]?["merchant_id"] ?? "",
      "amount": amountController.text,
      "order_no": orderNumberController.text,
      "merchant_key": widget.data[0]["merchant_key"],
      "payment_hk": widget.data[0]["payment_key"],
      "user_sub_wallet_id": selectedWalletId,
    };
    final String api = ApiKeys.postMerchant;
    HttpRequestApi(
      api: api,
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
            "merchant_name": widget.data[0]["data"]?["merchant_name"] ??
                widget.data[0]["merchant_name"] ??
                "",
            "amount": postParam["amount"] ?? "0",
            "order_no": postParam["order_no"] ?? "",
            "wallet_name": selectedWalletName,
            "wallet_id": selectedWalletId,
            "luvpay_id": userid ?? "",
            "payment_hk": postParam["payment_hk"] ?? "",
            "reference_no": retvalue["lp_ref_no"] ?? "",
            "date_time": retvalue["response_time"] ?? "",
            "merchant_id": postParam["merchant_id"] ?? "",
          },
        );
        WalletRefreshBus.refresher();
      } else {
        CustomDialogStack.showError(
            Get.context!, "luvpay", "${retvalue["msg"]}", () => Get.back());
      }
    });
  }

  void onPayPressed() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final data = await Authentication().getEncryptedKeys();
    final uData = await Authentication().getUserData2();

    CustomDialogStack.showLoading(Get.context!);
    final timeNow = await Functions.getTimeNow();

    final requestParam = <String, String>{
      "mobile_no": data["mobile_no"],
      "pwd": data["pwd"],
    };

    Get.back();

    Functions().requestOtp(requestParam, (objData) async {
      setState(() => isProcessing = false);

      final timeExp = DateFormat("yyyy-MM-dd hh:mm:ss a")
          .parse(objData["otp_exp_dt"].toString());

      final otpExpiry = DateTime(
        timeExp.year,
        timeExp.month,
        timeExp.day,
        timeExp.hour,
        timeExp.minute,
        timeExp.second,
      );

      final difference = otpExpiry.difference(timeNow);

      if (objData["success"] == "Y" || objData["status"] == "PENDING") {
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
  }

  VoidCallback? _payHandler() {
    return isAmountValid ? () => onPayPressed() : null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final borderOpacity = isDark ? 0.05 : 0.01;
    final amount = double.tryParse(amountController.text) ?? 0;
    final remaining = selectedWalletBalance - amount;
    return CustomScaffoldV2(
      appBarTitle: "Pay Merchant",
      onPressedLeading: () {
        Get.back();
        Get.back();
      },
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      scaffoldBody: isLoadingMerch
          ? const LoadingCard(text: "Loading…")
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
                        LuvpayText(
                          text: "Amount",
                          style: AppTextStyle.body1(context),
                          color: cs.onBackground.withAlpha(250),
                        ),
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
                        LuvpayText(
                          color: cs.onBackground.withAlpha(250),
                          text: "Order Number (Optional)",
                          style: AppTextStyle.body1(context),
                        ),
                        CustomTextField(
                          hintText: "Enter order number",
                          keyboardType: TextInputType.number,
                          controller: orderNumberController,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(20),
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                        spacing(height: 14),
                        LuvpayText(
                          color: cs.onBackground.withAlpha(250),
                          text: "Pay from",
                          style: AppTextStyle.body1(context),
                        ),
                        spacing(height: 10),
                        _balanceCard(context, cs, borderOpacity),
                        spacing(height: 22),
                        CustomButton(
                          text: "Pay now",
                          isInactive: !isAmountValid,
                          onPressed: () {
                            onPayPressed();
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
                LuvpayText(
                  text: merchantName,
                  style: AppTextStyle.h3(
                    context,
                  ).copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.2),
                  color: cs.onSurface,
                  maxLines: 1,
                ),
                const SizedBox(height: 3),
                LuvpayText(
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
    return InfoRowTile(
      onTap: () {
        showModalBottomSheet(
            isScrollControlled: true,
            useSafeArea: true,
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) {
              return DraggableScrollableSheet(
                initialChildSize: 0.5,
                minChildSize: 0.4,
                maxChildSize: 0.9,
                expand: false,
                builder: (context, controller) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        Expanded(
                          child: ListView(
                            controller: controller,
                            physics: const BouncingScrollPhysics(),
                            children: [
                              LuvpayText(
                                text: "Select Wallet",
                                style: AppTextStyle.h3(context).copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 16),
                              InfoRowTile(
                                onTap: () {
                                  setState(() {
                                    selectedWalletName = "Main Wallet";
                                    selectedWalletBalance = mainWalletBalance;
                                    selectedWalletId = "";
                                    selectedWalletIsShared = false;
                                  });

                                  _revalidateForm();
                                  Get.back();
                                },
                                title: "Main Wallet",
                                subtitle: toCurrencyString(
                                    mainWalletBalance.toString()),
                                trailing: selectedWalletName == "Main Wallet"
                                    ? Icon(Icons.check,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary)
                                    : null,
                              ),
                              const SizedBox(height: 10),
                              if (subWallets.isNotEmpty)
                                LuvpayText(
                                  text: "Subwallets",
                                  style: AppTextStyle.body1(context).copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.7),
                                ),
                              const SizedBox(height: 10),
                              ...subWallets.map((wallet) {
                                final name = wallet["name"] ?? "Subwallet";
                                final bal = wallet["amount"] ?? 0;
                                final isSelected = selectedWalletName == name;
                                final isShared =
                                    wallet["shared_to_user_id"] != null;

                                return Padding(
                                  padding: const EdgeInsets.only(left: 12),
                                  child: InfoRowTile(
                                    onTap: bal == 0
                                        ? () {}
                                        : () {
                                            setState(() {
                                              selectedWalletName = name;
                                              selectedWalletBalance =
                                                  double.tryParse(
                                                          bal.toString()) ??
                                                      0.0;
                                              selectedWalletId =
                                                  wallet["id"].toString();
                                              selectedWalletIsShared =
                                                  isShared; // ✅ VERY IMPORTANT
                                            });

                                            _revalidateForm();
                                            Get.back();
                                          },
                                    titleWidget: Row(
                                      children: [
                                        LuvpayText(
                                          text: name,
                                          style: AppTextStyle.body1(context)
                                              .copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: isSelected
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .onSurface,
                                          ),
                                        ),
                                        if (isShared)
                                          LuvpayText(
                                            text: " (Shared)",
                                            color: AppColorV2.correctState,
                                          ),
                                      ],
                                    ),
                                    subtitle: toCurrencyString(bal.toString()),
                                    trailing: isSelected
                                        ? Icon(Icons.check,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary)
                                        : null,
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            });
      },
      titleWidget: Row(
        children: [
          LuvpayText(text: selectedWalletName),
          if (selectedWalletIsShared)
            LuvpayText(
              text: " (Shared)",
              color: AppColorV2.correctState,
            ),
        ],
      ),
      subtitle: toCurrencyString(selectedWalletBalance.toString()),
      trailing: Icon(
        CupertinoIcons.chevron_down,
        color: cs.onSurface,
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
            child: LuvpayText(
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
