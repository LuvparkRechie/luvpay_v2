// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';

import 'package:luvpay/custom_widgets/alert_dialog.dart';
import 'package:luvpay/custom_widgets/luvpay/custom_scaffold.dart';

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
              _buildHeader(
                context,
                cs: cs,
                isDark: isDark,
                borderOpacity: borderOpacity,
              ),
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

  Widget _buildHeader(
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
        const SizedBox(height: 12),
        Text(
          'Payment Successful',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.2,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Keep this receipt for your records',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: cs.onSurface.withOpacity(0.60),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTicketReceiptCard(
    BuildContext context, {
    required ColorScheme cs,
    required bool isDark,
    required double borderOpacity,
  }) {
    final borderColor = cs.onSurface.withOpacity(borderOpacity);

    return PhysicalShape(
      clipper: TicketClipper(notchRadius: 14),
      elevation: 10,
      color: cs.surface,
      shadowColor: cs.shadow.withOpacity(isDark ? 0.30 : 0.10),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  _buildMerchantInfo(
                    context,
                    cs: cs,
                    isDark: isDark,
                    borderOpacity: borderOpacity,
                  ),
                  const SizedBox(height: 18),
                  _buildAmountSection(context, cs: cs),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DashedLine(
                color: cs.onSurface.withOpacity(isDark ? 0.18 : 0.12),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(22),
              child: _buildTransactionDetails(context, cs: cs),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMerchantInfo(
    BuildContext context, {
    required ColorScheme cs,
    required bool isDark,
    required double borderOpacity,
  }) {
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
              Text(
                'PAID TO',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w900,
                  color: cs.onSurface.withOpacity(0.55),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _capitalize(
                  controller.parameter["merchant_name"] ?? "Merchant",
                ),
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
        double.tryParse(controller.parameter["amount"]?.toString() ?? '0') ?? 0;

    return Column(
      children: [
        Text(
          'AMOUNT PAID',
          style: TextStyle(
            fontSize: 12,
            letterSpacing: 1,
            fontWeight: FontWeight.w900,
            color: cs.onSurface.withOpacity(0.55),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _formatCurrency(amt),
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
    try {
      dt = DateTime.tryParse(
        controller.parameter["date_time"]?.toString() ?? "",
      );
    } catch (_) {}

    final dateTxt = dt != null ? controller.formatDate(dt) : "N/A";
    final timeTxt = dt != null ? DateFormat('hh:mm a').format(dt) : "N/A";

    return Column(
      children: [
        _detailRow(context, cs, 'Date', dateTxt),
        _detailRow(context, cs, 'Time', timeTxt),
        _detailRow(
          context,
          cs,
          'Reference',
          controller.parameter["reference_no"] ?? 'N/A',
        ),
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
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: cs.onSurface.withOpacity(0.55),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
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
        label: const Text('Save Receipt'),
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

      if (Get.isDialogOpen == true) Get.back();
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
