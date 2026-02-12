// ignore_for_file: deprecated_member_use

import 'dart:typed_data';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';

import 'package:luvpay/shared/widgets/luvpay_text.dart';
import '../../../shared/widgets/neumorphism.dart';
import '../view.dart';

class SubWalletCard extends StatefulWidget {
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

  final bool isSelected;

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
    this.isSelected = false,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final surface = cs.surface;
    final surfaceAlt = cs.surfaceContainerHighest;
    final stroke = cs.outlineVariant.withOpacity(isDark ? 0.14 : 0.05);

    final body = cs.onSurface.withOpacity(0.72);

    final brand = cs.primary;
    final brandBorder = cs.primary.withOpacity(0.18);

    final radius = BorderRadius.circular(24);

    final content = Padding(
      padding: const EdgeInsets.all(10),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 5),
            buildWalletIcon(widget.iconBytes),
            const SizedBox(height: 5),
            LuvpayText(
              text: widget.wallet.name,
              maxLines: 1,
              minFontSize: 14,
              style: AppTextStyle.body2(context),
              color: body,
            ),
          ],
        ),
      ),
    );

    final bool canPress = !widget.isDeleting;
    final bool pressedVisual = canPress && _pressed;

    final double scale = pressedVisual ? 0.972 : 1.0;
    final double yTranslate = pressedVisual ? 1.6 : 0.0;

    final NeumorphicStyle neumorphicStyle = LuvNeu.card(
      radius: radius,
      pressed: pressedVisual,
      selected: widget.isSelected,
      color: surface,

      depth: isDark ? 0.65 : 1.6,
      pressedDepth: isDark ? -0.35 : -0.9,

      borderColor: isDark ? Colors.transparent : stroke,
      borderWidth: isDark ? 0 : 1,

      isDark: isDark,
    );

    final cardCore = Neumorphic(
      style: neumorphicStyle,
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withOpacity(
                    widget.isSelected ? 0.06 : 0.01,
                  ),
                ),
              ),
            ),

            if (widget.isSelected)
              Positioned.fill(
                child: IgnorePointer(
                  child: ClipRRect(
                    borderRadius: radius,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  cs.onSurface.withOpacity(
                                    isDark ? 0.06 : 0.05,
                                  ),
                                ],
                                stops: const [0.60, 1.0],
                              ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  Colors.transparent,
                                  cs.onSurface.withOpacity(
                                    isDark ? 0.045 : 0.04,
                                  ),
                                ],
                                stops: const [0.65, 1.0],
                              ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withOpacity(
                                    isDark ? 0.10 : 0.28,
                                  ),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.42],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            content,

            Align(
              alignment: Alignment.topLeft,
              child: Container(
                padding: const EdgeInsets.only(
                  left: 10,
                  top: 5,
                  bottom: 3,
                  right: 5,
                ),
                decoration: BoxDecoration(
                  color: surfaceAlt,
                  borderRadius: const BorderRadius.only(
                    bottomRight: Radius.circular(12),
                  ),
                  border: Border(
                    bottom: BorderSide(color: brandBorder),
                    right: BorderSide(color: brandBorder),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: brand.withOpacity(0.03),
                      blurRadius: 8,
                      spreadRadius: 1,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
                child: LuvpayText(
                  color: brand,
                  text: "₱ ${widget.wallet.balance.toStringAsFixed(2)}",
                  maxLines: 1,
                  maxFontSize: 12,
                  minFontSize: 8,
                  style: AppTextStyle.body2(
                    context,
                  ).copyWith(fontWeight: FontWeight.w800, color: brand),
                ),
              ),
            ),
          ],
        ),
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
        transform:
            Matrix4.identity()
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
        final glowColor = widget.base;

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
