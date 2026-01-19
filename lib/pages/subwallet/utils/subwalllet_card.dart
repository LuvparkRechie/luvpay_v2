// ignore_for_file: deprecated_member_use

import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:luvpay/custom_widgets/custom_text_v2.dart';

import '../view.dart';

class SubWalletCard extends StatelessWidget {
  final Wallet wallet;
  final VoidCallback onTap;

  final Uint8List? iconBytes;
  final Color base;
  final Color titleColor;
  final Color amountColor;
  final String categoryLabel;

  final bool isDeleting;
  final bool isPulsing;
  final Animation<double> deleteAnim;
  final Animation<double> pulseAnim;

  const SubWalletCard({
    super.key,
    required this.wallet,
    required this.onTap,
    required this.iconBytes,
    required this.base,
    required this.titleColor,
    required this.amountColor,
    required this.categoryLabel,
    required this.isDeleting,
    required this.isPulsing,
    required this.deleteAnim,
    required this.pulseAnim,
  });
  @override
  Widget build(BuildContext context) {
    final borderColor = base;

    final card = GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor.withOpacity(.20), width: 1.6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.06),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: borderColor.withOpacity(.30),
                              width: 1.4,
                            ),
                          ),
                          child: Center(
                            child: ClipOval(
                              child: SizedBox(
                                width: 30,
                                height: 30,
                                child: FittedBox(
                                  fit: BoxFit.contain,
                                  child: buildWalletIcon(iconBytes),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: borderColor.withOpacity(.30),
                              width: 1.2,
                            ),
                          ),
                          child: DefaultText(
                            text: categoryLabel,
                            maxLines: 1,
                            color: titleColor,
                            style: AppTextStyle.body1,
                          ),
                        ),
                      ],
                    ),

                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: borderColor.withOpacity(.35),
                          width: 1.2,
                        ),
                      ),
                      child: Icon(Iconsax.more, size: 18, color: titleColor),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Align(
                  alignment: Alignment.centerLeft,
                  child: DefaultText(
                    text: wallet.name,
                    maxLines: 1,
                    style: AppTextStyle.h3.copyWith(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: titleColor,
                      letterSpacing: .2,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: DefaultText(
                    text: "₱ ${wallet.balance.toStringAsFixed(2)}",
                    maxLines: 1,
                    style: AppTextStyle.h3_semibold.copyWith(
                      fontSize: 18,
                      color: amountColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (isDeleting) {
      return AnimatedBuilder(
        animation: deleteAnim,
        child: card,
        builder: (_, child) {
          final t = 1.0 - deleteAnim.value;
          return Opacity(
            opacity: t.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: t.clamp(0.0, 1.0),
              alignment: Alignment.center,
              child: child,
            ),
          );
        },
      );
    }

    if (!isPulsing) return card;

    return AnimatedBuilder(
      animation: pulseAnim,
      child: card,
      builder: (_, child) {
        final t = pulseAnim.value;
        return Transform.scale(
          scale: 1.0 + (0.04 * t),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: base.withOpacity(0.18 * t),
                  blurRadius: 28 * t,
                  spreadRadius: 2 * t,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: child,
          ),
        );
      },
    );
  }
}
