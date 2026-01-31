import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:luvpay/auth/authentication.dart';
import 'package:luvpay/custom_widgets/alert_dialog.dart';
import 'package:luvpay/custom_widgets/app_color_v2.dart';
import 'package:luvpay/custom_widgets/custom_body.dart';
import 'package:luvpay/custom_widgets/custom_button.dart';
import 'package:luvpay/custom_widgets/custom_text_v2.dart';
import 'package:luvpay/custom_widgets/custom_textfield.dart';
import 'package:luvpay/custom_widgets/luvpay/custom_scaffold.dart';
import 'package:luvpay/custom_widgets/spacing.dart';
import 'package:luvpay/custom_widgets/upper_case_formatter.dart';
import 'package:luvpay/functions/functions.dart';
import 'package:luvpay/http/api_keys.dart';
import 'package:luvpay/http/http_request.dart';
import 'package:luvpay/pages/biller_screen/bill_receipt.dart';

import 'package:material_symbols_icons/symbols.dart';

import '../../otp_field/view.dart';

class BillerScreen extends StatefulWidget {
  final List data;
  final String paymentHk;
  const BillerScreen({super.key, required this.data, required this.paymentHk});

  @override
  _BillerScreenState createState() => _BillerScreenState();
}

class _BillerScreenState extends State<BillerScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _billAcctController = TextEditingController();
  final TextEditingController _billNoController = TextEditingController();
  final TextEditingController _accountNameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _billerNameController = TextEditingController();
  final TextEditingController _billerAddressController =
      TextEditingController();
  List userData = [];
  bool canProceed = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
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
          timeExp.millisecond,
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

  void _initializeData() {
    // Initialize with widget data if available
    if (widget.data.isNotEmpty) {
      _billerNameController.text = widget.data[0]["biller_name"] ?? "";
      _billerAddressController.text = widget.data[0]["biller_address"] ?? "";
    }

    // Mock user data - replace with actual API call
    userData = [
      {"amount_bal": 1500.00},
    ];
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

  void _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      CustomDialogStack.showLoading(Get.context!);
      final billAcct = _billAcctController.text;
      final billNo = _billNoController.text;
      final accountName = _accountNameController.text;
      final amount = _amountController.text;

      double serviceFee =
          double.tryParse(widget.data[0]['service_fee'].toString()) ?? 0.0;
      double userAmount = double.tryParse(amount) ?? 0.0;
      double addedAmount = serviceFee + userAmount;
      String totalAmount = addedAmount.toStringAsFixed(2);
      int userId = await Authentication().getUserId();
      var parameter = {
        "luvpay_id": userId.toString(),
        "biller_id": widget.data[0]["biller_id"].toString(),
        "bill_acct_no": billAcct,
        "amount": totalAmount,
        "payment_hk": widget.paymentHk,
        "bill_no": billNo,
        "account_name": accountName,
        'original_amount': amount,
      };

      HttpRequestApi(
        api: ApiKeys.postPayBills,
        parameters: parameter,
      ).postBody().then((returnPost) async {
        print("returnPost $returnPost");
        Get.back();
        if (returnPost == "No Internet") {
          CustomDialogStack.showConnectionLost(Get.context!, () {
            Get.back();
          });
        } else if (returnPost == null) {
          CustomDialogStack.showServerError(Get.context!, () {
            Get.back();
          });
        } else {
          if (returnPost["success"] == 'Y') {
            _billAcctController.clear();
            _billNoController.clear();
            _accountNameController.clear();
            _amountController.clear();
            final result = await Get.to(
              BillPaymentReceipt(
                apiResponse: returnPost,
                paymentParams: parameter,
              ),
            );
            if (result != null) {
              Get.back();
            }
          } else {
            CustomDialogStack.showError(
              Get.context!,
              "Error",
              returnPost["msg"],
              () {
                Get.back();
              },
            );
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffoldV2(
      padding: EdgeInsets.zero,
      backgroundColor: AppColorV2.background,
      onPressedLeading: () {
        Get.back();
        Get.back();
      },
      appBarTitle: "Pay Bill",
      scaffoldBody: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 20),
        child: Column(
          children: [
            spacing(height: 20),

            // Biller Card
            _buildBillerCard(),
            spacing(height: 10),

            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    spacing(height: 20),

                    // Wallet Balance
                    buildWalletBalance(),
                    spacing(height: 30),

                    DefaultText(
                      text: "Bill Account Number",
                      style: AppTextStyle.h3,
                    ),

                    CustomTextField(
                      keyboardType: TextInputType.number,
                      controller: _billAcctController,
                      hintText: 'Enter bill account number',
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(15),
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Account number is required";
                        } else if (value.length < 5) {
                          return "Account number must be at least 5 digits";
                        } else if (value.length > 15) {
                          return "Account number must not exceed 15 digits";
                        }
                        return null;
                      },
                    ),

                    // Bill Number Field
                    spacing(height: 14),
                    DefaultText(text: "Bill Number", style: AppTextStyle.h3),

                    CustomTextField(
                      controller: _billNoController,
                      hintText: 'Enter bill number',
                      inputFormatters: [UpperCaseTextFormatter()],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter bill number';
                        }
                        return null;
                      },
                    ),

                    // Account Name Field
                    spacing(height: 14),
                    DefaultText(text: "Account Name", style: AppTextStyle.h3),

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
                        if (value == null || value.isEmpty) {
                          return "account name is required";
                        }
                        if (value.startsWith(' ') || value.endsWith(' ')) {
                          return "account name cannot start or end with a space";
                        }
                        return null;
                      },
                    ),

                    // Amount Field
                    spacing(height: 14),
                    DefaultText(text: "Amount", style: AppTextStyle.h3),

                    CustomTextField(
                      controller: _amountController,
                      hintText: "Enter payment amount",
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [AutoDecimalInputFormatter()],
                      validator: _validateAmount,
                    ),

                    spacing(height: 30),
                    Text(
                      'Please review your details before you proceed',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                    spacing(height: 20),
                    CustomButton(
                      text: "Pay now",

                      onPressed: () async {
                        FocusManager.instance.primaryFocus?.unfocus();

                        if (!(_formKey.currentState?.validate() ?? false))
                          return;

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
                  text: toCurrencyString(userData[0]["amount_bal"].toString()),
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

  Widget _buildBillerCard() {
    return Row(
      children: [
        Icon(Iconsax.receipt_text, color: AppColorV2.lpBlueBrand, size: 24),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            _capitalize(widget.data[0]["biller_name"]),
            style: TextStyle(
              color: AppColorV2.lpBlueBrand,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _billerNameController.dispose();
    _billerAddressController.dispose();
    _billAcctController.dispose();
    _billNoController.dispose();
    _accountNameController.dispose();
    _amountController.dispose();
    super.dispose();
  }
}

// Helper functions from your basis code
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

String toCurrencyString(String amount) {
  final number = double.tryParse(amount) ?? 0.0;
  return '₱${number.toStringAsFixed(2)}';
}
