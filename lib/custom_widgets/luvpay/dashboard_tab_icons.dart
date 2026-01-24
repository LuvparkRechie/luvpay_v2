import 'dart:ui';
import 'package:flutter/material.dart';
import '../app_color_v2.dart';

enum NeoNavIconMode { tab, icon }

class NeoNavIcon extends StatefulWidget {
  final NeoNavIconMode mode;

  final double? buttonSize;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;

  final bool? flatten;

  final String? activeIconName;
  final String? inactiveIconName;
  final IconData? activeIconData;
  final IconData? inactiveIconData;
  final bool? active;

  final String? assetPath;
  final String? iconName;
  final IconData? iconData;
  final Color? iconColor;

  final VoidCallback onTap;
  final double? width;
  final double? height;
  final double? iconSize;

  final Color? activeColor;
  final Color? inactiveColor;

  const NeoNavIcon.tab({
    super.key,
    this.activeIconName,
    this.inactiveIconName,
    this.activeIconData,
    this.inactiveIconData,
    required bool active,
    required this.onTap,
    this.width,
    this.height,
    this.iconSize,
    this.activeColor,
    this.inactiveColor,
    this.buttonSize,
    this.padding,
    this.borderRadius,
    this.flatten,
  }) : mode = NeoNavIconMode.tab,
       active = active,
       assetPath = null,
       iconName = null,
       iconData = null,
       iconColor = null,
       assert(
         (activeIconName != null || inactiveIconName != null) ||
             (activeIconData != null || inactiveIconData != null),
       );

  const NeoNavIcon.icon({
    super.key,
    this.assetPath,
    this.iconName,
    this.iconData,
    this.iconColor,
    required this.onTap,
    this.width,
    this.height,
    this.iconSize,
    this.buttonSize,
    this.padding,
    this.borderRadius,
    this.flatten,
  }) : mode = NeoNavIconMode.icon,
       active = null,
       activeIconName = null,
       inactiveIconName = null,
       activeIconData = null,
       inactiveIconData = null,
       activeColor = null,
       inactiveColor = null,
       assert(assetPath != null || iconName != null || iconData != null);

  @override
  State<NeoNavIcon> createState() => _NeoNavIconState();
}

class _NeoNavIconState extends State<NeoNavIcon> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final base = AppColorV2.background;
    final brand = AppColorV2.lpBlueBrand;
    final r = widget.borderRadius ?? BorderRadius.circular(18);

    final isTab = widget.mode == NeoNavIconMode.tab;
    final isActive = widget.active ?? false;

    final iconW = widget.width ?? 24;
    final iconH = widget.height ?? 24;

    final activeIconColor = widget.activeColor ?? brand;
    final inactiveIconColor =
        widget.inactiveColor ?? Colors.black.withValues(alpha: 0.55);

    final iconPadding =
        widget.padding ??
        const EdgeInsets.symmetric(horizontal: 12, vertical: 12);

    final bool flatten = widget.flatten == true;

    final inactiveShadows = [
      BoxShadow(
        color: Colors.white.withValues(alpha: 0.60),
        blurRadius: 8,
        offset: const Offset(-4, -4),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.06),
        blurRadius: 9,
        offset: const Offset(4, 4),
      ),
    ];

    final activeShadows = [
      BoxShadow(
        color: Colors.white.withValues(alpha: 0.60),
        blurRadius: 6,
        offset: const Offset(-3, -3),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.07),
        blurRadius: 6,
        offset: const Offset(3, 3),
      ),
    ];

    BoxShadow lerpShadow(BoxShadow a, BoxShadow b, double t) {
      return BoxShadow(
        color: Color.lerp(a.color, b.color, t) ?? b.color,
        blurRadius: lerpDouble(a.blurRadius, b.blurRadius, t) ?? b.blurRadius,
        spreadRadius:
            lerpDouble(a.spreadRadius, b.spreadRadius, t) ?? b.spreadRadius,
        offset: Offset(
          lerpDouble(a.offset.dx, b.offset.dx, t) ?? b.offset.dx,
          lerpDouble(a.offset.dy, b.offset.dy, t) ?? b.offset.dy,
        ),
      );
    }

    Widget buildIcon() {
      if (isTab) {
        final useIconData =
            (widget.activeIconData != null || widget.inactiveIconData != null);

        if (useIconData) {
          final icon =
              isActive
                  ? (widget.activeIconData ?? widget.inactiveIconData!)
                  : (widget.inactiveIconData ?? widget.activeIconData!);

          return Icon(
            icon,
            size: widget.iconSize ?? (iconW > iconH ? iconW : iconH),
            color: isActive ? activeIconColor : inactiveIconColor,
          );
        }

        final iconName =
            isActive
                ? (widget.activeIconName ?? widget.inactiveIconName!)
                : (widget.inactiveIconName ?? widget.activeIconName!);

        return Image.asset(
          "assets/images/$iconName.png",
          width: iconW,
          height: iconH,
          fit: BoxFit.contain,
          gaplessPlayback: true,
          color: isActive ? activeIconColor : inactiveIconColor,
          colorBlendMode: BlendMode.srcIn,
        );
      }

      if (widget.iconData != null) {
        return Icon(
          widget.iconData!,
          size: widget.iconSize ?? (iconW > iconH ? iconW : iconH),
          color: widget.iconColor ?? inactiveIconColor,
        );
      }

      final path =
          widget.assetPath ??
          (widget.iconName != null
              ? "assets/images/${widget.iconName}.png"
              : null);

      return Image.asset(
        path!,
        width: iconW,
        height: iconH,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        color: widget.iconColor,
        colorBlendMode:
            widget.iconColor != null ? BlendMode.srcIn : BlendMode.dst,
      );
    }

    final double t = isTab && isActive ? 1.0 : 0.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(end: t),
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          builder: (context, tt, _) {
            final borderColor =
                Color.lerp(
                  Colors.black.withValues(alpha: 0.010),
                  brand.withValues(alpha: 0.08),
                  tt,
                ) ??
                brand.withValues(alpha: 0.08);

            final shadows =
                flatten
                    ? const <BoxShadow>[]
                    : [
                      lerpShadow(inactiveShadows[0], activeShadows[0], tt),
                      lerpShadow(inactiveShadows[1], activeShadows[1], tt),
                    ];

            final size = widget.buttonSize;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: base,
                borderRadius: r,
                border: Border.all(
                  color: flatten ? Colors.transparent : borderColor,
                ),
                boxShadow: shadows,
              ),
              child: Padding(
                padding: iconPadding,
                child: Center(child: buildIcon()),
              ),
            );
          },
        ),
      ),
    );
  }
}
