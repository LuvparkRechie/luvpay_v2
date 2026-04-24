// ignore_for_file: deprecated_member_use

import 'dart:typed_data';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:luvpay/shared/widgets/colors.dart';

import 'package:luvpay/shared/widgets/luvpay_text.dart';
import '../../../core/utils/functions/functions.dart';
import '../view.dart';

class SubWalletTheme {
  final String key;
  final List<Color> gradient;

  const SubWalletTheme(this.key, this.gradient);
}

const List<SubWalletTheme> walletThemes = [
  SubWalletTheme("default", [
    Color(0xFF7EA2FF),
    Color(0xFF5B7CFA),
  ]),
  SubWalletTheme("blue", [
    Color(0xFF6FA8FF),
    Color(0xFF4F7DEB),
  ]),
  SubWalletTheme("teal", [
    Color(0xFF4FE0E6),
    Color(0xFF2FB7A6),
  ]),
  SubWalletTheme("blue_soft", [
    Color(0xFF6EA8FF),
    Color(0xFF5A8DEE),
  ]),
  SubWalletTheme("orange", [
    Color(0xFFFFB08A),
    Color(0xFFFF8A65),
  ]),
  SubWalletTheme("purple", [
    Color(0xFFD17CE5),
    Color(0xFFA259D9),
  ]),
];

class SubWalletCard extends StatefulWidget {
  final Wallet wallet;
  final VoidCallback onTap;

  final Uint8List? iconBytes;

  final Color titleColor;
  final Color amountColor;

  final String categoryLabel;

  final bool isDeleting;
  final bool isPulsing;
  final Animation<double> deleteAnim;
  final Animation<double> pulseAnim;
  final String themeKey;
  final bool isSelected;
  final String? mobileNo;
  final String? userName;
  const SubWalletCard({
    super.key,
    required this.wallet,
    required this.onTap,
    required this.iconBytes,
    required this.titleColor,
    required this.amountColor,
    required this.categoryLabel,
    required this.isDeleting,
    required this.isPulsing,
    required this.deleteAnim,
    required this.themeKey,
    required this.pulseAnim,
    this.isSelected = false,
    this.mobileNo,
    this.userName,
  });

  @override
  State<SubWalletCard> createState() => _SubWalletCardState();
}

class _SubWalletCardState extends State<SubWalletCard> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (!mounted) return;
    if (_pressed == v) return;
    setState(() => _pressed = v);
  }

  Future<List<Color>> resolveWalletGradient(String walletId) async {
    final key = await getWalletColor(walletId);

    final theme = walletThemes.firstWhere(
      (e) => e.key == key,
      orElse: () => walletThemes.first,
    );

    return theme.gradient;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final radius = BorderRadius.circular(24);

    final bool canPress = !widget.isDeleting;
    final bool pressedVisual = canPress && _pressed;

    final double scale = pressedVisual ? 0.972 : 1.0;
    final double yTranslate = pressedVisual ? 1.6 : 0.0;
    final walletTheme = walletThemes.firstWhere(
      (e) => e.key.toLowerCase() == widget.themeKey.toLowerCase(),
      orElse: () => walletThemes.first,
    );
    final cardCore = ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: LinearGradient(
                colors: walletTheme.gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FittedBox(
                  alignment: Alignment.centerLeft,
                  child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: walletTheme.gradient.first.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 28,
                            height: 28,
                            child: Container(
                              padding: const EdgeInsets.all(1),
                              decoration: BoxDecoration(
                                color: AppColorV2.background,
                                shape: BoxShape.circle,
                              ),
                              child: buildWalletIcon(widget.iconBytes),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: 120,
                              ),
                              child: LuvpayText(
                                color: AppColorV2.background,
                                text: widget.categoryLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      )),
                ),
                const SizedBox(height: 10),
                LuvpayText(
                  text: widget.wallet.name,
                  maxLines: 1,
                  style: AppTextStyle.body1(context),
                  color: Colors.white.withOpacity(0.9),
                  overflow: TextOverflow.ellipsis,
                ),
                LuvpayText(
                  text: "Php ${widget.wallet.balance.toStringAsFixed(0)}",
                  color: Colors.white,
                  style: AppTextStyle.h3_f22(context).copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (widget.wallet.isShared) ...[
            Positioned(
              bottom: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const LuvpayText(
                  text: "Shared",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
          Positioned.fill(
            child: Image.asset(
              "assets/images/lp_faint2.png",
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              color: AppColorV2.background.withAlpha(10),
            ),
          ),
        ],
      ),
    );
    final interactiveCard = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: canPress ? (_) => _setPressed(true) : null,
      onTapCancel: canPress ? () => _setPressed(false) : null,
      onTapUp: canPress ? (_) => _setPressed(false) : null,
      onTap: () {
        if (!canPress) return;
        _setPressed(false);
        widget.onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        transform: Matrix4.identity()
          ..translate(0.0, yTranslate)
          ..scale(scale, scale),
        child: cardCore,
      ),
    );

    Widget card = IgnorePointer(
      ignoring: widget.isDeleting,
      child: interactiveCard,
    );

    if (widget.isDeleting) {
      return AnimatedBuilder(
        animation: widget.deleteAnim,
        child: card,
        builder: (_, child) {
          final t = 1.0 - widget.deleteAnim.value;
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

    if (!widget.isPulsing) return card;

    return AnimatedBuilder(
      animation: widget.pulseAnim,
      child: card,
      builder: (_, child) {
        final t = widget.pulseAnim.value;
        final glowColor = walletTheme.gradient.first;
        return Transform.scale(
          scale: 1.0 + (0.05 * t),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: radius,
              boxShadow: [
                BoxShadow(
                  color: glowColor.withOpacity((isDark ? 0.10 : 0.14) * t),
                  blurRadius: 26 * t,
                  spreadRadius: 1.6 * t,
                  offset: const Offset(0, 0),
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
