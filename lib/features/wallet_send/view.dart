import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/formatters/formatter_utils.dart';
import 'package:flutter_native_contact_picker/model/contact.dart';
import 'package:flutter_svg/svg.dart';
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        Image.asset("assets/images/wallet_transfer_card.png"),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(
                                    isDark ? 0.14 : 0.16,
                                  ),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.account_balance_wallet_rounded,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 8),
                                    LuvpayText(
                                      text: "luvpay Wallet",
                                      style: AppTextStyle.body1(context),
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      maxFontSize: 12,
                                      minFontSize: 10,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              Obx(() {
                                String balanceText =
                                    !controller.isNetConn.value
                                        ? "........"
                                        : toCurrencyString(
                                          controller.userData.isEmpty
                                              ? "0.00"
                                              : controller
                                                  .userData[0]["amount_bal"]
                                                  .toString(),
                                        );

                                String mainPart = balanceText.split('.')[0];
                                String decimalPart =
                                    balanceText.split('.').length > 1
                                        ? '.${balanceText.split('.')[1]}'
                                        : '';

                                return RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                    children: [
                                      TextSpan(
                                        text:
                                            !controller.isNetConn.value
                                                ? "....."
                                                : mainPart,
                                      ),
                                      TextSpan(
                                        text:
                                            !controller.isNetConn.value
                                                ? ".."
                                                : decimalPart,
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),

                    AnimatedCrossFade(
                      firstChild: const SizedBox.shrink(),
                      secondChild: secondChild(context, cs, isDark),
                      crossFadeState:
                          controller.recipientData.isEmpty
                              ? CrossFadeState.showFirst
                              : CrossFadeState.showSecond,
                      duration: const Duration(milliseconds: 200),
                    ),

                    Form(
                      key: controller.formKeySend,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 14),
                          LuvpayText(text: "Amount", color: onSurface),
                          CustomTextField(
                            hintText: "Enter amount",
                            controller: controller.tokenAmount,
                            inputFormatters: [AutoDecimalInputFormatter()],
                            keyboardType:
                                Platform.isAndroid
                                    ? TextInputType.number
                                    : const TextInputType.numberWithOptions(
                                      signed: true,
                                      decimal: false,
                                    ),
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return "Amount is required";

                              double parsedValue;
                              try {
                                parsedValue = double.parse(value);
                              } catch (e) {
                                return "Invalid amount";
                              }

                              double availableBalance;
                              try {
                                availableBalance = double.parse(
                                  controller.userData.isEmpty
                                      ? "0.0"
                                      : controller.userData[0]["amount_bal"]
                                          .toString(),
                                );
                              } catch (e) {
                                return "Error retrieving balance";
                              }

                              if (parsedValue < 10)
                                return "Amount can’t be less than 10";
                              if (parsedValue > availableBalance) {
                                return "You don't have enough balance to proceed";
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 14),
                          Row(
                            children: [
                              LuvpayText(text: "Description", color: onSurface),
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
                                        controller.recipientData[0]["mobile_no"]
                                            .toString()) {
                                  controller.isValidUser.value = false;
                                  return;
                                }

                                if (double.parse(
                                      controller.userData.isEmpty
                                          ? "0.0"
                                          : controller.userData[0]["amount_bal"]
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
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget secondChild(BuildContext context, ColorScheme cs, bool isDark) {
    if (controller.recipientData.isEmpty) return Container();

    final onSurface = cs.onSurface;
    final cardOkBg = AppColorV2.lpBlueBrand.withValues(
      alpha: isDark ? 0.18 : 0.10,
    );

    final cardErrBg =
        isDark ? cs.errorContainer.withOpacity(0.30) : const Color(0xFFFFDFDF);

    final borderColor =
        controller.isValidUser.value == true
            ? Colors.transparent
            : AppColorV2.incorrectState;

    final cardBg = controller.isValidUser.value == true ? cardOkBg : cardErrBg;

    final radius = BorderRadius.circular(16);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        LuvpayText(text: "Transfer tokens to", color: onSurface),
        const SizedBox(height: 10),

        LuvNeuPress.rectangle(
          radius: radius,
          onTap: () {},
          background: cs.surface,
          borderColor: null,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: borderColor),
              color: cardBg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    controller.userImage.value.isEmpty ||
                            controller.userName.value.toLowerCase().contains(
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
                                  ? cs.surface
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
                    const SizedBox(width: 10),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LuvpayText(
                            maxLines: 1,
                            text:
                                controller.userName.value == "Unverified User"
                                    ? "Unverified User"
                                    : controller.userName.value,
                            color: onSurface,
                          ),
                          LuvpayText(
                            maxLines: 1,
                            text:
                                controller.recipientData[0]["email"] ??
                                "No email provided yet",
                            color: cs.onSurfaceVariant.withOpacity(0.8),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 5),
                    LuvNeuIconButton(
                      icon: LucideIcons.edit,
                      onTap: () {
                        Get.bottomSheet(
                          UsersBottomsheet(
                            index: 2,
                            cb: (index) => Functions.popPage(index),
                          ),
                          isDismissible: false,
                        );
                      },
                      background: cs.surface,
                    ),
                  ],
                ),

                Divider(
                  color: cs.outlineVariant.withOpacity(isDark ? 0.35 : 0.55),
                ),

                Row(
                  children: [
                    Expanded(
                      child: LuvpayText(
                        text: "Mobile Number",
                        color: onSurface,
                      ),
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: LuvpayText(
                          text: controller.recipientData[0]["mobile_no"],
                          color: onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        Visibility(
          visible: controller.isValidUser.value == false,
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
}

class UsersBottomsheet extends StatefulWidget {
  final int index;
  final Function cb;
  final bool? isValidUser;
  const UsersBottomsheet({
    super.key,
    required this.index,
    required this.cb,
    this.isValidUser,
  });

  @override
  State<UsersBottomsheet> createState() => _UsersBottomsheetState();
}

class _UsersBottomsheetState extends State<UsersBottomsheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController mobileNo = TextEditingController();
  final WalletSendController ct = Get.find<WalletSendController>();

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
      } else {
        ct.getRecipient(mobileNumber);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final sheetTopBg = AppColorV2.lpBlueBrand;
    final sheetBodyBg = cs.surface;
    final onSheetBody = cs.onSurface;

    return PopScope(
      canPop: false,
      child: Container(
        padding: const EdgeInsets.only(top: 10),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          color: sheetTopBg,
        ),
        child: Wrap(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  LuvpayText(text: "Transfer tokens to", color: Colors.white),
                  InkWell(
                    onTap: () => Functions.popPage(widget.index == 1 ? 2 : 1),
                    child: SvgPicture.asset("assets/images/close_button.svg"),
                  ),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.all(19),
              decoration: BoxDecoration(color: sheetBodyBg),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LuvpayText(text: "Recipient Number", color: onSheetBody),
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
                          if (value.toString().replaceAll(" ", "").length < 10)
                            return 'Invalid mobile number';
                          if (value.toString().replaceAll(" ", "")[0] == '0')
                            return 'Invalid mobile number';
                          return null;
                        },
                      ),

                      const SizedBox(height: 14),
                      LuvpayText(
                        text: "Choose other method",
                        color: onSheetBody,
                      ),
                      const SizedBox(height: 5),
                      SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _SheetOptionChip(
                              label: "Scan QR Code",
                              icon: LucideIcons.qrCode,
                              onTap: () {
                                FocusManager.instance.primaryFocus?.unfocus();
                                ct.requestCameraPermission();
                              },
                            ),
                            const SizedBox(width: 8),
                            _SheetOptionChip(
                              label: "From Contacts",
                              icon: LucideIcons.userSquare2,
                              onTap: selectSingleContact,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),
                      Visibility(
                        visible: MediaQuery.of(context).viewInsets.bottom == 0,
                        child: CustomButton(
                          isInactive: mobileNo.text.length != 12,
                          text: "Proceed",
                          onPressed: () {
                            FocusManager.instance.primaryFocus?.unfocus();
                            if (_formKey.currentState?.validate() ?? false) {
                              ct.getRecipient(
                                "63${mobileNo.text.removeAllWhitespace}",
                              );
                            }
                          },
                        ),
                      ),
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

class _SheetOptionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _SheetOptionChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final radius = BorderRadius.circular(14);

    return LuvNeuPress.rectangle(
      radius: radius,
      onTap: onTap,
      background: cs.surface,
      borderColor: cs.outlineVariant.withOpacity(isDark ? 0.22 : 0.18),
      depth: LuvNeu.pillDepthOutline,
      pressedDepth: LuvNeu.pillPressedDepth,
      pressedScale: 0.987,
      pressedTranslateY: 1.0,
      overlayOpacity: isDark ? 0.0 : 0.02,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColorV2.lpBlueBrand, size: 18),
            const SizedBox(width: 8),
            LuvpayText(text: label, color: cs.onSurface),
          ],
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
