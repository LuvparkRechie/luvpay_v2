// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

import 'package:luvpay/otp_field/index.dart';
import 'package:luvpay/pages/my_account/utils/index.dart';

import '../../auth/authentication.dart';
import '../../custom_widgets/alert_dialog.dart';
import '../../custom_widgets/luvpay/custom_button.dart';
import '../../custom_widgets/custom_text_v2.dart';
import '../../custom_widgets/custom_textfield.dart';
import '../../custom_widgets/luvpay/custom_scaffold.dart';
import '../../custom_widgets/spacing.dart';
import '../../functions/functions.dart';
import '../billers/utils/ticketclipper.dart';
import 'controller.dart';

class BillsPayment extends GetView<BillsPaymentController> {
  const BillsPayment({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final borderOpacity = isDark ? 0.05 : 0.01;

    final billerName = _capitalize(controller.arguments["biller_name"] ?? "");
    final billerAddress =
        (controller.arguments["biller_address"] ?? "").toString();
    final serviceFeeText =
        (controller.arguments["service_fee"] ?? "0").toString();
    final hasServiceFee = serviceFeeText.isNotEmpty && serviceFeeText != "0";

    return CustomScaffoldV2(
      appBarTitle: "Pay Bill",
      enableToolBar: true,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      scaffoldBody: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _headerCard(
                context,
                cs: cs,
                isDark: isDark,
                borderOpacity: borderOpacity,
                title: billerName,
              ),
              if (billerAddress.isNotEmpty) ...[
                const SizedBox(height: 8),
                DefaultText(
                  text: billerAddress,
                  style: AppTextStyle.body2(
                    context,
                  ).copyWith(fontWeight: FontWeight.w700),
                  color: cs.onSurface.withOpacity(0.55),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 14),

              _walletBalanceCard(borderOpacity: borderOpacity),

              const SizedBox(height: 18),
              DefaultText(
                text: "Bill Account Number",
                style: AppTextStyle.h3(context),
              ),
              const SizedBox(height: 10),
              CustomTextField(
                controller: controller.accNo,
                hintText: 'Enter bill account number',
                inputFormatters: [
                  LengthLimitingTextInputFormatter(15),
                  UpperCaseTextFormatter(),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return "Account number is required";
                  if (value.length < 5)
                    return "Account number must be at least 5 digits";
                  if (value.length > 15)
                    return "Account number must not exceed 15 digits";
                  return null;
                },
              ),

              const SizedBox(height: 14),
              DefaultText(
                text: "Account Name",
                style: AppTextStyle.h3(context),
              ),
              const SizedBox(height: 10),
              CustomTextField(
                controller: controller.accName,
                hintText: "Enter account name",
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
                  if (value == null || value.isEmpty)
                    return "Account name is required";
                  if (value.startsWith(' ') || value.endsWith(' ')) {
                    return "Account name cannot start or end with a space";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 14),
              DefaultText(text: "Bill Number", style: AppTextStyle.h3(context)),
              const SizedBox(height: 10),
              CustomTextField(
                controller: controller.billNo,
                hintText: "Enter bill number",
                keyboardType: TextInputType.text,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(30),
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    final filtered = newValue.text.toUpperCase().replaceAll(
                      RegExp(r'[^A-Z0-9]'),
                      '',
                    );
                    return TextEditingValue(
                      text: filtered,
                      selection: TextSelection.collapsed(
                        offset: filtered.length,
                      ),
                    );
                  }),
                ],
              ),

              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: DefaultText(
                      text: "Amount",
                      style: AppTextStyle.h3(context),
                    ),
                  ),
                  if (hasServiceFee)
                    DefaultText(
                      text: "+$serviceFeeText Service Fee",
                      style: AppTextStyle.body2(
                        context,
                      ).copyWith(fontWeight: FontWeight.w800),
                      color: cs.onSurface.withOpacity(0.55),
                      maxLines: 1,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              CustomTextField(
                controller: controller.billAmount,
                hintText: "Enter amount",
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  AutoDecimalInputFormatter(),
                  LengthLimitingTextInputFormatter(10),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return "Amount is required";
                  if (value.startsWith(' ') ||
                      value.endsWith(' ') ||
                      value.endsWith('-') ||
                      value.endsWith('.')) {
                    return "Amount cannot start or end with a space";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 18),
              _reviewHintCard(context, cs, borderOpacity),

              const SizedBox(height: 18),
              CustomButton(
                text: "Proceed",
                onPressed: () async {
                  FocusManager.instance.primaryFocus?.unfocus();

                  if (!(controller.formKey.currentState?.validate() ?? false))
                    return;

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

                    final ok =
                        (objData["success"] == "Y" ||
                            objData["status"] == "PENDING");
                    if (!ok) return;

                    final timeExp = DateFormat(
                      "yyyy-MM-dd hh:mm:ss a",
                    ).parse(objData["otp_exp_dt"].toString());

                    final otpExpiry = DateTime(
                      timeExp.year,
                      timeExp.month,
                      timeExp.day,
                      timeExp.hour,
                      timeExp.minute,
                      timeExp.second,
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
                        if (otp != null) controller.getBillerKey();
                      },
                    };

                    Get.to(
                      OtpFieldScreen(arguments: args),
                      transition: Transition.rightToLeftWithFade,
                      duration: const Duration(milliseconds: 400),
                    );
                  });
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerCard(
    BuildContext context, {
    required ColorScheme cs,
    required bool isDark,
    required double borderOpacity,
    required String title,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.onSurface.withOpacity(borderOpacity)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(isDark ? 0.28 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(isDark ? 0.18 : 0.10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: cs.onSurface.withOpacity(borderOpacity),
              ),
            ),
            child: Icon(Iconsax.receipt_text, color: cs.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DefaultText(
              text: title,
              style: AppTextStyle.h3(
                context,
              ).copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.2),
              color: cs.onSurface,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewHintCard(
    BuildContext context,
    ColorScheme cs,
    double borderOpacity,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withOpacity(borderOpacity)),
      ),
      child: Row(
        children: [
          Icon(Iconsax.info_circle, size: 18, color: cs.primary),
          const SizedBox(width: 10),
          Expanded(
            child: DefaultText(
              text: "Please review your details before you proceed.",
              style: AppTextStyle.body2(
                context,
              ).copyWith(fontWeight: FontWeight.w800),
              color: cs.onSurface.withOpacity(0.70),
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _walletBalanceCard({required double borderOpacity}) {
    return GetBuilder<BillsPaymentController>(
      builder: (c) {
        final theme = Theme.of(Get.context!);
        final cs = theme.colorScheme;
        final isDark = theme.brightness == Brightness.dark;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DefaultText(
              text: "luvpay Balance",
              style: AppTextStyle.h3(Get.context!),
              color: cs.onSurface,
            ),
            spacing(height: 12),
            Container(
              height: 54,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: cs.onSurface.withOpacity(borderOpacity),
                ),
                image: const DecorationImage(
                  fit: BoxFit.cover,
                  image: AssetImage("assets/images/booking_wallet_bg.png"),
                ),
                boxShadow: [
                  BoxShadow(
                    color: cs.shadow.withOpacity(isDark ? 0.22 : 0.10),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  Icon(Symbols.wallet, color: cs.onPrimary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DefaultText(
                      color: cs.onPrimary,
                      text: toCurrencyString(c.walletBalance.toString()),
                      style: AppTextStyle.body1(
                        Get.context!,
                      ).copyWith(fontWeight: FontWeight.w900),
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
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

String toCurrencyString(String amount) {
  final number = double.tryParse(amount) ?? 0.0;
  return '₱${number.toStringAsFixed(2)}';
}

class PaymentTicket extends GetView<BillsPaymentController> {
  final Map<String, String> ticketParam;
  final dynamic args;
  const PaymentTicket(this.args, {super.key, required this.ticketParam});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final borderOpacity = isDark ? 0.05 : 0.01;

    return CustomScaffoldV2(
      enableToolBar: false,
      canPop: false,
      enableCustom: false,
      useNormalBody: true,
      scaffoldBody: Container(
        color: cs.primary,
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    children: [
                      DownloadTicket(
                        isDownload: false,
                        ticketParam: ticketParam,
                        borderOpacity: borderOpacity,
                      ),
                      Positioned(
                        right: 18,
                        top: 18,
                        child: _iconPill(
                          context,
                          onTap: () {
                            controller.saveTicket(
                              DownloadTicket(
                                isDownload: false,
                                ticketParam: ticketParam,
                                borderOpacity: borderOpacity,
                              ),
                            );
                          },
                          icon: LucideIcons.download,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  CustomButton(
                    btnColor: cs.surface,
                    text: "Close",
                    textColor: cs.primary,
                    onPressed: () {
                      int backCount = (args["type"] == "use_pass") ? 5 : 4;
                      if (args["fav"] == "use_fav") backCount = 4;
                      for (int i = 0; i < backCount; i++) {
                        Get.back();
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: controller.addFavorites,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.bookmark_border_outlined,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 10),
                        DefaultText(
                          text: "Add to favorite",
                          color: Colors.white,
                          style: AppTextStyle.body1(
                            context,
                          ).copyWith(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).padding.bottom),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconPill(
    BuildContext context, {
    required VoidCallback onTap,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: cs.surface.withOpacity(0.16),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.onPrimary.withOpacity(0.18), width: 1),
          ),
          child: Icon(icon, color: cs.onPrimary.withOpacity(0.92), size: 20),
        ),
      ),
    );
  }
}

class DownloadTicket extends GetView<BillsPaymentController> {
  final bool isDownload;
  final Map<String, String> ticketParam;
  final double borderOpacity;

  const DownloadTicket({
    super.key,
    required this.isDownload,
    required this.ticketParam,
    required this.borderOpacity,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Wrap(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          child: TicketClipper(
            clipper: RoundedEdgeClipper(edge: Edge.vertical, depth: 15),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: cs.surface,
                border: Border.all(
                  color: cs.onSurface.withOpacity(borderOpacity),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        LucideIcons.checkCircle2,
                        size: 46,
                        color: cs.primary,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DefaultText(
                              text: "Congrats",
                              style: AppTextStyle.h2(context),
                              color: cs.primary,
                              maxLines: 1,
                            ),
                            const SizedBox(height: 4),
                            DefaultText(
                              text: "Successful transaction",
                              style: AppTextStyle.body2(
                                context,
                              ).copyWith(fontWeight: FontWeight.w700),
                              color: cs.onSurface.withOpacity(0.62),
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: cs.onSurface.withOpacity(borderOpacity),
                      ),
                    ),
                    child: Column(
                      children:
                          ticketParam.entries.map((e) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: DefaultText(
                                      text: "${e.key} :",
                                      style: AppTextStyle.paragraph2(
                                        context,
                                      ).copyWith(fontWeight: FontWeight.w800),
                                      color: cs.onSurface.withOpacity(0.60),
                                      maxLines: 1,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  DefaultText(
                                    text: e.value.toString(),
                                    style: AppTextStyle.h3(
                                      context,
                                    ).copyWith(fontWeight: FontWeight.w900),
                                    color: cs.onSurface,
                                    maxLines: 1,
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                    ),
                  ),

                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Container(
                        height: 96,
                        width: 96,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: cs.onSurface.withOpacity(borderOpacity),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: cs.shadow.withOpacity(
                                isDark ? 0.20 : 0.08,
                              ),
                              blurRadius: 16,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: PrettyQrView(
                          decoration: const PrettyQrDecoration(
                            background: Colors.white,
                            image: PrettyQrDecorationImage(
                              image: AssetImage("assets/images/logo.png"),
                            ),
                          ),
                          qrImage: QrImage(
                            QrCode.fromData(
                              data: ticketParam["ref_no"].toString(),
                              errorCorrectLevel: QrErrorCorrectLevel.H,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: _buildRefNoSection(context)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRefNoSection(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final refEntry = ticketParam.entries.firstWhere(
      (e) => e.key.toLowerCase().contains("ref no"),
      orElse: () => const MapEntry('', ''),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        DefaultText(
          text: refEntry.value,
          style: AppTextStyle.h3(context).copyWith(fontWeight: FontWeight.w900),
          color: cs.onSurface,
          maxLines: 1,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        DefaultText(
          text: refEntry.key.replaceAll('.', ''),
          style: AppTextStyle.body2(
            context,
          ).copyWith(fontWeight: FontWeight.w700),
          color: cs.onSurface.withOpacity(0.60),
          maxLines: 1,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
