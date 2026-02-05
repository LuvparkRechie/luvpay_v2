// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:ticketcher/ticketcher.dart';

import 'package:luvpay/custom_widgets/alert_dialog.dart';
import 'package:luvpay/custom_widgets/luvpay/custom_button.dart';
import 'package:luvpay/custom_widgets/custom_text_v2.dart';

class BillPaymentReceipt extends StatelessWidget {
  final Map<String, dynamic> apiResponse;
  final Map<String, dynamic> paymentParams;

  BillPaymentReceipt({
    super.key,
    required this.apiResponse,
    required this.paymentParams,
  });

  final ScreenshotController _shot = ScreenshotController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final borderOpacity = isDark ? 0.05 : 0.01;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: cs.surface,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          toolbarHeight: 0,
          elevation: 0,
          backgroundColor: cs.surface,
          surfaceTintColor: Colors.transparent,
          systemOverlayStyle: (isDark
                  ? SystemUiOverlayStyle.light
                  : SystemUiOverlayStyle.dark)
              .copyWith(statusBarColor: cs.surface),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 19),
            child: Column(
              children: [
                const SizedBox(height: 28),
                Screenshot(
                  controller: _shot,
                  child: _downloadableReceipt(
                    context,
                    cs: cs,
                    isDark: isDark,
                    borderOpacity: borderOpacity,
                  ),
                ),
                const SizedBox(height: 22),
                Column(
                  children: [
                    CustomButton(
                      text: "Done",
                      onPressed: () {
                        Get.back(result: true);
                        Get.back(result: true);
                      },
                    ),
                    const SizedBox(height: 10),
                    CustomButton(
                      text: "Save Receipt",
                      btnColor: cs.surface,
                      textColor: cs.primary,
                      bordercolor: cs.primary,
                      onPressed: () => _saveReceipt(context),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
                const SizedBox(height: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _downloadableReceipt(
    BuildContext context, {
    required ColorScheme cs,
    required bool isDark,
    required double borderOpacity,
  }) {
    final width = MediaQuery.of(context).size.width - (19 * 2);
    return SizedBox(
      width: width,
      child: _receiptTicket(
        context,
        cs: cs,
        isDark: isDark,
        borderOpacity: borderOpacity,
      ),
    );
  }

  Widget _receiptTicket(
    BuildContext context, {
    required ColorScheme cs,
    required bool isDark,
    required double borderOpacity,
  }) {
    final message = apiResponse['msg']?.toString() ?? '';
    final amountStr = _extractAmountFromMessage(message);
    final billerName = _extractBillerNameFromMessage(message);
    final amount = double.tryParse(amountStr) ?? 0.0;

    final borderColor = cs.onSurface.withOpacity(borderOpacity);

    return Ticketcher.vertical(
      notchRadius: 14,
      decoration: TicketcherDecoration(
        backgroundColor: cs.surface,
        borderRadius: const TicketRadius(radius: 16),
        border: Border.all(color: borderColor, width: 1),
        shadow: BoxShadow(
          color: cs.shadow.withOpacity(isDark ? 0.30 : 0.10),
          blurRadius: 22,
          offset: const Offset(0, 12),
        ),
        divider: TicketDivider.dashed(
          color: cs.onSurface.withOpacity(isDark ? 0.18 : 0.12),
          thickness: 1,
          dashWidth: 8,
          dashSpace: 6,
          padding: 10,
        ),
      ),
      sections: [
        Section(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            children: [
              _buildReceiptHeader(
                context,
                cs: cs,
                isDark: isDark,
                borderOpacity: borderOpacity,
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  DefaultText(
                    text: "AMOUNT PAID",
                    style: AppTextStyle.body2(context).copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                    color: cs.onSurface.withOpacity(0.60),
                  ),
                  DefaultText(
                    text: _formatCurrency(amount),
                    style: AppTextStyle.h3(context).copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                    ),
                    color: cs.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
        Section(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: Column(
            children: [
              _buildReceiptRow(
                context,
                cs,
                'STATUS',
                'COMPLETED',
                isBold: true,
              ),
              const SizedBox(height: 14),
              _buildReceiptRow(
                context,
                cs,
                'DATE',
                _formatDate(apiResponse['payment_dt']),
              ),
              const SizedBox(height: 10),
              _buildReceiptRow(
                context,
                cs,
                'TIME',
                _formatTime(apiResponse['payment_dt']),
              ),
              const SizedBox(height: 10),
              _buildReceiptRow(
                context,
                cs,
                'REFERENCE NO.',
                apiResponse['lp_ref_no']?.toString() ?? 'N/A',
              ),
              const SizedBox(height: 10),
              _buildReceiptRow(
                context,
                cs,
                'BILLER',
                billerName.isNotEmpty ? billerName : 'One Communities',
              ),
              const SizedBox(height: 10),
              _buildReceiptRow(
                context,
                cs,
                'ACCOUNT NAME',
                paymentParams['account_name']?.toString() ?? 'N/A',
              ),
              const SizedBox(height: 10),
              _buildReceiptRow(
                context,
                cs,
                'ACCOUNT NO.',
                paymentParams['bill_acct_no']?.toString() ?? 'N/A',
              ),
              const SizedBox(height: 10),
              _buildReceiptRow(context, cs, 'PAYMENT METHOD', 'LUVPARK Wallet'),
            ],
          ),
        ),
        Section(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            children: [
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
                  children: [
                    Image.asset("assets/images/logo.png", height: 38),
                    const SizedBox(height: 8),
                    DefaultText(
                      text: 'Thank you for your payment!',
                      style: AppTextStyle.body1(
                        context,
                      ).copyWith(fontWeight: FontWeight.w900),
                      color: cs.onSurface,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    DefaultText(
                      text: 'Keep this receipt for your records',
                      style: AppTextStyle.body2(
                        context,
                      ).copyWith(fontWeight: FontWeight.w700),
                      color: cs.onSurface.withOpacity(0.60),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _saveReceipt(BuildContext context) async {
    CustomDialogStack.showLoading(Get.context!);

    try {
      await Future.delayed(const Duration(milliseconds: 60));
      final bytes = await _shot.capture(pixelRatio: 3.0);

      if (bytes == null) {
        if (Get.isDialogOpen == true) Get.back();
        CustomDialogStack.showError(
          Get.context!,
          "Failed",
          "Unable to save receipt. Please try again.",
          () => Get.back(),
        );
        return;
      }

      final randomNumber = Random().nextInt(100000).toString();
      final fname = "luvpark$randomNumber.png";

      final dir = await getApplicationDocumentsDirectory();
      final imageFile = await File('${dir.path}/$fname').create();
      await imageFile.writeAsBytes(bytes);

      await GallerySaver.saveImage(imageFile.path);

      if (Get.isDialogOpen == true) Get.back();
      CustomDialogStack.showSuccess(
        Get.context!,
        "Success",
        "Receipt has been saved. Please check your gallery.",
        () {
          Get.back();
          Get.back();
        },
      );
    } catch (_) {
      if (Get.isDialogOpen == true) Get.back();
      CustomDialogStack.showError(
        Get.context!,
        "Failed",
        "Unable to save receipt. Please try again.",
        () => Get.back(),
      );
    }
  }

  Widget _buildReceiptHeader(
    BuildContext context, {
    required ColorScheme cs,
    required bool isDark,
    required double borderOpacity,
  }) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: cs.primary.withOpacity(isDark ? 0.18 : 0.10),
            shape: BoxShape.circle,
            border: Border.all(color: cs.onSurface.withOpacity(borderOpacity)),
          ),
          child: Icon(Icons.check_rounded, color: cs.primary, size: 32),
        ),
        const SizedBox(height: 14),
        DefaultText(
          text: 'Payment Successful',
          style: AppTextStyle.h2(context).copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.25,
          ),
          color: cs.onSurface,
        ),
      ],
    );
  }

  Widget _buildReceiptRow(
    BuildContext context,
    ColorScheme cs,
    String title,
    String value, {
    bool isBold = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: DefaultText(
            text: title,
            style: AppTextStyle.body2(context).copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
            color: cs.onSurface.withOpacity(0.58),
            maxLines: 1,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 6,
          child: DefaultText(
            text: value,
            textAlign: TextAlign.right,
            style: AppTextStyle.body2(context).copyWith(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w800,
            ),
            color: cs.onSurface,
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  String _extractAmountFromMessage(String message) {
    final regex = RegExp(r'Payment of ([\d.,]+) tokens');
    final match = regex.firstMatch(message);
    return match?.group(1) ?? (paymentParams['amount']?.toString() ?? '0');
  }

  String _extractBillerNameFromMessage(String message) {
    final regex = RegExp(r'to ([^.]+)\.');
    final match = regex.firstMatch(message);
    return match?.group(1)?.trim() ?? '';
  }

  String _formatDate(dynamic dateTime) {
    if (dateTime == null) return 'N/A';
    try {
      final inputFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
      final outputFormat = DateFormat('MMM dd, yyyy');
      final date = inputFormat.parse(dateTime.toString());
      return outputFormat.format(date);
    } catch (_) {
      return dateTime.toString();
    }
  }

  String _formatTime(dynamic dateTime) {
    if (dateTime == null) return 'N/A';
    try {
      final inputFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
      final outputFormat = DateFormat('hh:mm a');
      final date = inputFormat.parse(dateTime.toString());
      return outputFormat.format(date);
    } catch (_) {
      return dateTime.toString();
    }
  }

  String _formatCurrency(double amount) => '₱${amount.toStringAsFixed(2)}';
}
