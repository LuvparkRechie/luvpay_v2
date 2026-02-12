// ignore_for_file: prefer_const_constructors

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:luvpay/core/network/http/http_request.dart';
import 'package:luvpay/shared/dialogs/dialogs.dart';

import '../../../auth/authentication.dart';
import '../../../shared/widgets/colors.dart';
import '../../../shared/widgets/neumorphism.dart';
import '../../../shared/widgets/luvpay_text.dart';
import '../../../shared/widgets/custom_textfield.dart';
import '../../../shared/widgets/luvpay_loading.dart';
import '../../../shared/widgets/no_internet.dart';
import '../../../core/utils/functions/functions.dart';
import '../../../core/network/http/api_keys.dart';
import '../controller.dart';

class PayBill extends StatefulWidget {
  const PayBill({super.key});

  @override
  State<PayBill> createState() => _PayBillState();
}

class _PayBillState extends State<PayBill> {
  final controller = Get.put(BillersController());
  final fav = Get.arguments;
  final args = Get.arguments;
  double userBalance = 0.0;
  bool isLoading = true;
  bool isNetConn = true;

  final _accountNumberKey = GlobalKey<FormState>();
  final _accountNameKey = GlobalKey<FormState>();
  final _amountKey = GlobalKey<FormState>();
  final _billNumberKey = GlobalKey<FormState>();
  @override
  void initState() {
    controller.clearFields();
    super.initState();
    controller.billAccNo.text = fav["account_no"] ?? '';
    controller.billerAccountName.text = fav["account_name"] ?? '';
    getBalance();
  }

  Future<void> getBalance() async {
    final item = await Authentication().getUserId();
    String subApi = "${ApiKeys.getUserBalance}$item";
    HttpRequestApi(api: subApi).get().then((returnBalance) async {
      if (returnBalance == "No Internet") {
        setState(() {
          isLoading = false;
          isNetConn = false;
        });
        return;
      }

      if (returnBalance == null) {
        setState(() {
          isLoading = true;
          isNetConn = false;
        });
        CustomDialogStack.showServerError(context, () {
          Get.back();
        });
      }
      if (returnBalance["items"].isNotEmpty) {
        setState(() {
          isLoading = false;
          isNetConn = true;
          double amount = double.parse(
            returnBalance["items"][0]["amount_bal"].toString(),
          );
          userBalance = amount;
        });
      }
    });
  }

  void _submitForm() {
    bool isFavSource = args["source"] == "fav";
    final isAccountNumberValid = _accountNumberKey.currentState!.validate();
    final isAccountNameValid = _accountNameKey.currentState!.validate();
    final isAmountValid =
        args["source"] != "fav" ? _amountKey.currentState!.validate() : true;
    final isBillNumberValid =
        args["source"] != "fav"
            ? _billNumberKey.currentState!.validate()
            : true;

    if (isAccountNumberValid &&
        isAccountNameValid &&
        isAmountValid &&
        isBillNumberValid) {
      if (isFavSource) {
        // controller.addFavorites(args, 1);
      } else if (args["source"] == "pay" || args["source"] == "favorites") {
        controller.onPay(args);
      }
      // isFavSource ? controller.addFavorites(args) : controller.onPay(args);
    } else {
      CustomDialogStack.showError(
        Get.context!,
        "luvpark",
        "Please fill in all required fields.",
        () {
          Get.back();
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        backgroundColor: AppColorV2.lpBlueBrand,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: AppColorV2.lpBlueBrand,
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.light,
        ),
        title: Text(
          args["source"] == "fav" ? "Add to Favorites" : "Pay Biller",
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            Get.back();
            controller.clearFields();
          },
          icon: Icon(Iconsax.arrow_left, color: Colors.white),
        ),
      ),
      body:
          isLoading
              ? LoadingCard()
              : !isNetConn
              ? NoInternetConnected(onTap: getBalance)
              : Padding(
                padding: const EdgeInsets.all(15),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 20),
                      LuvpayText(
                        text: args["biller_name"],
                        color: AppColorV2.lpBlueBrand,
                        fontWeight: FontWeight.w600,
                      ),
                      LuvpayText(
                        text: args["biller_address"],
                        fontSize: 10,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Divider(color: AppColorV2.bodyTextColor),
                      SizedBox(height: 20),
                      LuvpayText(
                        text: "Account Number",
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                      Form(
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        key: _accountNumberKey,
                        child: CustomTextField(
                          controller: controller.billAccNo,
                          hintText: "Enter Account Number",
                          inputFormatters: <TextInputFormatter>[
                            LengthLimitingTextInputFormatter(15),
                            FilteringTextInputFormatter.digitsOnly,
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d*$'),
                            ),
                          ],
                          keyboardType:
                              Platform.isAndroid
                                  ? TextInputType.numberWithOptions(
                                    decimal: true,
                                  )
                                  : const TextInputType.numberWithOptions(
                                    signed: true,
                                    decimal: true,
                                  ),
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
                      ),
                      SizedBox(height: 10),
                      LuvpayText(
                        text: "Account Name",
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                      Form(
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        key: _accountNameKey,
                        child: CustomTextField(
                          controller: controller.billerAccountName,
                          hintText: "Enter Account Name",
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(30),
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[A-Za-z\s]'),
                            ),
                          ],
                          textCapitalization: TextCapitalization.characters,
                          keyboardType: TextInputType.name,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Account Name is required";
                            }
                            if ((value.startsWith(' ') ||
                                value.endsWith(' ') ||
                                value.endsWith('-') ||
                                value.endsWith('.'))) {
                              return "Account Name cannot start or end with a space";
                            }

                            return null;
                          },
                        ),
                      ),
                      Visibility(
                        visible: args["source"] != "fav",
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 10),
                            LuvpayText(
                              text: "Amount",
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                            Form(
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              key: _amountKey,
                              child: CustomTextField(
                                inputFormatters: <TextInputFormatter>[
                                  LengthLimitingTextInputFormatter(15),
                                  FilteringTextInputFormatter.digitsOnly,
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d*$'),
                                  ),
                                  AutoDecimalInputFormatter(),
                                ],
                                keyboardType:
                                    Platform.isAndroid
                                        ? TextInputType.numberWithOptions(
                                          decimal: true,
                                        )
                                        : const TextInputType.numberWithOptions(
                                          signed: true,
                                          decimal: true,
                                        ),
                                controller: controller.amount,
                                hintText: "Enter Amount",
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "Amount is required";
                                  }
                                  double? amount = double.tryParse(
                                    value.toString(),
                                  );
                                  if (value.startsWith('0')) {
                                    return "Invalid amount";
                                  }
                                  if (!Functions.isValidInput(
                                    amount!,
                                    args["service_fee"],
                                    double.parse(userBalance.toString()),
                                  )) {
                                    return "Input amount exceeds the allowable balance after service fee.";
                                  }
                                  if (amount >
                                      double.parse(userBalance.toString())) {
                                    return "Amount exceeds user balance";
                                  }

                                  return null;
                                },
                              ),
                            ),
                            LuvpayText(
                              text:
                                  args["service_fee"] == null
                                      ? ""
                                      : " Service Fee : ${args["service_fee"]}",
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                            ),
                            SizedBox(height: 15),
                            LuvpayText(
                              text: "Bill Number",
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                            Form(
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              key: _billNumberKey,
                              child: CustomTextField(
                                hintText: "Enter Bill Number",
                                controller: controller.billNo,
                                inputFormatters: <TextInputFormatter>[
                                  LengthLimitingTextInputFormatter(10),
                                  FilteringTextInputFormatter.digitsOnly,
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d*$'),
                                  ),
                                ],
                                keyboardType:
                                    Platform.isAndroid
                                        ? TextInputType.numberWithOptions(
                                          decimal: true,
                                        )
                                        : const TextInputType.numberWithOptions(
                                          signed: true,
                                          decimal: true,
                                        ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "Bill number is required";
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 30),
                      if (MediaQuery.of(context).viewInsets.bottom == 0)
                        CustomButton(
                          text: args["source"] == "fav" ? "Save" : "Pay",
                          onPressed: _submitForm,
                        ),
                    ],
                  ),
                ),
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
