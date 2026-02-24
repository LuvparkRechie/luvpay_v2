import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/formatters/formatter_utils.dart';
import 'package:flutter_native_contact_picker/model/contact.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../auth/authentication.dart';
import '../../core/utils/functions/functions.dart';
import '../../shared/dialogs/dialogs.dart';
import '../../shared/widgets/colors.dart';
import '../../shared/widgets/custom_scaffold.dart';
import '../../shared/widgets/custom_textfield.dart';
import '../../shared/widgets/luvpay_loading.dart';
import '../../shared/widgets/luvpay_text.dart';
import '../../shared/widgets/neumorphism.dart';
import '../../shared/widgets/variables.dart';
import 'controller.dart';

class WalletSend extends GetView<WalletSendController> {
  const WalletSend({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Obx(
      () => CustomScaffoldV2(
        padding: EdgeInsets.zero,
        canPop: false,
        enableToolBar: true,
        appBarTitle: "Transfer Token",
        onPressedLeading: () {
          if (controller.recipientData.isNotEmpty &&
              controller.recipientData[0]["mobile_no"] != null) {
            Get.back();
          } else if (!controller.isLoading.value == true) {
            () {};
          }
        },
        scaffoldBody: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 20),
          child: page1(context, cs, isDark),
        ),
      ),
    );
  }

  Widget page1(BuildContext context, ColorScheme cs, bool isDark) {
    final onSurface = cs.onSurface;
    final onSurfaceVar = cs.onSurfaceVariant;

    return ScrollConfiguration(
      behavior: ScrollBehavior().copyWith(overscroll: false),
      child: SingleChildScrollView(
        child:
            controller.isLoading.value
                ? LoadingCard()
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Form(
                      key: controller.formKeySend,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 14),

                          UsersBottomsheet(isEdit: false),

                          const SizedBox(height: 14),

                          Obx(() {
                            final recipientReady =
                                controller.recipientData.isNotEmpty &&
                                controller.isValidUser.value == true &&
                                controller.recipientData[0]["mobile_no"] !=
                                    null;

                            if (!recipientReady) return const SizedBox.shrink();

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                LuvpayText(text: "Amount", color: onSurface),
                                CustomTextField(
                                  hintText: "Enter amount",
                                  controller: controller.tokenAmount,
                                  inputFormatters: [
                                    AutoDecimalInputFormatter(),
                                  ],
                                  keyboardType:
                                      Platform.isAndroid
                                          ? TextInputType.number
                                          : const TextInputType.numberWithOptions(
                                            signed: true,
                                            decimal: false,
                                          ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Amount is required";
                                    }

                                    double parsedValue;
                                    try {
                                      parsedValue = double.parse(value);
                                    } catch (_) {
                                      return "Invalid amount";
                                    }

                                    double availableBalance;
                                    try {
                                      availableBalance = double.parse(
                                        controller.userData.isEmpty
                                            ? "0.0"
                                            : controller
                                                .userData[0]["amount_bal"]
                                                .toString(),
                                      );
                                    } catch (_) {
                                      return "Error retrieving balance";
                                    }

                                    if (parsedValue < 10) {
                                      return "Amount can’t be less than 10";
                                    }
                                    if (parsedValue > availableBalance) {
                                      return "You don't have enough balance to proceed";
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 14),

                                Row(
                                  children: [
                                    LuvpayText(
                                      text: "Description",
                                      color: onSurface,
                                    ),
                                    const SizedBox(width: 5),
                                    LuvpayText(
                                      text: "(Optional)",
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: onSurfaceVar.withOpacity(0.8),
                                    ),
                                  ],
                                ),

                                CustomTextField(
                                  inputFormatters: [
                                    LengthLimitingTextInputFormatter(30),
                                  ],
                                  maxLength: 30,
                                  controller: controller.message,
                                  maxLines: 5,
                                  minLines: 3,
                                ),

                                const SizedBox(height: 30),

                                CustomButton(
                                  text: "Continue",
                                  btnColor: AppColorV2.lpBlueBrand,
                                  onPressed: () async {
                                    if (controller.formKeySend.currentState!
                                        .validate()) {
                                      final item =
                                          await Authentication().getUserData2();

                                      if (controller.recipientData.isNotEmpty &&
                                          item["mobile_no"].toString() ==
                                              controller
                                                  .recipientData[0]["mobile_no"]
                                                  .toString()) {
                                        controller.isValidUser.value = false;
                                        return;
                                      }

                                      if (double.parse(
                                            controller.userData.isEmpty
                                                ? "0.0"
                                                : controller
                                                    .userData[0]["amount_bal"]
                                                    .toString(),
                                          ) <
                                          double.parse(
                                            controller.tokenAmount.text
                                                .toString()
                                                .removeAllWhitespace,
                                          )) {
                                        CustomDialogStack.showSnackBar(
                                          Get.context!,
                                          "Insufficient balance.",
                                          Colors.red,
                                          () {},
                                        );
                                        return;
                                      }

                                      await controller.proceedToOtp();
                                    }
                                  },
                                ),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}

class UsersBottomsheet extends StatefulWidget {
  final int? index;
  final bool? isEdit;
  final Function? cb;
  final bool? isValidUser;

  const UsersBottomsheet({
    super.key,
    this.index,
    this.cb,
    this.isValidUser,
    this.isEdit,
  });

  @override
  State<UsersBottomsheet> createState() => _UsersBottomsheetState();
}

class _UsersBottomsheetState extends State<UsersBottomsheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController mobileNo = TextEditingController();
  final WalletSendController ct = Get.find<WalletSendController>();

  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    mobileNo.dispose();
    super.dispose();
  }

  Future<void> selectSingleContact() async {
    Contact? selectedContact = await ct.contactPicker.selectContact();
    if (selectedContact != null) {
      ct.contact.value = selectedContact;

      final contactString = ct.contact.value.toString();
      String mobileNumber = contactString.replaceAll(RegExp(r'\D+'), '');

      if (mobileNumber.startsWith('63')) {
        mobileNumber = '0' + mobileNumber.substring(2);
      }

      if (mobileNumber.startsWith('09') || mobileNumber.startsWith('9')) {
        mobileNumber = '63' + mobileNumber.substring(1);
      }

      mobileNo.text = mobileNumber.substring(2).replaceAll(" ", "");

      if (mobileNo.text.length != 10) {
        CustomDialogStack.showError(
          context,
          "Error",
          "Invalid mobile number format",
          () => Get.back(),
        );
        return;
      }

      await ct.getRecipient(mobileNumber);
      _formKey.currentState?.validate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final sheetBodyBg = cs.surface;
    final onSheetBody = cs.onSurface;

    return PopScope(
      canPop: false,
      child: Wrap(
        children: [
          Container(
            decoration: BoxDecoration(color: sheetBodyBg),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LuvpayText(text: "Recipient Number", color: onSheetBody),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomMobileNumber(
                          hintText: "Enter mobile number",
                          controller: mobileNo,
                          inputFormatters: [Variables.maskFormatter],
                          onChange: (value) {
                            final clean = value.replaceAll(" ", "");
                            ct.isValidUser.value = true;

                            if (clean.length < 10) {
                              ct.recipientData.clear();
                              ct.userName.value = "";
                            }

                            _debounce?.cancel();
                            _debounce = Timer(
                              const Duration(milliseconds: 450),
                              () async {
                                if (clean.length == 10) {
                                  final ok =
                                      _formKey.currentState?.validate() ??
                                      false;
                                  if (!ok) return;

                                  await ct.getRecipient("63$clean");
                                  _formKey.currentState?.validate();
                                }
                              },
                            );
                          },
                          validator: (value) {
                            final clean = value?.replaceAll(" ", "") ?? "";

                            if (clean.isEmpty) return 'Field is required';
                            if (clean.length != 10)
                              return 'Invalid mobile number';
                            if (clean.startsWith('0'))
                              return 'Invalid mobile number';

                            return null;
                          },
                          suffixBgC: Colors.transparent,
                          suffixWidget: Padding(
                            padding: const EdgeInsets.only(right: 19),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                InkWell(
                                  onTap: () {
                                    FocusManager.instance.primaryFocus
                                        ?.unfocus();
                                    ct.requestCameraPermission();
                                  },
                                  child: Icon(LucideIcons.qrCode),
                                ),
                                SizedBox(width: 14),
                                InkWell(
                                  onTap: selectSingleContact,
                                  child: Icon(LucideIcons.contact),
                                ),
                              ],
                            ),
                          ),

                          onIconTap: () {},
                        ),

                        ValueListenableBuilder<TextEditingValue>(
                          valueListenable: mobileNo,
                          builder: (context, value, _) {
                            final clean = value.text.replaceAll(" ", "");

                            if (clean.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Row(
                                  children: [
                                    Icon(
                                      LucideIcons.info,
                                      size: 14,
                                      color: cs.onSurfaceVariant.withOpacity(
                                        0.75,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: LuvpayText(
                                        text:
                                            "Tip: Use QR or Contacts on the right to fill faster.",
                                        fontSize: 12,
                                        color: cs.onSurfaceVariant.withOpacity(
                                          0.85,
                                        ),
                                        maxLines: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            if (clean.length < 10) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Row(
                                  children: [
                                    Icon(
                                      LucideIcons.keyboard,
                                      size: 14,
                                      color: cs.onSurfaceVariant.withOpacity(
                                        0.75,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: LuvpayText(
                                        text:
                                            "Enter ${10 - clean.length} more digit(s) to verify",
                                        fontSize: 12,
                                        color: cs.onSurfaceVariant.withOpacity(
                                          0.85,
                                        ),
                                        maxLines: 1,
                                      ),
                                    ),
                                    Text(
                                      "${clean.length}/10",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: cs.onSurfaceVariant.withOpacity(
                                          0.85,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return Obx(() {
                              final loading = ct.isRecipientLookupLoading.value;
                              final valid = ct.isValidUser.value;
                              final name = ct.userName.value;
                              final hasRecipient =
                                  ct.recipientData.isNotEmpty &&
                                  ct.recipientData[0]["mobile_no"] != null;

                              if (loading) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: Row(
                                    children: [
                                      const SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      LuvpayText(
                                        text: "Checking…",
                                        fontSize: 12,
                                        color: cs.onSurfaceVariant.withOpacity(
                                          0.85,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              if (!valid && hasRecipient) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.error_outline_rounded,
                                        size: 16,
                                        color: AppColorV2.incorrectState,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: LuvpayText(
                                          text:
                                              "Invalid account. Please enter a different number.",
                                          fontSize: 12,
                                          color: AppColorV2.incorrectState,
                                          maxLines: 2,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              if (valid && hasRecipient) {
                                final displayName =
                                    (name.isEmpty ||
                                            name.toLowerCase().contains(
                                              "unknown",
                                            ))
                                        ? "Verified account"
                                        : name;

                                final isUnverified = displayName
                                    .toLowerCase()
                                    .contains("unverified");

                                return Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.verified_rounded,
                                        size: 16,
                                        color:
                                            isUnverified
                                                ? cs.onSurfaceVariant
                                                : AppColorV2.lpBlueBrand,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: LuvpayText(
                                          text: displayName,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color:
                                              isUnverified
                                                  ? cs.onSurfaceVariant
                                                  : AppColorV2.lpBlueBrand,
                                          maxLines: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              return const SizedBox.shrink();
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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
