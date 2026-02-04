// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:luvpay/custom_widgets/app_color_v2.dart';
import '../../../custom_widgets/custom_text_v2.dart';
import '../../../custom_widgets/luvpay/neumorphism.dart';

class TransferDetailsModal extends StatelessWidget {
  final Map<String, dynamic> data;

  const TransferDetailsModal({super.key, required this.data});

  Color _border(ColorScheme cs, bool isDark, [double? o]) =>
      cs.outlineVariant.withOpacity(o ?? (isDark ? 0.22 : 0.35));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final refNo = (data["ref_no"] ?? "").toString().trim();

    final bg = cs.surface;
    final stroke = _border(cs, isDark);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 46,
                height: 5,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: cs.onSurface.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),

              Row(
                children: [
                  Expanded(
                    child: DefaultText(
                      text: "Transfer details",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  LuvNeuIconButton(
                    icon: Icons.close_rounded,
                    onTap: () => Navigator.of(context).pop(),
                    size: 40,
                    iconSize: 18,
                  ),
                ],
              ),

              const SizedBox(height: 14),

              ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _summaryCard(context),

                  const SizedBox(height: 12),

                  _tile(
                    context,
                    title: "Balance before",
                    value: _formatMoney(data["amount_bal_bfore"]),
                  ),
                  _tile(
                    context,
                    title: "Balance after",
                    value: _formatMoney(data["amount_bal_after"]),
                  ),

                  InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap:
                        refNo.isEmpty
                            ? null
                            : () async {
                              await Clipboard.setData(
                                ClipboardData(text: refNo),
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                      "Reference number copied",
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                    duration: const Duration(seconds: 1),
                                    margin: const EdgeInsets.all(16),
                                  ),
                                );
                              }
                            },
                    child: _tile(
                      context,
                      title: "Reference no.",
                      valueWidget: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          DefaultText(
                            color: cs.primary,
                            text: refNo.isEmpty ? "—" : refNo,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          if (refNo.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.copy_rounded,
                              size: 16,
                              color: cs.primary.withOpacity(0.80),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  if (refNo.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Text(
                        "Tap reference number to copy",
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface.withOpacity(0.60),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryCard(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final desc = (data["transfer_desc"] ?? "Wallet Transfer").toString();
    final amountStr = _formatMoneySigned(data["amount"]);
    final isIn = _isIncome(data["amount"]);
    final isOut = _isExpense(data["amount"]);

    // Use themed colors; keep green/red for semantic but align opacity with theme.
    final accent = isIn ? cs.tertiary : (isOut ? cs.error : cs.primary);

    final radius = BorderRadius.circular(20);
    final stroke = _border(cs, isDark);

    return LuvNeuPress(
      radius: radius,
      onTap: null,
      depth: 1.8,
      pressedDepth: -0.8,
      overlayOpacity: 0.02,
      background: cs.surfaceContainerHighest,
      borderColor: stroke,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            LuvNeuPress(
              radius: BorderRadius.circular(16),
              onTap: null,
              depth: 1.4,
              pressedDepth: -0.7,
              overlayOpacity: 0.015,
              background: cs.surfaceContainerHigh,
              borderColor: stroke.withOpacity(0.90),
              child: SizedBox(
                width: 46,
                height: 46,
                child: Center(
                  child: Icon(
                    isIn
                        ? Icons.arrow_downward_rounded
                        : (isOut
                            ? Icons.arrow_upward_rounded
                            : Icons.swap_horiz_rounded),
                    color: accent,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DefaultText(
                    text: desc,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  DefaultText(
                    text: _formatDateTime(data["transfer_date"]),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface.withOpacity(0.65),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            DefaultText(
              text: amountStr,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              color: isIn ? cs.tertiary : (isOut ? cs.error : cs.onSurface),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required String title,
    String? value,
    Widget? valueWidget,
    Color? valueColor,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final radius = BorderRadius.circular(18);
    final stroke = _border(cs, isDark);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: LuvNeuPress(
        radius: radius,
        onTap: null,
        depth: 1.4,
        pressedDepth: -0.7,
        overlayOpacity: 0.02,
        background: cs.surfaceContainerHighest,
        borderColor: stroke,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: DefaultText(
                  text: title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface.withOpacity(0.70),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 220),
                child:
                    valueWidget ??
                    DefaultText(
                      text: value ?? "—",
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: valueColor ?? cs.onSurface,
                      ),
                      textAlign: TextAlign.right,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isIncome(dynamic amount) {
    final v = _toDouble(amount);
    return v > 0;
  }

  bool _isExpense(dynamic amount) {
    final v = _toDouble(amount);
    return v < 0;
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString().replaceAll(',', '')) ?? 0.0;
  }

  String _formatMoney(dynamic v) {
    final n = _toDouble(v);
    return '₱ ${n.toStringAsFixed(2)}';
  }

  String _formatMoneySigned(dynamic v) {
    final n = _toDouble(v);
    final sign = n > 0 ? '+' : (n < 0 ? '-' : '');
    return '$sign₱ ${n.abs().toStringAsFixed(2)}';
  }

  String _formatDateTime(dynamic input) {
    final s = (input ?? "").toString().trim();
    if (s.isEmpty) return "—";
    try {
      final dt = DateTime.parse(s).toLocal();
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final m = months[dt.month - 1];
      final day = dt.day.toString().padLeft(2, '0');
      final hour12 = ((dt.hour % 12) == 0 ? 12 : (dt.hour % 12));
      final mm = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour >= 12 ? "PM" : "AM";
      return '$m $day, ${dt.year} • $hour12:$mm $ampm';
    } catch (_) {
      return s;
    }
  }
}
