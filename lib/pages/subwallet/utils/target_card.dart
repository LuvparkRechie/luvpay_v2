// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:luvpay/custom_widgets/app_color_v2.dart';

class TargetCard extends StatelessWidget {
  final double balance;
  final double? target;
  final VoidCallback onTapSet;

  const TargetCard({
    super.key,
    required this.balance,
    required this.target,
    required this.onTapSet,
  });

  @override
  Widget build(BuildContext context) {
    final hasTarget = (target ?? 0) > 0;
    final t = target ?? 0;

    final pct = hasTarget ? (balance / t).clamp(0.0, 1.0) : 0.0;
    final percentText = '${(pct * 100).toStringAsFixed(0)}%';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withAlpha(14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "Target",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Colors.black.withAlpha(170),
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: onTapSet,
                  child: Ink(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: AppColorV2.lpBlueBrand.withAlpha(12),
                      border: Border.all(
                        color: AppColorV2.lpBlueBrand.withAlpha(50),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          hasTarget ? Iconsax.edit_2 : Iconsax.flag,
                          size: 16,
                          color: AppColorV2.lpBlueBrand,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          hasTarget ? "Update" : "Set target",
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            color: AppColorV2.lpBlueBrand,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: Text(
                  hasTarget ? "₱ ${t.toStringAsFixed(2)}" : "No target set",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (hasTarget)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: AppColorV2.lpBlueBrand.withAlpha(12),
                    border: Border.all(
                      color: AppColorV2.lpBlueBrand.withAlpha(40),
                    ),
                  ),
                  child: Text(
                    percentText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: AppColorV2.lpBlueBrand,
                    ),
                  ),
                ),
            ],
          ),

          if (hasTarget) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 9,
                backgroundColor: Colors.black.withAlpha(10),
                valueColor: AlwaysStoppedAnimation(AppColorV2.lpBlueBrand),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  "Saved: ₱ ${balance.toStringAsFixed(2)}",
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.black.withAlpha(130),
                  ),
                ),
                const Spacer(),
                Text(
                  "Remaining: ₱ ${(t - balance).clamp(0, double.infinity).toStringAsFixed(2)}",
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.black.withAlpha(130),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
