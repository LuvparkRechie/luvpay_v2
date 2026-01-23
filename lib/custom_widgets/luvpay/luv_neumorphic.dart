import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import '../app_color_v2.dart';

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

  factory LuvNeuPress.rect({
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
        borderRadius: widget.radius ?? BorderRadius.circular(999),
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
      child: AnimatedContainer(
        duration: widget.duration,
        curve: widget.curve,
        transform:
            Matrix4.identity()
              ..translate(0.0, dy)
              ..scale(scale, scale),
        child: core,
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
