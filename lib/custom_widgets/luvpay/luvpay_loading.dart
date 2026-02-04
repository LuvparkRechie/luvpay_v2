// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:flutter/material.dart';

class PremiumSpinner extends StatefulWidget {
  final double size;
  final double strokeWidth;

  final Color? color;

  final Color? glowColor;

  const PremiumSpinner({
    super.key,
    this.size = 18,
    this.strokeWidth = 2.3,
    this.color,
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
    final cs = Theme.of(context).colorScheme;

    final spinnerColor = widget.color ?? cs.primary;
    final glow = widget.glowColor ?? spinnerColor;

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
                  valueColor: AlwaysStoppedAnimation(spinnerColor),
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

  final Color? frostColor;

  const PremiumFrostCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    this.radius = 18,
    this.frostColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final base = frostColor ?? cs.surface;
    final glass = Color.lerp(base, cs.background, isDark ? 0.12 : 0.06) ?? base;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: glass.withOpacity(isDark ? .62 : .78),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: cs.outlineVariant.withOpacity(isDark ? .05 : .01),
              width: 0.9,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? .35 : .10),
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

  final Color? accentColor;
  final Color? glowColor;

  final bool barrierDismissible;

  final double topInset;

  const PremiumLoaderOverlay({
    super.key,
    required this.loading,
    required this.child,
    this.title = "Loading…",
    this.subtitle,
    this.accentColor,
    this.glowColor,
    this.barrierDismissible = false,
    this.topInset = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final spinnerColor = accentColor ?? cs.primary;

    return Stack(
      children: [
        child,
        Positioned(
          top: topInset,
          left: 0,
          right: 0,
          bottom: 0,
          child: IgnorePointer(
            ignoring: barrierDismissible,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder:
                  (w, anim) => FadeTransition(opacity: anim, child: w),
              child:
                  !loading
                      ? const SizedBox.shrink(key: ValueKey("loader_off"))
                      : Container(
                        key: const ValueKey("loader_on"),
                        color: cs.scrim.withOpacity(isDark ? 0.05 : 0.01),
                        alignment: Alignment.center,
                        child: PremiumFrostCard(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              PremiumSpinner(
                                size: 20,
                                strokeWidth: 2.4,
                                color: spinnerColor,
                                glowColor: glowColor,
                              ),
                              const SizedBox(width: 12),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: .2,
                                      color: cs.onSurface,
                                    ),
                                  ),
                                  if (subtitle != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      subtitle!,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: cs.onSurface.withOpacity(.70),
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
      ],
    );
  }
}

class PremiumRefreshOverlay extends StatelessWidget {
  final bool refreshing;
  final Widget child;

  final String label;
  final Color? accentColor;
  final Color? glowColor;

  final bool blockTouches;

  final double topInset;

  const PremiumRefreshOverlay({
    super.key,
    required this.refreshing,
    required this.child,
    this.label = "Refreshing…",
    this.accentColor,
    this.glowColor,
    this.blockTouches = true,
    this.topInset = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final spinnerColor = accentColor ?? cs.primary;

    return Stack(
      children: [
        child,
        Positioned(
          top: topInset,
          left: 0,
          right: 0,
          bottom: 0,
          child: IgnorePointer(
            ignoring: !blockTouches,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder:
                  (w, anim) => FadeTransition(opacity: anim, child: w),
              child:
                  !refreshing
                      ? const SizedBox.shrink(key: ValueKey("refresh_off"))
                      : Container(
                        key: const ValueKey("refresh_on"),
                        color: cs.scrim.withOpacity(isDark ? 0.55 : 0.35),
                        alignment: Alignment.center,
                        child: PremiumFrostCard(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              PremiumSpinner(
                                size: 18,
                                strokeWidth: 2.2,
                                color: spinnerColor,
                                glowColor: glowColor,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                label,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: .2,
                                  color: cs.onSurface,
                                ),
                              ),
                            ],
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

class LuvpayLoading extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final Color? color;
  final String? label;
  final bool center;

  const LuvpayLoading({
    super.key,
    this.size = 22,
    this.strokeWidth = 2.6,
    this.color,
    this.label,
    this.center = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final c = color ?? cs.primary;
    final bg = cs.surface;

    final loader = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: cs.outlineVariant.withOpacity(isDark ? .05 : .01),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(isDark ? 0.00 : .75),
            blurRadius: 14,
            offset: const Offset(-6, -6),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? .35 : .10),
            blurRadius: 14,
            offset: const Offset(6, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: strokeWidth,
              valueColor: AlwaysStoppedAnimation(c),
            ),
          ),
          if (label != null) ...[
            const SizedBox(width: 12),
            Text(
              label!,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                letterSpacing: .15,
                color: cs.onSurface.withOpacity(.75),
              ),
            ),
          ],
        ],
      ),
    );

    return center ? Center(child: loader) : loader;
  }
}
