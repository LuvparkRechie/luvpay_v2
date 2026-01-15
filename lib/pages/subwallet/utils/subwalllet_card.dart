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
    final outerBorder = const Color(0xFF0F172A).withOpacity(.01);
    final innerTintBorder = WalletTileTheme.darken(base, .10).withOpacity(.01);
    final shadow = const Color(0xFF0F172A).withOpacity(.08);

    final card = GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      WalletTileTheme.lighten(base, .14).withOpacity(1),
                      WalletTileTheme.lighten(base, .08).withOpacity(.50),
                    ],
                  ),
                ),
              ),
            ),

            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: const SizedBox(),
              ),
            ),

            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: outerBorder, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: shadow,
                      blurRadius: 22,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(1),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(23),
                    border: Border.all(color: innerTintBorder, width: 1),
                  ),
                ),
              ),
            ),

            Padding(
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
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withOpacity(.90),
                                  Colors.white.withOpacity(.30),
                                ],
                              ),
                              border: Border.all(
                                color: const Color(0xFF0F172A).withOpacity(.10),
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
                              borderRadius: BorderRadius.circular(999),
                              color: Colors.white.withOpacity(.55),
                              border: Border.all(
                                color: const Color(0xFF0F172A).withOpacity(.08),
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
                          borderRadius: BorderRadius.circular(14),
                          color: Colors.white.withOpacity(.50),
                          border: Border.all(
                            color: const Color(0xFF0F172A).withOpacity(.08),
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

            Positioned(
              top: -34,
              left: -44,
              child: Transform.rotate(
                angle: -0.45,
                child: Container(
                  width: 190,
                  height: 110,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(60),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(.24),
                        Colors.white.withOpacity(0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
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
