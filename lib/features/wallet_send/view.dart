// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_contact_picker/model/contact.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:luvpay/features/scanner_screen.dart';

import '../../auth/authentication.dart';
import '../../shared/dialogs/dialogs.dart';
import '../../shared/widgets/colors.dart';
import '../../shared/widgets/custom_scaffold.dart';
import '../../shared/widgets/custom_textfield.dart';
import '../../shared/widgets/luvpay_loading.dart';
import '../../shared/widgets/luvpay_text.dart';
import '../../shared/widgets/neumorphism.dart';
import '../../shared/widgets/variables.dart';
import '../billers/utils/allbillers.dart';
import 'controller.dart' hide CustomMobileNumber;

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
          Get.back();
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
      child:
          controller.isLoading.value
              ? Center(child: LoadingCard())
              : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Form(
                      key: controller.formKeySend,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 14),
                          UserDetails(isEdit: false),
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

class UserDetails extends StatefulWidget {
  final int? index;
  final bool? isEdit;
  final Function? cb;
  final bool? isValidUser;

  const UserDetails({
    super.key,
    this.index,
    this.cb,
    this.isValidUser,
    this.isEdit,
  });

  @override
  State<UserDetails> createState() => _UserDetailsState();
}

class _UserDetailsState extends State<UserDetails> {
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

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final args = Get.arguments;

      if (args is Map && args["mobile"] != null) {
        final mobile = args["mobile"].toString();
        await _applyNumber(mobile);
      }
    });
  }

  Future<void> _applyNumber(String mobileNumber) async {
    final normalized = ct.normalizeMobile(mobileNumber);
    if (normalized == null) {
      CustomDialogStack.showError(
        context,
        "Error",
        "Invalid mobile number format",
        () => Get.back(),
      );
      return;
    }

    final local10 = normalized.substring(2);
    mobileNo.text = Variables.maskFormatter.maskText(local10);
    await ct.getRecipient(normalized);
    _formKey.currentState?.validate();
  }

  Future<void> selectSingleContact() async {
    Contact? selectedContact = await ct.contactPicker.selectContact();
    if (selectedContact == null) return;

    ct.contact.value = selectedContact;

    final contactString = selectedContact.toString();
    final digits = contactString.replaceAll(RegExp(r'\D+'), '');
    await _applyNumber(digits);
  }

  Widget _chip(
    String title,
    String subtitle,
    VoidCallback onTap, {
    IconData icon = LucideIcons.userCircle2,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final surface = cs.surface;
    final radius = BorderRadius.circular(16);

    return LuvNeuPress.rectangle(
      radius: radius,
      onTap: onTap,
      background: surface,
      borderColor: cs.outlineVariant.withOpacity(isDark ? 0.18 : 0.30),
      depth: LuvNeu.iconDepth,
      pressedDepth: LuvNeu.iconPressedDepth,
      pressedScale: 0.985,
      pressedTranslateY: 1.0,
      overlayOpacity: isDark ? 0.0 : 0.02,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LuvpayText(
                    text: title,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 2),
                  LuvpayText(
                    text: subtitle,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant.withOpacity(0.85),
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
                    LuvpayText(
                      text: "Recipient Number",
                      color: onSheetBody,
                      style: AppTextStyle.body1(context),
                    ),
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
                                  _formKey.currentState?.validate() ?? false;
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
                        if (clean.length != 10) return 'Invalid mobile number';
                        if (clean.startsWith('0')) {
                          return 'Invalid mobile number';
                        }

                        return null;
                      },
                      suffixBgC: Colors.transparent,
                      suffixWidget: Padding(
                        padding: const EdgeInsets.only(right: 19),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () async {
                                FocusManager.instance.primaryFocus?.unfocus();

                                await Get.to(
                                  () => ScannerScreenV2(
                                    isBack: false,
                                    onchanged: (args) {
                                      if (args.isNotEmpty) {
                                        Get.back();
                                        _applyNumber(args);
                                      }
                                    },
                                  ),
                                );
                              },
                              child: const Icon(LucideIcons.qrCode),
                            ),
                            const SizedBox(width: 14),
                            InkWell(
                              onTap: selectSingleContact,
                              child: const Icon(LucideIcons.contact),
                            ),
                          ],
                        ),
                      ),
                      onIconTap: () {},
                    ),
                    const SizedBox(height: 12),
                    Obx(() {
                      final list = ct.recentRecipients;
                      if (list.isEmpty) return const SizedBox.shrink();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LuvpayText(
                            text: "Recent",
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurfaceVariant,
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 60,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: list.length,
                              separatorBuilder:
                                  (_, __) => const SizedBox(width: 10),
                              itemBuilder: (context, i) {
                                final item = list[i];
                                final name = (item["name"] ?? "").toString();
                                final mobile =
                                    (item["mobile_no"] ?? "").toString();

                                final title =
                                    name.isEmpty ? "Recent recipient" : name;
                                final subtitle =
                                    mobile.startsWith("63")
                                        ? "+$mobile"
                                        : mobile;

                                return _chip(title, subtitle, () async {
                                  FocusManager.instance.primaryFocus?.unfocus();
                                  await _applyNumber(mobile);
                                }, icon: LucideIcons.clock3);
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      );
                    }),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: mobileNo,
                      builder: (context, value, _) {
                        final clean = value.text.replaceAll(" ", "");

                        if (clean.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Row(
                              children: [
                                Icon(
                                  LucideIcons.sparkles,
                                  size: 14,
                                  color: cs.onSurfaceVariant.withOpacity(0.75),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: LuvpayText(
                                    text:
                                        "Choose a recent recipient, scan QR, or pick from Contacts.",
                                    fontSize: 12,
                                    color: cs.onSurfaceVariant.withOpacity(
                                      0.85,
                                    ),
                                    maxLines: 2,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        if (clean.length < 10) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Row(
                              children: [
                                Icon(
                                  LucideIcons.keyboard,
                                  size: 14,
                                  color: cs.onSurfaceVariant.withOpacity(0.75),
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
                              padding: const EdgeInsets.only(top: 6),
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
                              padding: const EdgeInsets.only(top: 6),
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
                                        name.toLowerCase().contains("unknown"))
                                    ? "Verified account"
                                    : name;

                            final isUnverified = displayName
                                .toLowerCase()
                                .contains("unverified");

                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
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
                                      fontWeight: FontWeight.w700,
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}
