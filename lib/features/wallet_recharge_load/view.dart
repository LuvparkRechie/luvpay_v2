// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_contact_picker/model/contact.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:luvpay/shared/dialogs/dialogs.dart';
import '../../shared/widgets/colors.dart';
import 'package:luvpay/shared/widgets/neumorphism.dart';

import '../../shared/widgets/luvpay_text.dart';
import '../../shared/widgets/custom_textfield.dart';
import '../../shared/widgets/custom_scaffold.dart';
import '../../shared/widgets/spacing.dart';
import '../../shared/widgets/variables.dart';
import '../../core/utils/functions/functions.dart';
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
              LuvpayText(text: "Amount", style: AppTextStyle.h3(context)),
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
        LuvpayText(text: "Top up tokens for", style: AppTextStyle.h3(context)),
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
                        LuvpayText(maxLines: 1, text: controller.rname.text),
                        LuvpayText(
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
                  LuvpayText(text: "Mobile Number"),
                  Align(
                    alignment: Alignment.centerRight,
                    child: LuvpayText(
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
            child: LuvpayText(
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
                LuvpayText(
                  maxLines: 1,
                  minFontSize: 8,
                  text: "${data["value"]}",
                  fontWeight: FontWeight.w700,
                  color:
                      active
                          ? _chipActiveText(context)
                          : _chipInactiveText(context),
                ),
                LuvpayText(
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
                          title: LuvpayText(text: e["type"]),
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
