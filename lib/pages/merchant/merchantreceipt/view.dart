import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:luvpay/custom_widgets/app_color_v2.dart';
import 'package:luvpay/custom_widgets/luvpay/custom_scaffold.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';

import '../../../custom_widgets/alert_dialog.dart';
import 'controller.dart';

/// ─────────────────────────────────────────
/// 🎟️ TICKET CLIPPER
/// ─────────────────────────────────────────
class TicketClipper extends CustomClipper<Path> {
  final double notchRadius;

  TicketClipper({this.notchRadius = 12});

  @override
  Path getClip(Size size) {
    final r = notchRadius;
    final path = Path();

    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height / 2 - r);
    path.arcToPoint(
      Offset(size.width, size.height / 2 + r),
      radius: Radius.circular(r),
      clockwise: false,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.lineTo(0, size.height / 2 + r);
    path.arcToPoint(
      Offset(0, size.height / 2 - r),
      radius: Radius.circular(r),
      clockwise: false,
    );
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

/// ─────────────────────────────────────────
/// ✂️ DASHED PERFORATION
/// ─────────────────────────────────────────
class DashedLine extends StatelessWidget {
  final Color color;

  const DashedLine({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        const dashWidth = 6.0;
        const dashGap = 4.0;
        final count = (constraints.maxWidth / (dashWidth + dashGap)).floor();

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            count,
            (_) => SizedBox(
              width: dashWidth,
              height: 1,
              child: DecoratedBox(decoration: BoxDecoration(color: color)),
            ),
          ),
        );
      },
    );
  }
}

class MerchantQRReceipt extends GetView<MerchantQRRController> {
  MerchantQRReceipt({super.key});
  final ScreenshotController _ticketController = ScreenshotController();
  @override
  Widget build(BuildContext context) {
    return CustomScaffoldV2(
      padding: EdgeInsets.zero,
      canPop: false,
      backgroundColor: Colors.white,
      onPressedLeading: () => Get.back(result: true),
      scaffoldBody: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 19),
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildHeader(),
              const SizedBox(height: 20),
              Screenshot(
                controller: _ticketController,
                child: _buildTicketReceiptCard(),
              ),

              const SizedBox(height: 32),
              _buildSaveButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// ───────────────── HEADER ─────────────────
  Widget _buildHeader() {
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
        const Text(
          'Payment Successful',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  /// ───────────────── MAIN TICKET ─────────────────
  Widget _buildTicketReceiptCard() {
    return PhysicalShape(
      clipper: TicketClipper(notchRadius: 14),
      elevation: 10,
      color: Colors.white,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildMerchantInfo(),
                  const SizedBox(height: 20),
                  _buildAmountSection(),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DashedLine(color: AppColorV2.boxStroke),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: _buildTransactionDetails(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMerchantInfo() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColorV2.lpBlueBrand,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(LucideIcons.store, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PAID TO',
                style: TextStyle(fontSize: 10, letterSpacing: 0.8),
              ),
              const SizedBox(height: 4),
              Text(
                _capitalize(
                  controller.parameter["merchant_name"] ?? "Merchant",
                ),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAmountSection() {
    return Column(
      children: [
        const Text(
          'AMOUNT PAID',
          style: TextStyle(fontSize: 12, letterSpacing: 1),
        ),
        const SizedBox(height: 6),
        Text(
          _formatCurrency(
            double.tryParse(
                  controller.parameter["amount"]?.toString() ?? '0',
                ) ??
                0,
          ),
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: AppColorV2.lpBlueBrand,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionDetails() {
    return Column(
      children: [
        _detailRow(
          'Date',
          controller.formatDate(
            DateTime.parse(controller.parameter["date_time"]),
          ),
        ),
        _detailRow('Time', DateFormat('hh:mm a').format(DateTime.now())),
        _detailRow('Reference', controller.parameter["reference_no"] ?? 'N/A'),
      ],
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11)),
          Text(
            value,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  /// ───────────────── SAVE BUTTON ─────────────────
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.download_rounded),
        label: const Text('Save Receipt'),
        onPressed: _saveReceipt,
      ),
    );
  }

  /// ───────────────── SAVE LOGIC ─────────────────
  void _saveReceipt() async {
    CustomDialogStack.showLoading(Get.context!);

    try {
      final image = await _ticketController.capture(
        delay: const Duration(milliseconds: 250),
        pixelRatio: 3, // crisp image
      );

      if (image == null) throw 'Capture failed';

      final dir = await getApplicationDocumentsDirectory();
      final file = File(
        '${dir.path}/merchant_ticket_${DateTime.now().millisecondsSinceEpoch}.png',
      );

      await file.writeAsBytes(image);
      await GallerySaver.saveImage(file.path);

      Get.back();
      CustomDialogStack.showSuccess(
        Get.context!,
        "Saved",
        "Receipt saved to gallery",
        () => Get.back(),
      );
    } catch (e) {
      Get.back();
      CustomDialogStack.showError(
        Get.context!,
        "Error",
        "Failed to save receipt. Please try again.",
        () {
          Get.back();
        },
      );
    }
  }

  String _formatCurrency(double amount) => '₱${amount.toStringAsFixed(2)}';

  String _capitalize(String text) =>
      text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
}
