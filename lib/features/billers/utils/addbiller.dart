// ignore_for_file: prefer_const_constructors

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../shared/widgets/colors.dart';
import '../../../shared/widgets/neumorphism.dart';
import '../../../shared/widgets/luvpay_text.dart';
import '../../../shared/widgets/custom_textfield.dart';
import '../../my_account/utils/view.dart';
import '../controller.dart';

class AddBiller extends StatefulWidget {
  const AddBiller({super.key});

  @override
  State<AddBiller> createState() => _PayBillState();
}

class _PayBillState extends State<AddBiller> {
  final controller = Get.put(BillersController());

  @override
  void initState() {
    super.initState();
  }

  void _submitForm() {}

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
        title: Text("Pay Biller"),
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            Get.back();
            controller.clearFields();
          },
          icon: Icon(Iconsax.arrow_left, color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LuvpayText(
                text: "",
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
              Divider(color: AppColorV2.bodyTextColor),
              SizedBox(height: 5),
              LuvpayText(
                text: "Account Number",
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
              Form(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: CustomTextField(
                  controller: controller.billAccNo,
                  hintText: "Enter Account Number",
                  inputFormatters: <TextInputFormatter>[
                    LengthLimitingTextInputFormatter(15),
                    FilteringTextInputFormatter.digitsOnly,
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                  ],
                  keyboardType:
                      Platform.isAndroid
                          ? TextInputType.numberWithOptions(decimal: true)
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
                child: CustomTextField(
                  controller: controller.billerAccountName,
                  hintText: "Enter Account Name",
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(30),
                    SimpleNameFormatter(),
                  ],
                  textCapitalization: TextCapitalization.characters,
                  keyboardType: TextInputType.name,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Account Name is required";
                    }
                    if ((value.endsWith(' ') ||
                        value.endsWith('-') ||
                        value.endsWith('.'))) {
                      return "Account Name cannot end with a space, hyphen, or period";
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(height: 10),
              LuvpayText(
                text: "Amount",
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
              Form(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: CustomTextField(
                  inputFormatters: <TextInputFormatter>[
                    LengthLimitingTextInputFormatter(15),
                    FilteringTextInputFormatter.digitsOnly,
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                    AutoDecimalInputFormatter(),
                  ],
                  keyboardType:
                      Platform.isAndroid
                          ? TextInputType.numberWithOptions(decimal: true)
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
                    final amount = double.tryParse(value);
                    if (amount == null || value.startsWith('0')) {
                      return "Invalid amount";
                    }
                    return null;
                  },
                ),
              ),
              LuvpayText(text: "", fontSize: 10, fontWeight: FontWeight.w400),
              SizedBox(height: 10),
              LuvpayText(
                text: "Bill Number",
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
              Form(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: CustomTextField(
                  hintText: "Enter Bill Number",
                  controller: controller.billNo,
                  inputFormatters: <TextInputFormatter>[
                    LengthLimitingTextInputFormatter(10),
                    FilteringTextInputFormatter.digitsOnly,
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                  ],
                  keyboardType:
                      Platform.isAndroid
                          ? TextInputType.numberWithOptions(decimal: true)
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
              SizedBox(height: 30),
              if (MediaQuery.of(context).viewInsets.bottom == 0)
                CustomButton(text: "Pay", onPressed: _submitForm),
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
