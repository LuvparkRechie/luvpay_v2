// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:luvpay/custom_widgets/app_color_v2.dart';
import 'package:luvpay/custom_widgets/custom_text_v2.dart';

class FloatingCreateSubwalletButton extends StatelessWidget {
  final VoidCallback onTap;

  const FloatingCreateSubwalletButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(right: 16, bottom: 16 + bottomPad),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: AppColorV2.lpBlueBrand,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(.18),
                  ),
                  child: const Icon(Iconsax.add, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 10),
                DefaultText(
                  text: "Create subwallet",
                  style: AppTextStyle.paragraph1.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
