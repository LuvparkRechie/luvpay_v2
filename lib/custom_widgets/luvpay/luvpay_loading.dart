import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:luvpay/custom_widgets/app_color_v2.dart';

class PremiumSpinner extends StatefulWidget {
  final double size;
  final double strokeWidth;
  final Color color;
  final Color? glowColor;

  const PremiumSpinner({
    super.key,
    this.size = 18,
    this.strokeWidth = 2.3,
    required this.color,
    this.glowColor,
  });

  @override
  State<PremiumSpinner> createState() => _PremiumSpinnerState();
}

class _PremiumSpinnerState extends State<PremiumSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glow = widget.glowColor ?? widget.color;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          return Transform.rotate(
            angle: _ctrl.value * 6.283185307179586,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: glow.withOpacity(.20),
                        blurRadius: 14,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                CircularProgressIndicator(
                  strokeWidth: widget.strokeWidth,
                  valueColor: AlwaysStoppedAnimation(widget.color),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class PremiumFrostCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double radius;

  const PremiumFrostCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    this.radius = 18,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.72),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: const Color(0xFF0F172A).withOpacity(.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.10),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class PremiumLoaderOverlay extends StatelessWidget {
  final bool loading;
  final Widget child;

  final String title;
  final String? subtitle;

  final Color accentColor;
  final Color? glowColor;

  final bool barrierDismissible;

  const PremiumLoaderOverlay({
    super.key,
    required this.loading,
    required this.child,
    this.title = "Loading…",
    this.subtitle,
    required this.accentColor,
    this.glowColor,
    this.barrierDismissible = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child:
              !loading
                  ? const SizedBox.shrink()
                  : Positioned.fill(
                    child: IgnorePointer(
                      ignoring: barrierDismissible,
                      child: Container(
                        decoration: BoxDecoration(color: AppColorV2.background),

                        child: Center(
                          child: PremiumFrostCard(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                PremiumSpinner(
                                  size: 20,
                                  strokeWidth: 2.4,
                                  color: accentColor,
                                  glowColor: glowColor,
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: .2,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    if (subtitle != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        subtitle!,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(
                                            0xFF0F172A,
                                          ).withOpacity(.62),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
        ),
      ],
    );
  }
}

class PremiumRefreshOverlay extends StatelessWidget {
  final bool refreshing;
  final Widget child;

  final String label;
  final Color accentColor;
  final Color? glowColor;

  final bool blockTouches;

  const PremiumRefreshOverlay({
    super.key,
    required this.refreshing,
    required this.child,
    this.label = "Refreshing…",
    required this.accentColor,
    this.glowColor,
    this.blockTouches = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child:
              !refreshing
                  ? const SizedBox.shrink()
                  : Positioned.fill(
                    child: IgnorePointer(
                      ignoring: !blockTouches,
                      child: Container(
                        color: AppColorV2.background,
                        child: Center(
                          child: PremiumFrostCard(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                PremiumSpinner(
                                  size: 18,
                                  strokeWidth: 2.2,
                                  color: accentColor,
                                  glowColor: glowColor,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  label,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: .2,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
        ),
      ],
    );
  }
}
