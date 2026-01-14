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
          left: 0,
          right: 0,
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          decoration: BoxDecoration(
            color: AppColorV2.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 14),

              Align(
                alignment: Alignment.centerLeft,
                child: const DefaultText(
                  text: "Transfer details",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),

              const SizedBox(height: 14),

              ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _summaryCard(context),
                  const SizedBox(height: 14),

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
                    onTap:
                        refNo.isEmpty
                            ? null
                            : () async {
                              await Clipboard.setData(
                                ClipboardData(text: refNo),
                              );
                            },
                    child: _tile(
                      context,
                      title: "Reference no.",
                      valueWidget: DefaultText(
                        color: AppColorV2.lpBlueBrand,
                        text: refNo.isEmpty ? "—" : refNo,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryCard(BuildContext context) {
    final desc = (data["transfer_desc"] ?? "Wallet Transfer").toString();
    final amountStr = _formatMoneySigned(data["amount"]);
    final isIn = _isIncome(data["amount"]);
    final isOut = _isExpense(data["amount"]);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColorV2.lpBlueBrand.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColorV2.lpBlueBrand.withOpacity(0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isIn
                  ? Icons.arrow_downward_rounded
                  : (isOut
                      ? Icons.arrow_upward_rounded
                      : Icons.swap_horiz_rounded),
              color: AppColorV2.lpBlueBrand,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DefaultText(
                  text: desc,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                DefaultText(
                  text: _formatDateTime(data["transfer_date"]),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          DefaultText(
            text: amountStr,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: DefaultText(
              text: title,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ),
          const SizedBox(width: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child:
                valueWidget ??
                DefaultText(
                  text: value ?? "—",
                  style: const TextStyle(fontWeight: FontWeight.w600),
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
