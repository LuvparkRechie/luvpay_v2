import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../shared/widgets/colors.dart';
import '../../../shared/widgets/luvpay_text.dart';
import '../../../shared/widgets/custom_textfield.dart';
import '../../../shared/widgets/neumorphism.dart';
import '../../../shared/widgets/spacing.dart';
import '../controller.dart';

class AddFavoritesWidget extends GetView<BillersController> {
  AddFavoritesWidget({super.key});
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final nickName = TextEditingController();
    final accountNo = TextEditingController();
    final args = Get.arguments;
    return Scaffold(
      backgroundColor: AppColorV2.background,
      appBar: AppBar(
        elevation: 1,
        backgroundColor: AppColorV2.lpBlueBrand,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: AppColorV2.lpBlueBrand,
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.light,
        ),
        title: Text("Favorite Biller"),
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            Get.back();
          },
          icon: Icon(Iconsax.arrow_left, color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(15, 20, 15, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LuvpayText(
                  text: args["biller_name"],
                  color: AppColorV2.lpBlueBrand,
                  fontWeight: FontWeight.w600,
                ),
                spacing(height: 5),
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
                CustomTextField(
                  controller: accountNo,
                  hintText: "Enter Account Number",
                  inputFormatters: <TextInputFormatter>[
                    LengthLimitingTextInputFormatter(15),
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      final String newText = newValue.text.replaceAll(
                        RegExp(r'[^0-9-]'),
                        '',
                      );
                      if (newText != oldValue.text) {
                        return TextEditingValue(
                          text: newText,
                          selection: TextSelection.collapsed(
                            offset: newText.length,
                          ),
                        );
                      }

                      return oldValue;
                    }),
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
                SizedBox(height: 10),
                LuvpayText(
                  text: "Nickname",
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
                CustomTextField(
                  controller: nickName,
                  hintText: "Enter Nickname",
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(30),
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z\s]')),
                  ],
                  textCapitalization: TextCapitalization.characters,
                  keyboardType: TextInputType.name,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Nickname is required";
                    }
                    if ((value.startsWith(' ') ||
                        value.endsWith(' ') ||
                        value.endsWith('-') ||
                        value.endsWith('.'))) {
                      return "Nickname cannot start or end with a space";
                    }

                    return null;
                  },
                ),
                SizedBox(height: 30),
                CustomButton(
                  text: "Add to favorites",
                  onPressed: () async {
                    FocusManager.instance.primaryFocus?.unfocus();
                    await Future.delayed(Duration(milliseconds: 300));
                    if (formKey.currentState!.validate()) {
                      controller.addFavorites(
                        args,
                        args["biller_id"],
                        accountNo.text,
                        nickName.text,
                      );
                    }
                  },
                ),
              ],
            ),
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
