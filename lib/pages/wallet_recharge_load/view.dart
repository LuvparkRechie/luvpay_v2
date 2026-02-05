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
import '../../custom_widgets/luvpay/custom_button.dart';
import '../../custom_widgets/custom_text_v2.dart';
import '../../custom_widgets/custom_textfield.dart';
import '../../custom_widgets/luvpay/custom_scaffold.dart';
import '../../custom_widgets/spacing.dart';
import '../../custom_widgets/variables.dart';
import '../../functions/functions.dart';
import 'controller.dart';

class WalletRechargeLoadScreen extends GetView<WalletRechargeLoadController> {
  const WalletRechargeLoadScreen({super.key});

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  Color _surface(BuildContext context) {
    return AppColorV2.background;
  }

  Color _borderSoft(BuildContext context) {
    return _isDark(context)
        ? Colors.white.withAlpha(14)
        : Colors.black.withAlpha(12);
  }

  Color _shadowDark(BuildContext context) {
    return _isDark(context)
        ? Colors.black.withAlpha(80)
        : Colors.black.withAlpha(28);
  }

  Color _shadowLight(BuildContext context) {
    return _isDark(context)
        ? Colors.white.withAlpha(26)
        : Colors.white.withAlpha(180);
  }

  Color _textPrimary(BuildContext context) {
    return AppColorV2.primaryTextColor;
  }

  Color _textSecondary(BuildContext context) {
    return AppColorV2.bodyTextColor;
  }

  Color _chipActiveText(BuildContext context) {
    return Colors.white;
  }

  Color _chipInactiveText(BuildContext context) {
    return _textPrimary(context);
  }

  BoxDecoration _neoCard(
    BuildContext context, {
    double radius = 12,
    Color? color,
    bool inset = false,
  }) {
    final base = color ?? _surface(context);

    return BoxDecoration(
      color: base,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: _borderSoft(context)),
      boxShadow:
          inset
              ? [
                BoxShadow(
                  color: _shadowDark(
                    context,
                  ).withAlpha(_isDark(context) ? 90 : 18),
                  blurRadius: 10,
                  offset: Offset(3, 3),
                ),
                BoxShadow(
                  color: _shadowLight(
                    context,
                  ).withAlpha(_isDark(context) ? 34 : 210),
                  blurRadius: 10,
                  offset: Offset(-3, -3),
                ),
              ]
              : [
                BoxShadow(
                  color: _shadowDark(context),
                  blurRadius: 12,
                  offset: Offset(6, 6),
                ),
                BoxShadow(
                  color: _shadowLight(context),
                  blurRadius: 12,
                  offset: Offset(-6, -6),
                ),
              ],
    );
  }

  BoxDecoration _neoChip(
    BuildContext context, {
    double radius = 10,
    required bool active,
  }) {
    final base = _surface(context);

    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      color: active ? AppColorV2.lpBlueBrand : base,
      border: Border.all(
        color: active ? Colors.transparent : _borderSoft(context),
        width: 1,
      ),
      boxShadow:
          active
              ? [
                BoxShadow(
                  color: _shadowDark(
                    context,
                  ).withAlpha(_isDark(context) ? 120 : 30),
                  blurRadius: 10,
                  offset: Offset(4, 4),
                ),
              ]
              : [
                BoxShadow(
                  color: _shadowDark(
                    context,
                  ).withAlpha(_isDark(context) ? 95 : 20),
                  blurRadius: 10,
                  offset: Offset(4, 4),
                ),
                BoxShadow(
                  color: _shadowLight(
                    context,
                  ).withAlpha(_isDark(context) ? 34 : 210),
                  blurRadius: 10,
                  offset: Offset(-4, -4),
                ),
              ],
    );
  }

  BoxDecoration _recipientNeo(BuildContext context, {required bool isUnknown}) {
    if (isUnknown) {
      return BoxDecoration(
        color: _isDark(context) ? Color(0xFF3B1F1F) : Color(0xFFFFDFDF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColorV2.incorrectState.withAlpha(140)),
        boxShadow: [
          BoxShadow(
            color: _shadowDark(context).withAlpha(_isDark(context) ? 120 : 18),
            blurRadius: 10,
            offset: Offset(4, 4),
          ),
          BoxShadow(
            color: _shadowLight(context).withAlpha(_isDark(context) ? 34 : 210),
            blurRadius: 10,
            offset: Offset(-4, -4),
          ),
        ],
      );
    }

    return BoxDecoration(
      color: _surface(context),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _borderSoft(context)),
      boxShadow: [
        BoxShadow(
          color: _shadowDark(context).withAlpha(_isDark(context) ? 95 : 18),
          blurRadius: 12,
          offset: Offset(6, 6),
        ),
        BoxShadow(
          color: _shadowLight(context).withAlpha(_isDark(context) ? 34 : 210),
          blurRadius: 12,
          offset: Offset(-6, -6),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final imgPath = controller.arguments["image"];

    return CustomScaffoldV2(
      enableToolBar: true,
      appBarTitle: "Top up",
      onPressedLeading: () {
        controller.mobNum.clear();
        Get.back();
      },
      scaffoldBody: Form(
        key: controller.topUpKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RepaintBoundary(
                child: Container(
                  decoration: _neoCard(
                    context,
                    radius: 12,
                    color: _surface(context),
                  ),
                  height: 70,
                  width: MediaQuery.of(context).size.width / 2,
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: Image.asset(
                      imgPath,
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 10),
              Divider(
                color:
                    _isDark(context)
                        ? Colors.white.withAlpha(14)
                        : Colors.black.withAlpha(18),
              ),
              SizedBox(height: 10),

              Obx(() => topupAccount(context)),

              SizedBox(height: 14),
              DefaultText(text: "Amount", style: AppTextStyle.h3(context)),
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
                onChange: (d) => controller.onTextChange(),
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

              Obx(() {
                return Column(
                  children: [
                    for (int i = 0; i < controller.padData.length; i += 3)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          for (
                            int j = i;
                            j < i + 3 && j < controller.padData.length;
                            j++
                          )
                            myPads(context, controller.padData[j], j),
                        ],
                      ),
                  ],
                );
              }),

              const SizedBox(height: 30),

              Obx(() {
                if (MediaQuery.of(context).viewInsets.bottom != 0) {
                  return SizedBox.shrink();
                }
                final inactive = !controller.isActiveBtn.value;

                return CustomButton(
                  text: "Continue",
                  btnColor:
                      inactive
                          ? AppColorV2.lpBlueBrand.withValues(alpha: .7)
                          : AppColorV2.lpBlueBrand,
                  onPressed: inactive ? () {} : () => controller.onPay(),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget topupAccount(BuildContext context) {
    final isUnknown = controller.rname.text.toLowerCase().contains("unknown");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DefaultText(text: "Top up tokens for", style: AppTextStyle.h3(context)),
        SizedBox(height: 10),
        Container(
          padding: EdgeInsets.all(12),
          width: double.infinity,
          decoration: _recipientNeo(context, isUnknown: isUnknown),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  controller.userImage.value.isEmpty || isUnknown
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
                        DefaultText(maxLines: 1, text: controller.rname.text),
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
                ],
              ),
              Divider(
                color:
                    Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withAlpha(14)
                        : Colors.black.withAlpha(18),
              ),
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

  Widget myPads(BuildContext context, data, int index) {
    final active = data["is_active"] == true;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(3.0),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => controller.pads(data["value"]),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 160),
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 12),
            decoration: _neoChip(context, active: active),
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
                  color:
                      active
                          ? _chipActiveText(context)
                          : _chipInactiveText(context),
                ),
                DefaultText(
                  text: "Token",
                  fontWeight: FontWeight.w500,
                  color:
                      active
                          ? _chipActiveText(context)
                          : _textSecondary(context),
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

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  Color _borderSoft(BuildContext context) =>
      _isDark(context)
          ? Colors.white.withAlpha(14)
          : Colors.black.withAlpha(10);

  Color _shadowDark(BuildContext context) =>
      _isDark(context)
          ? Colors.black.withAlpha(95)
          : Colors.black.withAlpha(16);

  Color _shadowLight(BuildContext context) =>
      _isDark(context)
          ? Colors.white.withAlpha(34)
          : Colors.white.withAlpha(210);

  BoxDecoration _neoSheetTile(BuildContext context) {
    return BoxDecoration(
      color: AppColorV2.background,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _borderSoft(context)),
      boxShadow: [
        BoxShadow(
          color: _shadowDark(context),
          blurRadius: 10,
          offset: Offset(5, 5),
        ),
        BoxShadow(
          color: _shadowLight(context),
          blurRadius: 10,
          offset: Offset(-5, -5),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 15, vertical: 20),
          color: AppColorV2.background,
          width: double.infinity,
          child: Column(
            children:
                paymentType.map((e) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Get.back();
                        cabllBack(e["value"]);
                      },
                      child: Container(
                        decoration: _neoSheetTile(context),
                        child: ListTile(
                          title: DefaultText(text: e["type"]),
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            color: AppColorV2.bodyTextColor,
                          ),
                        ),
                      ),
                    ),
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

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  Color _borderSoft(BuildContext context) =>
      _isDark(context)
          ? Colors.white.withAlpha(14)
          : Colors.black.withAlpha(10);

  Color _shadowDark(BuildContext context) =>
      _isDark(context)
          ? Colors.black.withAlpha(100)
          : Colors.black.withAlpha(18);

  Color _shadowLight(BuildContext context) =>
      _isDark(context)
          ? Colors.white.withAlpha(34)
          : Colors.white.withAlpha(210);

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
            () => Get.back(),
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

  BoxDecoration _neoActionPill(BuildContext context) {
    return BoxDecoration(
      color: AppColorV2.background,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _borderSoft(context)),
      boxShadow: [
        BoxShadow(
          color: _shadowDark(context),
          blurRadius: 10,
          offset: Offset(4, 4),
        ),
        BoxShadow(
          color: _shadowLight(context),
          blurRadius: 10,
          offset: Offset(-4, -4),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Container(
        padding: EdgeInsets.only(top: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          color: AppColorV2.lpBlueBrand,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(_isDark(context) ? 110 : 35),
              blurRadius: 14,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Wrap(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  DefaultText(
                    text: "Top up tokens for",
                    style: AppTextStyle.body1(context),
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
              decoration: BoxDecoration(
                color: AppColorV2.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                boxShadow: [
                  BoxShadow(
                    color: _shadowLight(
                      context,
                    ).withAlpha(_isDark(context) ? 34 : 220),
                    blurRadius: 12,
                    offset: Offset(-6, -6),
                  ),
                  BoxShadow(
                    color: _shadowDark(
                      context,
                    ).withAlpha(_isDark(context) ? 95 : 16),
                    blurRadius: 12,
                    offset: Offset(6, 6),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  physics: BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DefaultText(
                        text: "Recipient Number",
                        style: AppTextStyle.h3(context),
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
                          if (value!.isEmpty) return 'Field is required';
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
                        style: AppTextStyle.h3(context),
                      ),
                      spacing(height: 8),
                      SingleChildScrollView(
                        physics: BouncingScrollPhysics(),
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                FocusManager.instance.primaryFocus!.unfocus();
                                ct.requestCameraPermission();
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: _neoActionPill(context),
                                child: Row(
                                  children: [
                                    Icon(
                                      color: AppColorV2.lpBlueBrand,
                                      LucideIcons.qrCode,
                                    ),
                                    SizedBox(width: 5),
                                    DefaultText(
                                      text: "Scan QR Code",
                                      style: AppTextStyle.body1(context),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => selectSingleContact(),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: _neoActionPill(context),
                                child: Row(
                                  children: [
                                    Icon(
                                      color: AppColorV2.lpBlueBrand,
                                      LucideIcons.userSquare2,
                                    ),
                                    SizedBox(width: 5),
                                    DefaultText(
                                      text: "From Contacts",
                                      style: AppTextStyle.body1(context),
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
