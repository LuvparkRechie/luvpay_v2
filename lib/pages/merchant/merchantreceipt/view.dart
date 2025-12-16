import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:luvpay/custom_widgets/app_color_v2.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';

import '../../../custom_widgets/alert_dialog.dart';
import 'controller.dart';

class MerchantQRReceipt extends GetView<MerchantQRRController> {
  MerchantQRReceipt({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Get.back(result: true),
                      icon: Icon(
                        Icons.close,
                        color: AppColorV2.primaryTextColor,
                      ),
                    ),
                    Spacer(),
                    Text(
                      'Payment Receipt',
                      style: TextStyle(
                        color: AppColorV2.primaryTextColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Spacer(),
                    SizedBox(width: 48),
                  ],
                ),
              ),

              // Merchant-Specific Header
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      SizedBox(height: 20),
                      _buildMerchantHeader(),
                      SizedBox(height: 20),
                      _buildMerchantReceiptCard(),
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
                                onTap: () => _saveReceipt(),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMerchantHeader() {
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

  Widget _buildMerchantSuccessIcon() {
    return Column(
      children: [
        // Animated Success Circle
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColorV2.lpBlueBrand, AppColorV2.lpTealBrand],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColorV2.lpBlueBrand.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer Ring
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              // Inner Icon
              Icon(LucideIcons.check, color: AppColorV2.lpBlueBrand, size: 40),
            ],
          ),
        ),
        SizedBox(height: 16),
        Text(
          'Payment to Merchant',
          style: TextStyle(
            color: AppColorV2.primaryTextColor,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Successfully Completed',
          style: TextStyle(color: AppColorV2.bodyTextColor, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildMerchantReceiptCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 25,
            offset: Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: AppColorV2.boxStroke.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Receipt Content
          Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              children: [
                // Merchant Info Highlight
                _buildMerchantInfoSection(),
                SizedBox(height: 24),

                // Amount Section
                _buildAmountSection(),
                SizedBox(height: 24),

                // Transaction Details
                _buildTransactionDetails(),
                SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMerchantInfoSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColorV2.pastelBlueAccent.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColorV2.lpBlueBrand.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColorV2.lpBlueBrand,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: AppColorV2.lpBlueBrand.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Icon(LucideIcons.store, color: Colors.white, size: 24),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PAID TO',
                  style: TextStyle(
                    color: AppColorV2.bodyTextColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _capitalize(
                    controller.parameter["merchant_name"] ?? "Merchant",
                  ),
                  style: TextStyle(
                    color: AppColorV2.primaryTextColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'QR Code Merchant',
                  style: TextStyle(
                    color: AppColorV2.bodyTextColor,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColorV2.lpBlueBrand.withValues(alpha: 0.05),
            AppColorV2.lpTealBrand.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: AppColorV2.lpBlueBrand.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Text(
            'AMOUNT PAID',
            style: TextStyle(
              color: AppColorV2.bodyTextColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
          SizedBox(height: 8),
          Text(
            _formatCurrency(
              double.tryParse(
                    controller.parameter["amount"]?.toString() ?? '0',
                  ) ??
                  0.0,
            ),
            style: TextStyle(
              color: AppColorV2.lpBlueBrand,
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 12),
          Container(height: 1, color: AppColorV2.boxStroke),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Reference no.',
                style: TextStyle(color: AppColorV2.bodyTextColor, fontSize: 12),
              ),
              Text(
                controller.parameter["reference_no"],
                style: TextStyle(
                  color: AppColorV2.lpBlueBrand,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionDetails() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildDetailRow(
            icon: LucideIcons.calendar,
            label: 'Transaction Date',
            value: controller.formatDate(
              DateTime.parse(controller.parameter["date_time"]),
            ),
          ),
          SizedBox(height: 12),
          _buildDetailRow(
            icon: LucideIcons.clock,
            label: 'Transaction Time',
            value: DateFormat('hh:mm a').format(DateTime.now()),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    bool isHighlighted = false,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color:
                isHighlighted
                    ? AppColorV2.lpBlueBrand.withValues(alpha: 0.1)
                    : Colors.grey[200],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            color:
                isHighlighted
                    ? AppColorV2.lpBlueBrand
                    : AppColorV2.bodyTextColor,
            size: 16,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppColorV2.bodyTextColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color:
                      isHighlighted
                          ? AppColorV2.lpBlueBrand
                          : AppColorV2.primaryTextColor,
                  fontSize: 13,
                  fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper methods
  String _formatCurrency(double amount) {
    return '₱${amount.toStringAsFixed(2)}';
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  void _saveReceipt() {
    CustomDialogStack.showLoading(Get.context!);
    String randomNumber = Random().nextInt(100000).toString();
    String fname = "luvmart_merchant$randomNumber.png";
    ScreenshotController()
        .captureFromWidget(
          _buildDownloadableReceipt(),
          delay: const Duration(seconds: 2),
        )
        .then((image) async {
          final dir = await getApplicationDocumentsDirectory();
          final imagePath = await File('${dir.path}/$fname').create();
          await imagePath.writeAsBytes(image);
          GallerySaver.saveImage(imagePath.path).then((result) {
            Get.back();
            CustomDialogStack.showSuccess(
              Get.context!,
              "Success",
              "Merchant receipt has been saved to your gallery.",
              () {
                Get.back();
              },
            );
          });
        });
  }

  void _shareReceipt() {
    CustomDialogStack.showLoading(Get.context!);
    String randomNumber = Random().nextInt(100000).toString();
    String fname = "luvmart_merchant$randomNumber.png";
    ScreenshotController()
        .captureFromWidget(
          _buildDownloadableReceipt(),
          delay: const Duration(seconds: 2),
        )
        .then((image) async {
          final dir = await getApplicationDocumentsDirectory();
          final imagePath = await File('${dir.path}/$fname').create();
          await imagePath.writeAsBytes(image);
          Get.back();
          CustomDialogStack.showSuccess(
            Get.context!,
            "Ready to Share",
            "Merchant receipt is ready for sharing!",
            () {
              Get.back();
            },
          );
        });
  }

  Widget _buildDownloadableReceipt() {
    return Container(
      width: 320,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColorV2.boxStroke, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Merchant Header
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColorV2.lpBlueBrand, AppColorV2.lpTealBrand],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'MERCHANT RECEIPT',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),
          SizedBox(height: 16),

          // Merchant Info
          Row(
            children: [
              Icon(LucideIcons.store, color: AppColorV2.lpBlueBrand, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  _capitalize(
                    controller.parameter["merchant_name"] ?? "Merchant",
                  ),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColorV2.primaryTextColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // Amount
          Text(
            _formatCurrency(
              double.tryParse(
                    controller.parameter["amount"]?.toString() ?? '0',
                  ) ??
                  0.0,
            ),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColorV2.lpBlueBrand,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'QR Code Payment',
            style: TextStyle(fontSize: 11, color: AppColorV2.bodyTextColor),
          ),
          SizedBox(height: 16),

          // Details
          _buildDownloadDetailItem(
            'Date',
            controller.formatDate(
              DateTime.parse(controller.parameter["date_time"]),
            ),
          ),
          _buildDownloadDetailItem(
            'Time',
            DateFormat('hh:mm a').format(DateTime.now()),
          ),
          _buildDownloadDetailItem(
            'Reference',
            controller.parameter["reference_no"] ?? 'N/A',
          ),
          SizedBox(height: 12),

          // Status
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColorV2.correctState.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'PAYMENT COMPLETED',
              style: TextStyle(
                color: AppColorV2.correctState,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadDetailItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: AppColorV2.bodyTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColorV2.primaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
}
