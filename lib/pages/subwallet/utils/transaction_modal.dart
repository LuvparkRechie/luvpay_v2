import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:luvpay/custom_widgets/app_color_v2.dart';
import '../../../custom_widgets/custom_text_v2.dart';

class TransferDetailsModal extends StatelessWidget {
  final Map<String, dynamic> data;

  const TransferDetailsModal({super.key, required this.data});
  @override
  Widget build(BuildContext context) {
    final refNo = (data["ref_no"] ?? "").toString().trim();

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          decoration: BoxDecoration(
            color: AppColorV2.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 46,
                height: 5,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(25),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),

              Row(
                children: [
                  const Expanded(
                    child: DefaultText(
                      text: "Transfer details",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.of(context).pop(),
                    child: Ink(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.black.withAlpha(10),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: Colors.black.withAlpha(130),
                      ),
                    ),
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
                            color: AppColorV2.lpBlueBrand,
                            text: refNo.isEmpty ? "—" : refNo,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          if (refNo.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.copy_rounded,
                              size: 16,
                              color: AppColorV2.lpBlueBrand.withAlpha(180),
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
                          color: Colors.black.withAlpha(110),
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
    final desc = (data["transfer_desc"] ?? "Wallet Transfer").toString();
    final amountStr = _formatMoneySigned(data["amount"]);
    final isIn = _isIncome(data["amount"]);
    final isOut = _isExpense(data["amount"]);

    final accent =
        isIn ? Colors.green : (isOut ? Colors.red : AppColorV2.lpBlueBrand);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withAlpha(14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: accent.withAlpha(18),
            ),
            child: Icon(
              isIn
                  ? Icons.arrow_downward_rounded
                  : (isOut
                      ? Icons.arrow_upward_rounded
                      : Icons.swap_horiz_rounded),
              color: accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DefaultText(
                  text: desc,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                DefaultText(
                  text: _formatDateTime(data["transfer_date"]),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withAlpha(120),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          DefaultText(
            text: amountStr,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            color: isIn ? Colors.green : (isOut ? Colors.red : null),
          ),
        ],
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

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withAlpha(14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: DefaultText(
              text: title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.black.withAlpha(130),
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
                  style: const TextStyle(fontWeight: FontWeight.w800),
                  color: valueColor,
                  textAlign: TextAlign.right,
                ),
          ),
        ],
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
