// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_contact_picker/model/contact.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../custom_widgets/alert_dialog.dart';
import '../../custom_widgets/app_color_v2.dart';
import '../../custom_widgets/custom_button.dart';
import '../../custom_widgets/custom_text_v2.dart';
import '../../custom_widgets/custom_textfield.dart';
import '../../custom_widgets/luvpay/custom_scaffold.dart';
import '../../custom_widgets/spacing.dart';
import '../../custom_widgets/variables.dart';
import '../../functions/functions.dart';
import 'controller.dart';

class WalletRechargeLoadScreen extends GetView<WalletRechargeLoadController> {
  const WalletRechargeLoadScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return CustomScaffoldV2(
      enableToolBar: true,
      appBarTitle: "Top up",
      onPressedLeading: () {
        controller.mobNum.clear();
        Get.back();
      },
      scaffoldBody: Obx(
        () => Form(
          key: controller.topUpKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 14),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(20),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  height: 70,
                  padding: EdgeInsets.all(20),
                  child: Image.asset(controller.arguments["image"]),
                ),
                SizedBox(height: 10),
                Divider(),
                SizedBox(height: 10),
                topupAccount(),
                SizedBox(height: 5),
                SizedBox(height: 14),
                DefaultText(text: "Amount", style: AppTextStyle.h3),
                CustomTextField(
                  controller: controller.amountController,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp("[0-9]")),
                    LengthLimitingTextInputFormatter(5),
                  ],
                  keyboardType:
                      Platform.isAndroid
                          ? TextInputType.number
                          : const TextInputType.numberWithOptions(
                            signed: true,
                            decimal: false,
                          ),
                  onChange: (d) {
                    controller.onTextChange();
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Amount is required";
                    }
                    if (double.parse(value.toString()) <
                        controller.minTopUp.value) {
                      return "Minimum of ${controller.minTopUp.value} tokens";
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 20),
                for (int i = 0; i < controller.padData.length; i += 3)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (
                        int j = i;
                        j < i + 3 && j < controller.padData.length;
                        j++
                      )
                        myPads(controller.padData[j], j),
                    ],
                  ),
                const SizedBox(height: 30),
                if (MediaQuery.of(context).viewInsets.bottom == 0)
                  CustomButton(
                    text: "Continue",
                    btnColor:
                        !controller.isActiveBtn.value
                            ? AppColorV2.lpBlueBrand.withValues(alpha: .7)
                            : AppColorV2.lpBlueBrand,
                    onPressed:
                        !controller.isActiveBtn.value
                            ? () {}
                            : () {
                              controller.onPay();
                            },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget topupAccount() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DefaultText(text: "Top up tokens for", style: AppTextStyle.h3),
        SizedBox(height: 10),
        Container(
          padding: EdgeInsets.all(10),
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(
              color:
                  controller.rname.text.toLowerCase().contains("unknown")
                      ? AppColorV2.incorrectState
                      : Colors.transparent,
            ),
            borderRadius: BorderRadius.circular(7),
            color:
                controller.rname.text == "Unknown user"
                    ? Color(0xFFFFDFDF)
                    : AppColorV2.lpBlueBrand.withValues(alpha: .1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  controller.userImage.value.isEmpty ||
                          controller.rname.text.toLowerCase().contains(
                            "unknown",
                          )
                      ? Image.asset(
                        height: 50,
                        "assets/images/no_whiteborder_person.png",
                      )
                      : CircleAvatar(
                        radius: 25,
                        backgroundColor:
                            controller.userImage.value.isEmpty
                                ? Colors.white
                                : null,
                        backgroundImage:
                            controller.userImage.value.isNotEmpty
                                ? MemoryImage(
                                  base64Decode(
                                    controller.userImage.value.toString(),
                                  ),
                                )
                                : null,
                      ),
                  Container(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DefaultText(
                          maxLines: 1,
                          text: controller.rname.text,

                          style: AppTextStyle.h3_f22,
                        ),

                        DefaultText(
                          maxLines: 1,
                          text:
                              controller.email.value.contains("null")
                                  ? "No email provided yet"
                                  : controller.email.value,
                          color: AppColorV2.bodyTextColor,
                        ),
                      ],
                    ),
                  ),
                  Container(width: 5),
                  // InkWell(
                  //   onTap: () {
                  //     Get.bottomSheet(
                  //       UserssBottomsheet(
                  //         index: 2,
                  //         cb: (index) {
                  //           Functions.popPage(index);
                  //         },
                  //       ),
                  //       isDismissible: false,
                  //     );
                  //   },
                  //   child: Icon(
                  //     LucideIcons.edit,
                  //     size: 20,
                  //     color:
                  //         controller.rname.text == "Unknown user"
                  //             ? AppColorV2.incorrectState
                  //             : AppColorV2.lpBlueBrand,
                  //   ),
                  // ),
                ],
              ),
              Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  DefaultText(text: "Mobile Number"),
                  Align(
                    alignment: Alignment.centerRight,
                    child: DefaultText(
                      text: "0${controller.mobNum.text}",
                      color: AppColorV2.primaryTextColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Visibility(
          visible: controller.rname.text == "Unknown user",

          child: Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: DefaultText(
              text: "Invalid account. Please put a different number.",
              color: AppColorV2.incorrectState,
            ),
          ),
        ),
      ],
    );
  }

  Widget myPads(data, int index) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(3.0),
        child: InkWell(
          onTap: () {
            controller.pads(data["value"]);
          },
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 10, 22, 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: Colors.grey.shade200, width: 1),
              color: data["is_active"] ? AppColorV2.lpBlueBrand : Colors.white,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                DefaultText(
                  maxLines: 1,
                  minFontSize: 8,
                  text: "${data["value"]}",
                  fontWeight: FontWeight.w700,
                  color: data["is_active"] ? Colors.white : Colors.black,
                ),
                DefaultText(
                  text: "Token",
                  fontWeight: FontWeight.w500,
                  color: data["is_active"] ? Colors.white : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ignore: must_be_immutable
class PaymentMethodType extends StatelessWidget {
  final Function cabllBack;
  PaymentMethodType({super.key, required this.cabllBack});

  List paymentType = [
    {"type": "UB-Online", "value": "ub online"},
    {"type": "Instapay", "value": "instapay"},
    {"type": "Pay Gate", "value": "paygate"},
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 15, vertical: 20),
          color: Colors.white,

          width: double.infinity,
          child: Column(
            children:
                paymentType.map((e) {
                  return ListTile(
                    onTap: () {
                      Get.back();
                      cabllBack(e["value"]);
                    },
                    title: DefaultText(text: e["type"]),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }
}

class UserssBottomsheet extends StatefulWidget {
  final int index;
  final Function cb;
  final bool? isValidUser;
  const UserssBottomsheet({
    super.key,
    required this.index,
    required this.cb,
    this.isValidUser,
  });

  @override
  State<UserssBottomsheet> createState() => _UsersBottomsheetState();
}

class _UsersBottomsheetState extends State<UserssBottomsheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController mobileNo = TextEditingController();
  final ct = Get.put(WalletRechargeLoadController());

  @override
  void initState() {
    super.initState();
  }

  Future<void> selectSingleContact() async {
    Contact? selectedContact = await ct.contactPicker.selectContact();
    if (selectedContact != null) {
      ct.contact.value = selectedContact;

      if (ct.contact.value != null) {
        String contactString = ct.contact.value.toString();
        String mobileNumber = contactString.replaceAll(
          RegExp(r'^.*\[\s*|\s*\].*$'),
          '',
        );

        mobileNumber = mobileNumber.replaceAll(" ", "");
        if (mobileNumber.startsWith('0')) {
          mobileNumber = mobileNumber.substring(1);
        } else {
          mobileNumber = mobileNumber.substring(3);
        }

        mobileNo.text = mobileNumber;
        ct.mobNum.text = mobileNo.text.replaceAll(" ", "");
        if (ct.mobNum.text.length != 10) {
          CustomDialogStack.showError(
            context,
            "Error",
            "Invalid mobile number format",
            () {
              Get.back();
            },
          );
        } else {
          ct.onSearchChanged(
            ct.mobNum.text.replaceAll(" ", ""),
            false,
            from: "contacts",
          );
          CustomDialogStack.showLoading(context);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Container(
        padding: EdgeInsets.only(top: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          color: AppColorV2.lpBlueBrand,
        ),
        child: Wrap(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  DefaultText(
                    text: "Top up tokens for",
                    style: AppTextStyle.body1,
                    color: AppColorV2.background,
                  ),
                  InkWell(
                    onTap: () {
                      Functions.popPage(widget.index == 1 ? 2 : 1);
                    },
                    child: SvgPicture.asset("assets/images/close_button.svg"),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(19),
              decoration: BoxDecoration(color: AppColorV2.background),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  physics: BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DefaultText(
                        text: "Recipient Number",
                        style: AppTextStyle.h3,
                      ),
                      CustomMobileNumber(
                        hintText: "Enter mobile number",
                        controller: mobileNo,
                        inputFormatters: [Variables.maskFormatter],
                        onChange: (value) {
                          setState(() {
                            value.replaceAll(" ", "");
                          });
                        },
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Field is required';
                          }
                          if (value.toString().replaceAll(" ", "").length <
                              10) {
                            return 'Invalid mobile number';
                          }
                          if (value.toString().replaceAll(" ", "")[0] == '0') {
                            return 'Invalid mobile number';
                          }

                          return null;
                        },
                      ),
                      spacing(height: 20),
                      DefaultText(
                        text: "Choose other method",
                        style: AppTextStyle.h3,
                      ),
                      spacing(height: 8),
                      SingleChildScrollView(
                        physics: BouncingScrollPhysics(),
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                              onTap: () {
                                FocusManager.instance.primaryFocus!.unfocus();

                                ct.requestCameraPermission();
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppColorV2.bodyTextColor.withAlpha(
                                      50,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      color: AppColorV2.lpBlueBrand,
                                      LucideIcons.qrCode,
                                    ),
                                    SizedBox(width: 5),
                                    DefaultText(
                                      text: "Scan QR Code",
                                      style: AppTextStyle.body1,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            InkWell(
                              onTap: () {
                                selectSingleContact();
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppColorV2.bodyTextColor.withAlpha(
                                      50,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      color: AppColorV2.lpBlueBrand,
                                      LucideIcons.userSquare2,
                                    ),
                                    SizedBox(width: 5),
                                    DefaultText(
                                      text: "From Contacts",
                                      style: AppTextStyle.body1,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 30),
                      Visibility(
                        visible: MediaQuery.of(context).viewInsets.bottom == 0,
                        child: CustomButton(
                          isInactive: mobileNo.text.length != 12,
                          text: "Proceed",
                          onPressed: () {
                            if (_formKey.currentState?.validate() ?? false) {
                              ct.mobNum.text = mobileNo.text.replaceAll(
                                " ",
                                "",
                              );
                              ct.onSearchChanged(
                                ct.mobNum.text,
                                false,
                                from: "proceed",
                              );
                            }
                            CustomDialogStack.showLoading(context);
                          },
                        ),
                      ),
                      SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
