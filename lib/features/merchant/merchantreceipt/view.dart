// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';

import 'package:luvpay/shared/dialogs/dialogs.dart';
import 'package:luvpay/shared/widgets/custom_scaffold.dart';
import 'package:ticketcher/ticketcher.dart';

import '../../../core/utils/functions/functions.dart';
import '../../../shared/widgets/luvpay_text.dart';
import 'controller.dart';

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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final borderOpacity = isDark ? 0.05 : 0.01;

    return CustomScaffoldV2(
      padding: EdgeInsets.zero,
      canPop: false,
      backgroundColor: cs.surface,
      onPressedLeading: () {
        Get.back(result: true);
        Get.back(result: true);
      },
      scaffoldBody: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 19),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Screenshot(
                controller: _ticketController,
                child: _buildTicketReceiptCard(
                  context,
                  cs: cs,
                  isDark: isDark,
                  borderOpacity: borderOpacity,
                ),
              ),
              const SizedBox(height: 24),
              _buildSaveButton(context, cs: cs, isDark: isDark),
              const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTicketReceiptCard(
    BuildContext context, {
    required ColorScheme cs,
    required bool isDark,
    required double borderOpacity,
  }) {
    final borderColor = cs.onSurface.withOpacity(borderOpacity);

    final merchantName =
        controller.parameter["merchant_name"]?.toString().trim().isEmpty ?? true
            ? "Merchant"
            : controller.parameter["merchant_name"].toString();

    final amount =
        double.tryParse(controller.parameter["amount"]?.toString() ?? '') ??
            0.0;

    final reference = controller.parameter["reference_no"]?.toString() ?? "N/A";

    final orderNo = controller.parameter["order_no"]?.toString() ?? "N/A";

    final walletName =
        controller.parameter["wallet_name"]?.toString().trim().isEmpty ?? true
            ? "Main Wallet"
            : controller.parameter["wallet_name"].toString();

    final raw = controller.parameter["date_time"];

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
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(isDark ? 0.18 : 0.10),
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor),
                ),
                child: Icon(Icons.check_rounded, color: cs.primary, size: 32),
              ),
              const SizedBox(height: 14),
              LuvpayText(
                text: 'Payment Successful',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  LuvpayText(
                    text: "AMOUNT PAID",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface.withOpacity(0.60),
                    ),
                  ),
                  LuvpayText(
                    text: _formatCurrency(amount),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: cs.primary,
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
              _row(cs, 'STATUS', 'COMPLETED', bold: true),
              const SizedBox(height: 10),
              _row(cs, 'DATE', Functions.formatPHDate(raw)),
              const SizedBox(height: 10),
              _row(cs, 'TIME', Functions.formatPHTime(raw)),
              const SizedBox(height: 10),
              _row(cs, 'MERCHANT', merchantName),
              const SizedBox(height: 10),
              _row(cs, 'REFERENCE', reference),
              const SizedBox(height: 10),
              if (orderNo.isNotEmpty) _row(cs, 'ORDER NO.', orderNo),
              const SizedBox(height: 10),
              _row(cs, 'PAID FROM', walletName),
            ],
          ),
        ),
        Section(
          padding: const EdgeInsets.fromLTRB(20, 25, 20, 16),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    Image.asset("assets/images/logo.png", height: 38),
                    const SizedBox(height: 8),
                    LuvpayText(
                      text: 'Thank you for your payment!',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    LuvpayText(
                      text: 'Keep this receipt for your records',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface.withOpacity(0.60),
                      ),
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

  Widget _row(ColorScheme cs, String title, String value, {bool bold = false}) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: LuvpayText(
            text: title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: cs.onSurface.withOpacity(0.58),
            ),
          ),
        ),
        Expanded(
          flex: 6,
          child: LuvpayText(
            text: value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12,
              fontWeight: bold ? FontWeight.w900 : FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMerchantInfo(
    BuildContext context, {
    required ColorScheme cs,
    required bool isDark,
    required double borderOpacity,
  }) {
    String merchantName =
        controller.parameter["merchant_name"]?.toString().trim() ?? "";

    if (merchantName.isEmpty) {
      merchantName = "Merchant";
    }
    final borderColor = cs.onSurface.withOpacity(borderOpacity);

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: cs.primary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: const Icon(LucideIcons.store, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LuvpayText(
                text: 'PAID TO',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w900,
                  color: cs.onSurface.withOpacity(0.55),
                ),
              ),
              const SizedBox(height: 4),
              LuvpayText(
                text: _capitalize(merchantName),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: cs.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAmountSection(BuildContext context, {required ColorScheme cs}) {
    final amt =
        double.tryParse(controller.parameter["amount"]?.toString() ?? '') ??
            0.0;
    return Column(
      children: [
        LuvpayText(
          text: 'AMOUNT PAID',
          style: TextStyle(
            fontSize: 12,
            letterSpacing: 1,
            fontWeight: FontWeight.w900,
            color: cs.onSurface.withOpacity(0.55),
          ),
        ),
        const SizedBox(height: 6),
        LuvpayText(
          text: _formatCurrency(amt),
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w900,
            color: cs.primary,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionDetails(
    BuildContext context, {
    required ColorScheme cs,
  }) {
    DateTime? dt;

    final raw = controller.parameter["date_time"]?.toString();

    try {
      dt = DateTime.tryParse(raw ?? "");

      if (dt == null && raw != null && raw.isNotEmpty) {
        dt = DateFormat("yyyy-MM-dd HH:mm:ss").parse(raw);
      }
    } catch (_) {}

    final dateTxt = dt != null ? controller.formatDate(dt) : "N/A";
    final timeTxt = dt != null ? DateFormat('hh:mm a').format(dt) : "N/A";

    final walletName = (controller.parameter["wallet_name"] == null ||
            controller.parameter["wallet_name"].toString().trim().isEmpty)
        ? "Main Wallet"
        : controller.parameter["wallet_name"].toString();

    final reference = (controller.parameter["reference_no"] == null ||
            controller.parameter["reference_no"].toString().trim().isEmpty)
        ? "N/A"
        : controller.parameter["reference_no"].toString();

    final orderNo = (controller.parameter["order_no"] == null ||
            controller.parameter["order_no"].toString().trim().isEmpty)
        ? "N/A"
        : controller.parameter["order_no"].toString();

    return Column(
      children: [
        _detailRow(context, cs, 'Date', dateTxt),
        _detailRow(context, cs, 'Time', timeTxt),
        _detailRow(context, cs, 'Reference', reference),
        _detailRow(context, cs, 'Order No', orderNo),
        _detailRow(context, cs, 'Paid From', walletName),
      ],
    );
  }

  Widget _detailRow(
    BuildContext context,
    ColorScheme cs,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          LuvpayText(
            text: label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: cs.onSurface.withOpacity(0.55),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: LuvpayText(
              text: value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: cs.onSurface,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(
    BuildContext context, {
    required ColorScheme cs,
    required bool isDark,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.download_rounded),
        label: const LuvpayText(text: 'Save Receipt'),
        style: OutlinedButton.styleFrom(
          foregroundColor: cs.primary,
          side: BorderSide(color: cs.primary.withOpacity(isDark ? 0.55 : 0.75)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
        ),
        onPressed: _saveReceipt,
      ),
    );
  }

  void _saveReceipt() async {
    CustomDialogStack.showLoading(Get.context!);

    try {
      final image = await _ticketController.capture(
        delay: const Duration(milliseconds: 250),
        pixelRatio: 3,
      );

      if (image == null) throw 'Capture failed';

      final dir = await getApplicationDocumentsDirectory();
      final file = File(
        '${dir.path}/merchant_ticket_${DateTime.now().millisecondsSinceEpoch}.png',
      );

      await file.writeAsBytes(image);
      await GallerySaver.saveImage(file.path);

      if (Get.isDialogOpen == true) {
        Get.back();
        return;
      }
      Get.back();
      CustomDialogStack.showSuccess(
        Get.context!,
        "Saved",
        "Receipt saved to gallery",
        () => Get.back(),
      );
    } catch (_) {
      if (Get.isDialogOpen == true) Get.back();
      CustomDialogStack.showError(
        Get.context!,
        "Error",
        "Failed to save receipt. Please try again.",
        () => Get.back(),
      );
    }
  }

  String _formatCurrency(double amount) => '₱${amount.toStringAsFixed(2)}';

  String _capitalize(String text) =>
      text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
}
