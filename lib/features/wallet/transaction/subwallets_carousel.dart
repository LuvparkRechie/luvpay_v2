// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../subwallet/utils/subwalllet_card.dart';
import '../../subwallet/view.dart';
import '../../../shared/widgets/colors.dart';

class SubWallerCarousel extends StatelessWidget {
  final List<Wallet> wallets;
  final Function(Wallet) onTap;
  final Function(int, CarouselPageChangedReason)? onPageChanged;

  const SubWallerCarousel({
    super.key,
    required this.wallets,
    required this.onTap,
    this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isSingle = wallets.length == 1;
    const double walletCardRatio = 2.8;

    return CarouselSlider(
      options: CarouselOptions(
        initialPage: 0,
        // initialPage: wallets.length > 1 ? 1 : 0,
        scrollPhysics: const BouncingScrollPhysics(),
        aspectRatio: walletCardRatio,
        enableInfiniteScroll: false,
        viewportFraction: 0.48,
        // padEnds: !isSingle,
        padEnds: false,
        disableCenter: true,
        // disableCenter: isSingle,
        enlargeCenterPage: false,
        // enlargeCenterPage: !isSingle,
        enlargeFactor: 0.12,
        onPageChanged: onPageChanged,
        enlargeStrategy: CenterPageEnlargeStrategy.scale,
      ),
      items: wallets.map((w) {
        final iconBytes = (w.imageBase64?.isNotEmpty ?? false)
            ? decodeBase64Safe(w.imageBase64!)
            : null;

        final categoryLabel =
            (w.categoryTitle.trim().isNotEmpty ? w.categoryTitle : w.category);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: AspectRatio(
              aspectRatio: walletCardRatio,
              child: SubWalletCard(
                wallet: w,
                onTap: () => onTap(w),
                iconBytes: iconBytes,
                themeKey: w.colorTheme,
                titleColor: cs.onSurface,
                amountColor: cs.onSurface.withOpacity(0.72),
                categoryLabel: categoryLabel,
                mobileNo: w.mobileNo,
                userName: w.userName,
                isDeleting: false,
                isPulsing: false,
                deleteAnim: const AlwaysStoppedAnimation(0),
                pulseAnim: const AlwaysStoppedAnimation(1),
              )),
        );
      }).toList(),
    );
  }
}
