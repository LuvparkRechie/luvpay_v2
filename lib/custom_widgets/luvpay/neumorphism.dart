// ignore_for_file: deprecated_member_use

import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:flutter/material.dart';
import '../app_color_v2.dart';
import '../custom_text_v2.dart';

enum NeoNavIconMode { tab, icon }

class NeoNavIcon extends StatelessWidget {
  final NeoNavIconMode mode;

  final bool? active;

  final String? activeIconName;
  final String? inactiveIconName;
  final IconData? activeIconData;
  final IconData? inactiveIconData;

  final String? assetPath;
  final String? iconName;
  final IconData? iconData;
  final Color? iconColor;

  final VoidCallback onTap;

  final double size;
  final double iconSize;
  final EdgeInsets padding;
  final BorderRadius borderRadius;

  final Color? activeColor;
  final Color? inactiveColor;
  final bool flatten;

  final bool showDot;
  final int? badgeCount;
  final Alignment badgeAlignment;
  final Offset badgeOffset;
  final Color? badgeColor;
  final Color? badgeTextColor;
  final double dotSize;

  const NeoNavIcon.tab({
    super.key,
    required this.onTap,
    required this.active,
    this.activeIconName,
    this.inactiveIconName,
    this.activeIconData,
    this.inactiveIconData,
    this.size = 48,
    this.iconSize = 24,
    this.padding = const EdgeInsets.all(10),
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
    this.activeColor,
    this.inactiveColor,
    this.flatten = false,
    this.showDot = false,
    this.badgeCount,
    this.badgeAlignment = Alignment.topRight,
    this.badgeOffset = const Offset(2, -2),
    this.badgeColor,
    this.badgeTextColor,
    this.dotSize = 9,
  }) : mode = NeoNavIconMode.tab,
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
    required this.onTap,
    this.assetPath,
    this.iconName,
    this.iconData,
    this.iconColor,
    this.size = 48,
    this.iconSize = 24,
    this.padding = const EdgeInsets.all(10),
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
    this.flatten = false,
    this.showDot = false,
    this.badgeCount,
    this.badgeAlignment = Alignment.topRight,
    this.badgeOffset = const Offset(2, -2),
    this.badgeColor,
    this.badgeTextColor,
    this.dotSize = 9,
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final isTab = mode == NeoNavIconMode.tab;
    final isActive = active == true;

    final brand = AppColorV2.lpBlueBrand;

    final surface = cs.surface;
    final onSurface = cs.onSurface;
    final onSurfaceVariant = cs.onSurfaceVariant;

    final inactive =
        inactiveColor ??
        (isDark
            ? onSurface.withOpacity(0.62)
            : onSurfaceVariant.withOpacity(0.70));

    final badgeBg = badgeColor ?? AppColorV2.incorrectState;
    final badgeFg = badgeTextColor ?? Colors.white;

    final bool hasCount = (badgeCount != null && badgeCount! > 0);
    final bool showBadge = hasCount || showDot;

    Widget buildIcon() {
      if (isTab) {
        if (activeIconData != null || inactiveIconData != null) {
          final icon =
              isActive
                  ? (activeIconData ?? inactiveIconData!)
                  : (inactiveIconData ?? activeIconData!);

          return Icon(
            icon,
            size: iconSize,
            color: isActive ? (activeColor ?? brand) : inactive,
          );
        }

        final name =
            isActive
                ? (activeIconName ?? inactiveIconName!)
                : (inactiveIconName ?? activeIconName!);

        return Image.asset(
          "assets/images/$name.png",
          width: iconSize,
          height: iconSize,
          color: isActive ? (activeColor ?? brand) : inactive,
          colorBlendMode: BlendMode.srcIn,
        );
      }

      if (iconData != null) {
        return Icon(iconData!, size: iconSize, color: iconColor ?? inactive);
      }

      final path =
          assetPath ??
          (iconName != null ? "assets/images/$iconName.png" : null);

      return Image.asset(
        path!,
        width: iconSize,
        height: iconSize,
        color: iconColor,
        colorBlendMode: iconColor != null ? BlendMode.srcIn : BlendMode.dst,
      );
    }

    Widget buildBadge() {
      final borderCutColor = surface.withOpacity(isDark ? 0.95 : 0.98);

      if (hasCount) {
        final c = badgeCount!;
        final text = c > 99 ? "99+" : "$c";

        final minW = text.length <= 1 ? 16.0 : 22.0;
        final h = 16.0;

        return Container(
          constraints: BoxConstraints(minWidth: minW, minHeight: h),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: badgeBg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: borderCutColor, width: 1.4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.35 : 0.12),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: badgeFg,
                fontWeight: FontWeight.w900,
                fontSize: 10.5,
                height: 1.0,
              ),
            ),
          ),
        );
      }

      return Container(
        width: dotSize,
        height: dotSize,
        decoration: BoxDecoration(
          color: badgeBg,
          shape: BoxShape.circle,
          border: Border.all(color: borderCutColor, width: 1.4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.35 : 0.12),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
      );
    }

    return LuvNeuPress.rectangle(
      radius: borderRadius,
      onTap: onTap,
      selected: isTab && isActive,
      depth: flatten ? 0 : LuvNeu.cardDepth,
      pressedDepth: flatten ? 0 : LuvNeu.cardPressedDepth,
      background: surface,
      borderColor: flatten ? Colors.transparent : (isActive ? brand : null),
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(padding: padding, child: Center(child: buildIcon())),
            if (showBadge)
              Align(
                alignment: badgeAlignment,
                child: Transform.translate(
                  offset: badgeOffset,
                  child: buildBadge(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class InfoRowTile extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? value;
  final Widget? trailing;
  final VoidCallback? trailingOnTap;
  final VoidCallback onTap;
  final int? maxLines;
  final String? subtitle;
  final int? subtitleMaxlines;

  const InfoRowTile({
    super.key,
    this.icon,
    required this.title,
    this.value,
    this.subtitle,
    this.trailing,
    this.trailingOnTap,
    required this.onTap,
    this.maxLines,
    this.subtitleMaxlines,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(16);

    final surface = cs.surface;
    final onSurface = cs.onSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: LuvNeuPress.rectangle(
        radius: radius,
        onTap: onTap,
        borderColor: null,
        background: surface,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Neumorphic(
                  style: LuvNeu.icon(
                    radius: BorderRadius.circular(12),
                    color: surface,
                    borderColor: null,
                  ),
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: Center(
                      child: Icon(
                        icon,
                        color: onSurface.withOpacity(0.90),
                        size: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (value != null)
                      DefaultText(
                        text: value!,
                        style: AppTextStyle.body1(context),
                      ),
                    DefaultText(
                      maxLines: maxLines ?? 2,
                      text: title,
                      color: onSurface,
                      style: AppTextStyle.body1(context),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      DefaultText(
                        text: subtitle!,
                        maxLines: subtitleMaxlines ?? 1,
                        color: cs.onSurfaceVariant,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: trailingOnTap,
                  behavior: HitTestBehavior.opaque,
                  child: trailing,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class SectionListView extends StatelessWidget {
  final String sectionTitle;
  final List<Map<String, dynamic>> items;

  const SectionListView({
    super.key,
    required this.sectionTitle,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DefaultText(text: sectionTitle, style: AppTextStyle.h3(context)),
        const SizedBox(height: 8),
        ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return InfoRowTile(
              icon: item['icon'],
              title: item['title'],
              value: item['value'],
              trailing: item['trailing'],
              trailingOnTap: item['trailingOnTap'],
              onTap: item['onTap'] ?? () {},
              maxLines: item['maxLines'],
              subtitle: item['subtitle'],
              subtitleMaxlines: item['subtitleMaxlines'],
            );
          },
        ),
      ],
    );
  }
}

class DefaultContainer extends StatelessWidget {
  final Widget child;
  const DefaultContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.35 : 0.06),
            blurRadius: isDark ? 18 : 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
          width: 0.8,
        ),
      ),
      child: Stack(children: [child]),
    );
  }
}

class LuvNeu {
  static const double intensity = 0.45;
  static const double surfaceIntensity = 0.06;

  static const double cardDepth = 2.0;
  static const double cardPressedDepth = -1.0;

  static const double pillDepthFilled = 2.0;
  static const double pillDepthOutline = 1.5;
  static const double pillPressedDepth = -1.0;

  static const double iconDepth = 1.5;
  static const double iconPressedDepth = -1.0;

  static const double _borderOpacity = 0.14;
  static const double _borderWidth = 0.8;

  static NeumorphicBorder _softBorder(Color c, double width) {
    final softened = c.withOpacity(
      (c.opacity).clamp(0.0, 1.0) * _borderOpacity,
    );
    return NeumorphicBorder(color: softened, width: width.clamp(0.5, 1.0));
  }

  static NeumorphicStyle card({
    required BorderRadius radius,
    bool pressed = false,
    bool selected = false,
    Color? color,
    double depth = cardDepth,
    double pressedDepth = cardPressedDepth,
    Color? borderColor,
    double borderWidth = _borderWidth,
  }) {
    final base = color ?? AppColorV2.background;

    return NeumorphicStyle(
      color: base,
      shape: NeumorphicShape.convex,
      boxShape: NeumorphicBoxShape.roundRect(radius),
      depth: selected ? -0.5 : (pressed ? pressedDepth : depth),
      intensity: intensity,
      surfaceIntensity: surfaceIntensity,
      border:
          borderColor == null
              ? const NeumorphicBorder.none()
              : _softBorder(borderColor, borderWidth),
    );
  }

  static NeumorphicStyle circle({
    bool pressed = false,
    bool selected = false,
    Color? color,
    double depth = iconDepth,
    double pressedDepth = iconPressedDepth,
    Color? borderColor,
    double borderWidth = _borderWidth,
    NeumorphicShape shape = NeumorphicShape.convex,
  }) {
    final base = color ?? AppColorV2.background;

    return NeumorphicStyle(
      color: base,
      shape: shape,
      boxShape: const NeumorphicBoxShape.circle(),
      depth: selected ? -0.5 : (pressed ? pressedDepth : depth),
      intensity: 0.42,
      surfaceIntensity: 0.06,
      border:
          borderColor == null
              ? const NeumorphicBorder.none()
              : _softBorder(borderColor, borderWidth),
    );
  }

  static NeumorphicStyle pill({
    required BorderRadius radius,
    required bool filled,
    bool pressed = false,
    Color? filledColor,
    Color? borderColor,
    double borderWidth = _borderWidth,
  }) {
    final fill = filledColor ?? AppColorV2.lpBlueBrand;

    return NeumorphicStyle(
      color: filled ? fill : AppColorV2.background,
      shape: NeumorphicShape.convex,
      boxShape: NeumorphicBoxShape.roundRect(radius),
      depth:
          pressed
              ? pillPressedDepth
              : (filled ? pillDepthFilled : pillDepthOutline),
      intensity: 0.42,
      surfaceIntensity: 0.06,
      border:
          borderColor == null
              ? const NeumorphicBorder.none()
              : _softBorder(borderColor, borderWidth),
    );
  }

  static NeumorphicStyle icon({
    required BorderRadius radius,
    bool pressed = false,
    Color? color,
    Color? borderColor,
    double borderWidth = _borderWidth,
    NeumorphicShape shape = NeumorphicShape.convex,
  }) {
    final base = color ?? AppColorV2.background;

    return NeumorphicStyle(
      color: base,
      shape: shape,
      boxShape: NeumorphicBoxShape.roundRect(radius),
      depth: pressed ? iconPressedDepth : iconDepth,
      intensity: 0.42,
      surfaceIntensity: 0.06,
      border:
          borderColor == null
              ? const NeumorphicBorder.none()
              : _softBorder(borderColor, borderWidth),
    );
  }
}

class LuvNeuPress extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  final BorderRadius? radius;
  final NeumorphicBoxShape? boxShape;

  final double depth;
  final double pressedDepth;
  final bool selected;
  final Color? background;
  final Color? borderColor;
  final double borderWidth;

  final Duration duration;
  final Curve curve;
  final double pressedScale;
  final double pressedTranslateY;

  final double overlayOpacity;

  const LuvNeuPress({
    super.key,
    required this.child,
    this.onTap,
    this.radius,
    this.boxShape,
    this.depth = LuvNeu.cardDepth,
    this.pressedDepth = LuvNeu.cardPressedDepth,
    this.selected = false,
    this.background,
    this.borderColor,
    this.borderWidth = 0.8,
    this.duration = const Duration(milliseconds: 130),
    this.curve = Curves.easeOutCubic,
    this.pressedScale = 0.985,
    this.pressedTranslateY = 1.0,
    this.overlayOpacity = 0.035,
  }) : assert(
         radius != null || boxShape != null,
         'Provide either radius or boxShape.',
       );

  factory LuvNeuPress.rectangle({
    Key? key,
    required BorderRadius radius,
    required Widget child,
    VoidCallback? onTap,
    double depth = LuvNeu.cardDepth,
    double pressedDepth = LuvNeu.cardPressedDepth,
    bool selected = false,
    Color? background,
    Color? borderColor,
    double borderWidth = 0.8,
    Duration duration = const Duration(milliseconds: 130),
    Curve curve = Curves.easeOutCubic,
    double pressedScale = 0.985,
    double pressedTranslateY = 1.0,
    double overlayOpacity = 0.035,
  }) {
    return LuvNeuPress(
      key: key,
      child: child,
      onTap: onTap,
      radius: radius,
      depth: depth,
      pressedDepth: pressedDepth,
      selected: selected,
      background: background,
      borderColor: borderColor,
      borderWidth: borderWidth,
      duration: duration,
      curve: curve,
      pressedScale: pressedScale,
      pressedTranslateY: pressedTranslateY,
      overlayOpacity: overlayOpacity,
    );
  }

  factory LuvNeuPress.circle({
    Key? key,
    required Widget child,
    VoidCallback? onTap,
    double depth = LuvNeu.iconDepth,
    double pressedDepth = LuvNeu.iconPressedDepth,
    bool selected = false,
    Color? background,
    Color? borderColor,
    double borderWidth = 0.8,
    Duration duration = const Duration(milliseconds: 130),
    Curve curve = Curves.easeOutCubic,
    double pressedScale = 0.985,
    double pressedTranslateY = 1.0,
    double overlayOpacity = 0.035,
  }) {
    return LuvNeuPress(
      key: key,
      child: child,
      onTap: onTap,
      boxShape: const NeumorphicBoxShape.circle(),
      depth: depth,
      pressedDepth: pressedDepth,
      selected: selected,
      background: background,
      borderColor: borderColor,
      borderWidth: borderWidth,
      duration: duration,
      curve: curve,
      pressedScale: pressedScale,
      pressedTranslateY: pressedTranslateY,
      overlayOpacity: overlayOpacity,
    );
  }

  @override
  State<LuvNeuPress> createState() => _LuvNeuPressState();
}

class _LuvNeuPressState extends State<LuvNeuPress> {
  bool _pressed = false;

  void _set(bool v) {
    if (!mounted) return;
    if (_pressed == v) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final canPress = widget.onTap != null;
    final pressedVisual = canPress && _pressed;

    final scale = pressedVisual ? widget.pressedScale : 1.0;
    final dy = pressedVisual ? widget.pressedTranslateY : 0.0;

    final shape =
        widget.boxShape ??
        NeumorphicBoxShape.roundRect(
          widget.radius ?? BorderRadius.circular(16),
        );

    final isCircle = widget.boxShape == const NeumorphicBoxShape.circle();

    final style =
        isCircle
            ? LuvNeu.circle(
              pressed: pressedVisual,
              selected: widget.selected,
              depth: widget.depth,
              pressedDepth: widget.pressedDepth,
              color: widget.background,
              borderColor: widget.borderColor,
              borderWidth: widget.borderWidth,
            )
            : LuvNeu.card(
              radius: widget.radius ?? BorderRadius.circular(16),
              pressed: pressedVisual,
              selected: widget.selected,
              depth: widget.depth,
              pressedDepth: widget.pressedDepth,
              color: widget.background,
              borderColor: widget.borderColor,
              borderWidth: widget.borderWidth,
            );

    final core = Neumorphic(
      style: style.copyWith(boxShape: shape),
      child: ClipRRect(
        borderRadius:
            isCircle
                ? BorderRadius.circular(999)
                : (widget.radius ?? BorderRadius.circular(16)),
        child: Stack(
          children: [
            if (widget.overlayOpacity > 0)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(
                      widget.selected
                          ? widget.overlayOpacity + 0.02
                          : widget.overlayOpacity,
                    ),
                  ),
                ),
              ),
            widget.child,
          ],
        ),
      ),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: canPress ? (_) => _set(true) : null,
      onTapCancel: canPress ? () => _set(false) : null,
      onTapUp: canPress ? (_) => _set(false) : null,
      onTap: () {
        if (!canPress) return;
        _set(false);
        widget.onTap?.call();
      },
      child: AnimatedScale(
        scale: scale,
        duration: widget.duration,
        curve: widget.curve,
        alignment: Alignment.center,
        child: AnimatedSlide(
          duration: widget.duration,
          curve: widget.curve,
          offset: Offset(0, dy / 100),
          child: Center(child: core),
        ),
      ),
    );
  }
}

class LuvNeuIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool danger;
  final double size;
  final double iconSize;
  final Color? background;

  const LuvNeuIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.danger = false,
    this.size = 44,
    this.iconSize = 18,
    this.background,
  });

  @override
  State<LuvNeuIconButton> createState() => _LuvNeuIconButtonState();
}

class _LuvNeuIconButtonState extends State<LuvNeuIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final color =
        widget.danger ? AppColorV2.incorrectState : AppColorV2.lpBlueBrand;
    final radius = BorderRadius.circular(14);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: Neumorphic(
        style: LuvNeu.icon(
          radius: radius,
          pressed: _pressed,
          color: widget.background ?? AppColorV2.background,
          borderColor: color,
          borderWidth: 0.8,
        ),
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: Center(
            child: Icon(widget.icon, color: color, size: widget.iconSize),
          ),
        ),
      ),
    );
  }
}

class LuvNeuPillButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;
  final double height;
  final Color? filledColor;

  const LuvNeuPillButton({
    super.key,
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
    this.height = 52,
    this.filledColor,
  });

  @override
  State<LuvNeuPillButton> createState() => _LuvNeuPillButtonState();
}

class _LuvNeuPillButtonState extends State<LuvNeuPillButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);
    final fill = widget.filledColor ?? AppColorV2.lpBlueBrand;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: Neumorphic(
        style: LuvNeu.pill(
          radius: radius,
          filled: widget.filled,
          pressed: _pressed,
          filledColor: fill,
          borderColor: widget.filled ? null : fill,
          borderWidth: 0.8,
        ),
        child: SizedBox(
          height: widget.height,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.icon,
                  size: 20,
                  color:
                      widget.filled
                          ? AppColorV2.background
                          : AppColorV2.lpBlueBrand,
                ),
                const SizedBox(width: 10),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color:
                        widget.filled
                            ? AppColorV2.background
                            : AppColorV2.lpBlueBrand,
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

class CustomRowTile extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;

  final Widget? trailing;

  final VoidCallback? onTap;

  final EdgeInsets padding;
  final BorderRadius radius;

  final BorderRadius leadingRadius;
  final double leadingSize;

  final BorderRadius trailingRadius;
  final EdgeInsets trailingPadding;

  final Color? background;
  final Color? leadingBackground;

  const CustomRowTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    this.radius = const BorderRadius.all(Radius.circular(16)),
    this.leadingRadius = const BorderRadius.all(Radius.circular(12)),
    this.leadingSize = 40,
    this.trailingRadius = const BorderRadius.all(Radius.circular(14)),
    this.trailingPadding = const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 8,
    ),
    this.background,
    this.leadingBackground,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final surface = background ?? cs.surface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: LuvNeuPress.rectangle(
        radius: radius,
        onTap: onTap,
        background: surface,
        borderColor: null,
        child: Padding(
          padding: padding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (leading != null) ...[
                Neumorphic(
                  style: LuvNeu.icon(
                    radius: leadingRadius,
                    color: leadingBackground ?? surface,
                    borderColor: null,
                  ),
                  child: SizedBox(
                    width: leadingSize,
                    height: leadingSize,
                    child: Center(child: leading),
                  ),
                ),
                const SizedBox(width: 12),
              ],

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title,
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      subtitle!,
                    ],
                  ],
                ),
              ),

              if (trailing != null) ...[
                const SizedBox(width: 10),
                Neumorphic(
                  style: NeumorphicStyle(
                    color: surface,
                    shape: NeumorphicShape.flat,
                    boxShape: NeumorphicBoxShape.roundRect(trailingRadius),
                    depth: -1.0,
                    intensity: LuvNeu.intensity,
                    surfaceIntensity: LuvNeu.surfaceIntensity,
                    border: const NeumorphicBorder.none(),
                  ),
                  child: Padding(padding: trailingPadding, child: trailing),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
