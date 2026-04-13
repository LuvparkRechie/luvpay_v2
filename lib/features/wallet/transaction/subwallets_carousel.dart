import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

import '../../subwallet/utils/subwalllet_card.dart';
import '../../subwallet/view.dart';

class SubWallerCarousel extends StatelessWidget {
  final List<Wallet> wallets;
  final Function(Wallet) onTap;

  const SubWallerCarousel({
    super.key,
    required this.wallets,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return CarouselSlider(
      options: CarouselOptions(
        scrollPhysics: const BouncingScrollPhysics(),
        height: 120,
        enableInfiniteScroll: false,
        viewportFraction: 0.55,
        padEnds: false,
        disableCenter: true,
        enlargeCenterPage: true,
        enlargeFactor: 0.15,
      ),
      items: wallets.map((w) {
        final iconBytes = (w.imageBase64?.isNotEmpty ?? false)
            ? decodeBase64Safe(w.imageBase64!)
            : null;

        final categoryLabel =
            (w.categoryTitle.trim().isNotEmpty ? w.categoryTitle : w.category);

        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: SubWalletCard(
            wallet: w,
            onTap: () => onTap(w),
            iconBytes: iconBytes,
            base: w.color,
            titleColor: cs.onSurface,
            amountColor: cs.onSurface.withOpacity(0.72),
            categoryLabel: categoryLabel,
            isDeleting: false,
            isPulsing: false,
            deleteAnim: const AlwaysStoppedAnimation(0),
            pulseAnim: const AlwaysStoppedAnimation(1),
          ),
        );
      }).toList(),
    );
  }
}
