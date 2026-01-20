// ignore_for_file: deprecated_member_use

import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:luvpay/custom_widgets/app_color_v2.dart';
import 'package:luvpay/custom_widgets/custom_text_v2.dart';

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
            DefaultText(
              text: widget.wallet.name,
              maxLines: 1,
              minFontSize: 14,
              style: AppTextStyle.body2,
              color: AppColorV2.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );

    // Press effect values
    final bool canPress = !widget.isDeleting;
    final bool pressedVisual = canPress && _pressed;

    final double scale = pressedVisual ? 0.965 : 1.0;
    final double yTranslate = pressedVisual ? 2.0 : 0.0;

    final normalShadows = <BoxShadow>[
      BoxShadow(
        color: const Color(0xFF0F172A).withOpacity(0.10),
        blurRadius: 34,
        spreadRadius: 1,
        offset: const Offset(0, 0),
      ),
      BoxShadow(
        color: const Color(0xFF0F172A).withOpacity(0.06),
        blurRadius: 16,
        spreadRadius: 0,
        offset: const Offset(0, 0),
      ),
    ];

    final pressedShadows = <BoxShadow>[
      BoxShadow(
        color: const Color(0xFF0F172A).withOpacity(0.08),
        blurRadius: 16,
        spreadRadius: 0,
        offset: const Offset(0, 6),
      ),
    ];

    final cardCore = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow:
            widget.isSelected
                ? []
                : (pressedVisual ? pressedShadows : normalShadows),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: radius,
                color: Colors.white.withOpacity(
                  widget.isSelected ? 0.88 : 0.92,
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
                                  const Color(0xFF0F172A).withOpacity(0.08),
                                ],
                                stops: const [0.55, 1.0],
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
                                  const Color(0xFF0F172A).withOpacity(0.06),
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
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withOpacity(0.70),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.45],
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
                  boxShadow: [
                    BoxShadow(
                      color: AppColorV2.lpBlueBrand.withOpacity(.45),
                      blurRadius: 2,
                      spreadRadius: 1,
                      offset: const Offset(0, 0),
                    ),
                    BoxShadow(
                      color: AppColorV2.lpBlueBrand.withOpacity(.45),
                      blurRadius: 2,
                      spreadRadius: 0,
                      offset: const Offset(0, 0),
                    ),
                  ],
                  color: AppColorV2.lpBlueBrand.withOpacity(.45),
                  borderRadius: const BorderRadius.only(
                    bottomRight: Radius.circular(12),
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: AppColorV2.lpBlueBrand.withOpacity(.20),
                    ),
                    right: BorderSide(
                      color: AppColorV2.lpBlueBrand.withOpacity(.20),
                    ),
                  ),
                ),
                child: DefaultText(
                  color: AppColorV2.background,
                  text: "₱ ${widget.wallet.balance.toStringAsFixed(2)}",
                  maxLines: 1,
                  maxFontSize: 8,
                  minFontSize: 8,
                  style: AppTextStyle.body2,
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
        return Transform.scale(
          scale: 1.0 + (0.06 * t),

          child: Container(
            decoration: BoxDecoration(
              borderRadius: radius,
              boxShadow: [
                BoxShadow(
                  color: widget.base.withOpacity(0.18 * t),
                  blurRadius: 28 * t,
                  spreadRadius: 2 * t,
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
