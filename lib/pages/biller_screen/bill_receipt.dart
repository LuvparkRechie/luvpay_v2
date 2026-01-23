import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:ticketcher/ticketcher.dart';

import 'package:luvpay/custom_widgets/alert_dialog.dart';
import 'package:luvpay/custom_widgets/custom_button.dart';
import '../../custom_widgets/app_color_v2.dart';

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
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          toolbarHeight: 0,
          elevation: 0,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 19),
            child: Column(
              children: [
                const SizedBox(height: 40),
                Screenshot(
                  controller: _shot,
                  child: _downloadableReceipt(context),
                ),
                const SizedBox(height: 32),
                Column(
                  children: [
                    CustomButton(
                      text: "Done",
                      onPressed: () => Get.back(result: true),
                    ),
                    const SizedBox(height: 10),
                    CustomButton(
                      text: "Save Receipt",
                      btnColor: Colors.white,
                      textColor: AppColorV2.lpBlueBrand,
                      bordercolor: AppColorV2.lpBlueBrand,
                      onPressed: () => _saveReceipt(context),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _downloadableReceipt(BuildContext context) {
    final width = MediaQuery.of(context).size.width - (19 * 2);
    return SizedBox(width: width, child: _receiptTicket());
  }

  Widget _receiptTicket() {
    final message = apiResponse['msg']?.toString() ?? '';
    final amountStr = _extractAmountFromMessage(message);
    final billerName = _extractBillerNameFromMessage(message);
    final amount = double.tryParse(amountStr) ?? 0.0;

    return Ticketcher.vertical(
      notchRadius: 14,
      decoration: TicketcherDecoration(
        backgroundColor: Colors.white,
        borderRadius: TicketRadius(radius: 14),
        border: Border.all(color: AppColorV2.boxStroke, width: 1),
        shadow: BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 18,
          offset: const Offset(0, 10),
        ),
        divider: TicketDivider.dashed(
          color: AppColorV2.boxStroke.withValues(alpha: 0.8),
          thickness: 1,
          dashWidth: 8,
          dashSpace: 6,
          padding: 10,
        ),
      ),
      sections: [
        Section(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildReceiptHeader(),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "AMOUNT PAID",
                    style: TextStyle(
                      color: AppColorV2.bodyTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    _formatCurrency(amount),
                    style: TextStyle(
                      color: AppColorV2.lpBlueBrand,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
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
              _buildReceiptRow('STATUS', 'COMPLETED', isBold: true),
              const SizedBox(height: 14),
              _buildReceiptRow('DATE', _formatDate(apiResponse['payment_dt'])),
              const SizedBox(height: 10),
              _buildReceiptRow('TIME', _formatTime(apiResponse['payment_dt'])),
              const SizedBox(height: 10),
              _buildReceiptRow(
                'REFERENCE NO.',
                apiResponse['lp_ref_no']?.toString() ?? 'N/A',
              ),
              const SizedBox(height: 10),
              _buildReceiptRow(
                'BILLER',
                billerName.isNotEmpty ? billerName : 'One Communities',
              ),
              const SizedBox(height: 10),
              _buildReceiptRow(
                'ACCOUNT NAME',
                paymentParams['account_name']?.toString() ?? 'N/A',
              ),
              const SizedBox(height: 10),
              _buildReceiptRow(
                'ACCOUNT NO.',
                paymentParams['bill_acct_no']?.toString() ?? 'N/A',
              ),
              const SizedBox(height: 10),
              _buildReceiptRow('PAYMENT METHOD', 'LUVPARK Wallet'),
            ],
          ),
        ),
        Section(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColorV2.pastelBlueAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.favorite_rounded,
                      color: AppColorV2.lpBlueBrand,
                      size: 16,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Thank you for your payment!',
                      style: TextStyle(
                        color: AppColorV2.primaryTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Keep this receipt for your records',
                      style: TextStyle(
                        color: AppColorV2.bodyTextColor,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(height: 4, color: AppColorV2.primaryTextColor),
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

  Widget _buildReceiptHeader() {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppColorV2.correctState,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 30),
        ),
        const SizedBox(height: 16),
        Text(
          'Payment Successful',
          style: TextStyle(
            color: AppColorV2.primaryTextColor,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildReceiptRow(String title, String value, {bool isBold = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            title,
            style: TextStyle(
              color: AppColorV2.bodyTextColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 6,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: AppColorV2.primaryTextColor,
              fontSize: 12,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
            ),
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
