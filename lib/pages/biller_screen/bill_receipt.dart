import 'dart:io';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:luvpay/custom_widgets/alert_dialog.dart';
import 'package:luvpay/custom_widgets/custom_text_v2.dart';

import 'package:screenshot/screenshot.dart';

import 'package:path_provider/path_provider.dart';

import '../../custom_widgets/app_color_v2.dart';

class BillPaymentReceipt extends StatelessWidget {
  final Map<String, dynamic> apiResponse;
  final Map<String, dynamic> paymentParams;

  const BillPaymentReceipt({
    super.key,
    required this.apiResponse,
    required this.paymentParams,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => Get.back(result: true),
            icon: Icon(CupertinoIcons.back, color: Colors.white, size: 24),
            splashColor: AppColorV2.lpBlueBrand.withAlpha(50),
          ),
          title: DefaultText(
            text: "Payment Receipt",
            color: Colors.white,
            fontSize: 14,
            style: AppTextStyle.h3,
            maxLines: 1,
          ),
          centerTitle: true,
          backgroundColor: AppColorV2.lpBlueBrand,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.white,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 19),
            child: Column(
              children: [
                SizedBox(height: 40),
                reciptDetails(),
                // Receipt Body
                SizedBox(height: 32),

                Column(
                  children: [
                    // Download Button
                    Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColorV2.lpBlueBrand),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _saveReceipt(context),
                          borderRadius: BorderRadius.circular(8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.download_rounded,
                                color: AppColorV2.lpBlueBrand,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Save Receipt',
                                style: TextStyle(
                                  color: AppColorV2.lpBlueBrand,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                  ],
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget reciptDetails() {
    final message = apiResponse['msg'] ?? '';
    final amount = _extractAmountFromMessage(message);
    final billerName = _extractBillerNameFromMessage(message);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColorV2.boxStroke, width: 1),
        color: Colors.white,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Receipt Content
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                // Store/App Header
                Center(child: Column(children: [_buildReceiptHeader()])),
                SizedBox(height: 20),

                // Divider
                _buildDashedDivider(),
                SizedBox(height: 20),
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
                      _formatCurrency(double.tryParse(amount) ?? 0.0),
                      style: TextStyle(
                        color: AppColorV2.lpBlueBrand,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                // Status
                _buildReceiptRow('STATUS', 'COMPLETED', isBold: true),
                SizedBox(height: 16),

                // Date & Time
                _buildReceiptRow(
                  'DATE',
                  _formatDateTime(apiResponse['payment_dt']),
                ),
                SizedBox(height: 12),
                _buildReceiptRow(
                  'TIME',
                  _formatTime(apiResponse['payment_dt']),
                ),
                SizedBox(height: 12),

                // Transaction Details
                _buildReceiptRow(
                  'REFERENCE NO.',
                  apiResponse['lp_ref_no'] ?? 'N/A',
                ),
                SizedBox(height: 12),
                _buildReceiptRow(
                  'BILLER',
                  billerName.isNotEmpty ? billerName : 'One Communities',
                ),
                SizedBox(height: 12),
                _buildReceiptRow(
                  'ACCOUNT NAME',
                  paymentParams['account_name'] ?? 'N/A',
                ),
                SizedBox(height: 12),
                _buildReceiptRow(
                  'ACCOUNT NO.',
                  paymentParams['bill_acct_no'] ?? 'N/A',
                ),
                SizedBox(height: 12),
                _buildReceiptRow('PAYMENT METHOD', 'LUVPARK Wallet'),
                SizedBox(height: 20),

                // Divider
                _buildDashedDivider(),
                SizedBox(height: 20),

                // Thank You Message
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColorV2.pastelBlueAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.favorite_rounded,
                        color: AppColorV2.lpBlueBrand,
                        size: 16,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Thank you for your payment!',
                        style: TextStyle(
                          color: AppColorV2.primaryTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 4),
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
              ],
            ),
          ),

          // Receipt Bottom Border
          Container(height: 4, color: AppColorV2.primaryTextColor),
        ],
      ),
    );
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
          child: Icon(Icons.check_rounded, color: Colors.white, size: 30),
        ),
        SizedBox(height: 16),
        Text(
          'Payment Successful',
          style: TextStyle(
            color: AppColorV2.primaryTextColor,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildReceiptRow(String title, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColorV2.bodyTextColor,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: AppColorV2.primaryTextColor,
            fontSize: 12,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDashedDivider() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 4.0;
        const dashHeight = 1.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();

        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: AppColorV2.boxStroke),
              ),
            );
          }),
        );
      },
    );
  }

  // Helper methods
  String _extractAmountFromMessage(String message) {
    final regex = RegExp(r'Payment of ([\d.,]+) tokens');
    final match = regex.firstMatch(message);
    return match?.group(1) ?? paymentParams['amount'] ?? '0';
  }

  String _extractBillerNameFromMessage(String message) {
    final regex = RegExp(r'to ([^.]+)\.');
    final match = regex.firstMatch(message);
    return match?.group(1)?.trim() ?? '';
  }

  String _formatDateTime(dynamic dateTime) {
    if (dateTime == null) return 'N/A';
    try {
      final inputFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
      final outputFormat = DateFormat('MMM dd, yyyy');
      final date = inputFormat.parse(dateTime.toString());
      return outputFormat.format(date);
    } catch (e) {
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
    } catch (e) {
      return dateTime.toString();
    }
  }

  String _formatCurrency(double amount) {
    return '₱${amount.toStringAsFixed(2)}';
  }

  Widget _downloadableReceipt() {
    final message = apiResponse['msg'] ?? '';
    final amount = _extractAmountFromMessage(message);
    final billerName = _extractBillerNameFromMessage(message);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColorV2.boxStroke, width: 1),
        color: Colors.white,
        borderRadius: BorderRadius.circular(8), // Soft rounded corners
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Receipt Top Edge - Perforated/Ticket Style
          Container(
            height: 20,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ...List.generate(
                  10,
                  (index) => Container(
                    width: 8,
                    height: 1,
                    margin: EdgeInsets.symmetric(horizontal: 2),
                    color: AppColorV2.boxStroke,
                  ),
                ),
              ],
            ),
          ),

          // Receipt Top Border
          Container(height: 3, color: AppColorV2.primaryTextColor),

          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                // Store/App Header with enhanced styling
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColorV2.pastelBlueAccent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'luvpay',
                          style: TextStyle(
                            color: AppColorV2.lpBlueBrand,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'DIGITAL PAYMENT RECEIPT',
                        style: TextStyle(
                          color: AppColorV2.bodyTextColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _formatDateTime(apiResponse['payment_dt']),
                        style: TextStyle(
                          color: AppColorV2.bodyTextColor,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),

                // Top Dashed Divider
                _buildEnhancedDashedDivider(),
                SizedBox(height: 20),

                // Amount Section - Highlighted
                Container(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColorV2.pastelBlueAccent.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColorV2.lpBlueBrand.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'AMOUNT PAID',
                        style: TextStyle(
                          color: AppColorV2.bodyTextColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _formatCurrency(double.tryParse(amount) ?? 0.0),
                        style: TextStyle(
                          color: AppColorV2.lpBlueBrand,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),

                // Status with badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColorV2.correctState.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColorV2.correctState.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        color: AppColorV2.correctState,
                        size: 14,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'PAYMENT COMPLETED',
                        style: TextStyle(
                          color: AppColorV2.correctState,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),

                // Middle Dashed Divider
                _buildEnhancedDashedDivider(),
                SizedBox(height: 20),

                // Transaction Details with better spacing
                _buildEnhancedReceiptRow(
                  'Reference No.',
                  apiResponse['lp_ref_no'] ?? 'N/A',
                  isImportant: true,
                ),
                SizedBox(height: 12),
                _buildEnhancedReceiptRow(
                  'Biller',
                  billerName.isNotEmpty ? billerName : 'One Communities',
                ),
                SizedBox(height: 12),
                _buildEnhancedReceiptRow(
                  'Account Name',
                  paymentParams['account_name'] ?? 'N/A',
                ),
                SizedBox(height: 12),
                _buildEnhancedReceiptRow(
                  'Account No.',
                  paymentParams['bill_acct_no'] ?? 'N/A',
                ),
                SizedBox(height: 12),
                _buildEnhancedReceiptRow('Payment Method', 'LUVPARK Wallet'),
                SizedBox(height: 20),

                // Bottom Dashed Divider
                _buildEnhancedDashedDivider(),
                SizedBox(height: 20),

                // Thank You Section
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColorV2.pastelBlueAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.favorite_rounded,
                        color: AppColorV2.lpBlueBrand,
                        size: 16,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Thank you for your payment!',
                        style: TextStyle(
                          color: AppColorV2.primaryTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 4),
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
              ],
            ),
          ),

          // Receipt Bottom Border
          Container(height: 3, color: AppColorV2.primaryTextColor),

          // Receipt Bottom Edge - Perforated/Ticket Style
          Container(
            height: 20,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ...List.generate(
                  10,
                  (index) => Container(
                    width: 8,
                    height: 1,
                    margin: EdgeInsets.symmetric(horizontal: 2),
                    color: AppColorV2.boxStroke,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedDashedDivider() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 6.0;
        const dashHeight = 1.5;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();

        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return Container(
              width: dashWidth,
              height: dashHeight,
              decoration: BoxDecoration(
                color: AppColorV2.boxStroke.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(1),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildEnhancedReceiptRow(
    String title,
    String value, {
    bool isImportant = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: AppColorV2.bodyTextColor,
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color:
                    isImportant
                        ? AppColorV2.lpBlueBrand
                        : AppColorV2.primaryTextColor,
                fontSize: 11,
                fontWeight: isImportant ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _saveReceipt(BuildContext context) {
    CustomDialogStack.showLoading(Get.context!);
    String randomNumber = Random().nextInt(100000).toString();
    String fname = "luvpark$randomNumber.png";
    ScreenshotController()
        .captureFromWidget(
          _downloadableReceipt(),
          delay: const Duration(seconds: 2),
        )
        .then((image) async {
          final dir = await getApplicationDocumentsDirectory();
          final imagePath = await File('${dir.path}/$fname').create();
          await imagePath.writeAsBytes(image);
          GallerySaver.saveImage(imagePath.path).then((result) {
            CustomDialogStack.showSuccess(
              Get.context!,
              "Success",
              "QR code has been saved. Please check your gallery.",
              () {
                Get.back();
                Get.back();
              },
            );
          });
        });
  }
}
