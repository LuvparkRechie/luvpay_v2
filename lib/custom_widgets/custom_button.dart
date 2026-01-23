// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_auto_size_text/flutter_auto_size_text.dart'
    show AutoSizeText;
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:luvpay/custom_widgets/app_color_v2.dart';
import 'package:luvpay/custom_widgets/custom_text_v2.dart';

class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;

  final Color? btnColor;
  final bool? loading;
  final Color? bordercolor;
  final Color? textColor;
  final double? borderRadius;
  final double? btnHeight;
  final double? fontSize;
  final int? maxLines;
  final Widget? leading;
  final Widget? trailing;
  final bool isInactive;
  final double? verticalPadding;
  final FontWeight? fontWeight;
  final EdgeInsetsGeometry? margin;
  final double? width;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.fontSize,
    this.btnColor,
    this.bordercolor,
    this.textColor,
    this.loading,
    this.borderRadius = 30,
    this.btnHeight,
    this.maxLines,
    this.leading,
    this.isInactive = false,
    this.verticalPadding,
    this.fontWeight,
    this.margin,
    this.width,
    this.trailing,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (!mounted) return;
    if (_pressed == v) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.borderRadius ?? 30);
    final isDisabled = widget.isInactive == true;

    final bg =
        isDisabled
            ? AppColorV2.inactiveButton
            : (widget.btnColor ?? AppColorV2.lpBlueBrand);

    final fg =
        widget.textColor ??
        (isDisabled ? Colors.black.withAlpha(120) : AppColorV2.background);

    final showLoading = (widget.loading ?? false);

    final canPress = !isDisabled && !showLoading;
    final pressedVisual = canPress && _pressed;

    final scale = pressedVisual ? 0.985 : 1.0;
    final dy = pressedVisual ? 1.0 : 0.0;
    final borderCol = (widget.bordercolor ?? Colors.transparent);
    final effectiveBorder =
        borderCol == Colors.transparent ? null : borderCol.withOpacity(0.22);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: canPress ? (_) => _setPressed(true) : null,
      onTapUp: canPress ? (_) => _setPressed(false) : null,
      onTapCancel: canPress ? () => _setPressed(false) : null,
      onTap: canPress ? widget.onPressed : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutCubic,
        transform:
            Matrix4.identity()
              ..translate(0.0, dy)
              ..scale(scale, scale),
        child: Container(
          margin: widget.margin,
          width: widget.width ?? MediaQuery.of(context).size.width,
          height: widget.btnHeight,
          child: Neumorphic(
            style: NeumorphicStyle(
              color: bg,
              shape: NeumorphicShape.flat,
              boxShape: NeumorphicBoxShape.roundRect(radius),
              depth: isDisabled ? 0 : (pressedVisual ? -1.0 : 1.6),
              intensity: 0.45,
              surfaceIntensity: 0.08,
              border:
                  effectiveBorder == null
                      ? const NeumorphicBorder.none()
                      : NeumorphicBorder(color: effectiveBorder, width: 1),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: widget.verticalPadding ?? 12,
              ),
              child: Center(
                child:
                    showLoading
                        ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: fg,
                            strokeWidth: 2,
                          ),
                        )
                        : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.leading != null) ...[
                              Padding(
                                padding: const EdgeInsets.only(right: 10.0),
                                child: widget.leading!,
                              ),
                            ],
                            Flexible(
                              child: DefaultText(
                                maxLines: widget.maxLines ?? 1,
                                text: widget.text,
                                textAlign: TextAlign.center,
                                color: fg,
                                fontSize: widget.fontSize,
                                style: AppTextStyle.textButton,
                                fontWeight:
                                    widget.fontWeight ?? FontWeight.w700,
                                height: 20 / 16,
                              ),
                            ),
                            if (widget.trailing != null) ...[
                              const SizedBox(width: 10),
                              widget.trailing!,
                            ],
                          ],
                        ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CustomButtonCancel extends StatefulWidget {
  final String text;
  final Color? color;
  final Color? textColor;
  final Color? borderColor;
  final VoidCallback onPressed;

  const CustomButtonCancel({
    super.key,
    required this.text,
    required this.onPressed,
    this.borderColor,
    this.color,
    this.textColor,
  });

  @override
  State<CustomButtonCancel> createState() => _CustomButtonCancelState();
}

class _CustomButtonCancelState extends State<CustomButtonCancel> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(14);

    final bg = widget.color ?? AppColorV2.background;
    final fg = widget.textColor ?? AppColorV2.lpBlueBrand;

    final borderCol = widget.borderColor;
    final effectiveBorder =
        borderCol == null ? null : borderCol.withOpacity(0.20);

    final pressedVisual = _pressed;
    final scale = pressedVisual ? 0.988 : 1.0;
    final dy = pressedVisual ? 1.0 : 0.0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutCubic,
        transform:
            Matrix4.identity()
              ..translate(0.0, dy)
              ..scale(scale, scale),
        child: Neumorphic(
          style: NeumorphicStyle(
            color: bg,
            shape: NeumorphicShape.flat,
            boxShape: NeumorphicBoxShape.roundRect(radius),
            depth: pressedVisual ? -1.0 : 1.4,
            intensity: 0.42,
            surfaceIntensity: 0.07,
            border:
                effectiveBorder == null
                    ? const NeumorphicBorder.none()
                    : NeumorphicBorder(color: effectiveBorder, width: 1),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: AutoSizeText(
                widget.text,
                style: GoogleFonts.lato(
                  color: fg,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CustomDialogButton extends StatefulWidget {
  final String text;
  final Color? borderColor;
  final Color? btnColor;
  final Color? txtColor;
  final VoidCallback onTap;

  const CustomDialogButton({
    super.key,
    required this.text,
    this.borderColor,
    this.btnColor,
    this.txtColor,
    required this.onTap,
  });

  @override
  State<CustomDialogButton> createState() => _CustomDialogButtonState();
}

class _CustomDialogButtonState extends State<CustomDialogButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(74);
    final bg = widget.btnColor ?? const Color(0xFFF9FBFC);
    final fg = widget.txtColor ?? const Color(0xFF0078FF);

    final borderCol = widget.borderColor;
    final effectiveBorder =
        borderCol == null ? null : borderCol.withOpacity(0.20);

    final pressedVisual = _pressed;
    final scale = pressedVisual ? 0.988 : 1.0;
    final dy = pressedVisual ? 1.0 : 0.0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutCubic,
        transform:
            Matrix4.identity()
              ..translate(0.0, dy)
              ..scale(scale, scale),
        child: Neumorphic(
          style: NeumorphicStyle(
            color: bg,
            shape: NeumorphicShape.flat,
            boxShape: NeumorphicBoxShape.roundRect(radius),
            depth: pressedVisual ? -1.0 : 1.2,
            intensity: 0.42,
            surfaceIntensity: 0.07,
            border:
                effectiveBorder == null
                    ? const NeumorphicBorder.none()
                    : NeumorphicBorder(color: effectiveBorder, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
            child: DefaultText(
              text: widget.text,
              color: fg,
              fontSize: 14,
              letterSpacing: 0.50,
              textAlign: TextAlign.center,
              fontWeight: FontWeight.w700,
              minFontSize: 8,
            ),
          ),
        ),
      ),
    );
  }
}

class CustomElevatedButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? btnColor;
  final bool loading;
  final bool disabled;
  final Color? textColor;
  final double borderRadius;
  final double fontSize;
  final double? btnHeight;
  final Color? borderColor;
  final IconData? icon;
  final double iconSize;
  final Color? iconColor;
  final double spacing;
  final double? btnwidth;

  const CustomElevatedButton({
    super.key,
    required this.text,
    this.onPressed,
    this.btnColor,
    this.textColor,
    this.loading = false,
    this.disabled = false,
    this.borderRadius = 7.0,
    this.fontSize = 14.0,
    this.btnHeight,
    this.borderColor,
    this.icon,
    this.iconSize = 20.0,
    this.iconColor,
    this.spacing = 8.0,
    this.btnwidth,
  });

  @override
  State<CustomElevatedButton> createState() => _CustomElevatedButtonState();
}

class _CustomElevatedButtonState extends State<CustomElevatedButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.borderRadius);
    final bg =
        widget.disabled
            ? Colors.grey
            : (widget.btnColor ?? AppColorV2.lpBlueBrand);
    final fg = widget.textColor ?? AppColorV2.background;

    final borderCol = widget.borderColor;
    final effectiveBorder =
        borderCol == null ? null : borderCol.withOpacity(0.20);

    final canPress =
        !(widget.loading || widget.disabled) && widget.onPressed != null;
    final pressedVisual = canPress && _pressed;

    final scale = pressedVisual ? 0.985 : 1.0;
    final dy = pressedVisual ? 1.0 : 0.0;

    return GestureDetector(
      onTapDown: canPress ? (_) => setState(() => _pressed = true) : null,
      onTapUp: canPress ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: canPress ? () => setState(() => _pressed = false) : null,
      onTap: canPress ? widget.onPressed : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutCubic,
        transform:
            Matrix4.identity()
              ..translate(0.0, dy)
              ..scale(scale, scale),
        child: SizedBox(
          height: widget.btnHeight ?? 50.0,
          width: widget.btnwidth,
          child: Neumorphic(
            style: NeumorphicStyle(
              color: bg,
              shape: NeumorphicShape.flat,
              boxShape: NeumorphicBoxShape.roundRect(radius),
              depth: widget.disabled ? 0 : (pressedVisual ? -1.0 : 1.6),
              intensity: 0.45,
              surfaceIntensity: 0.08,
              border:
                  effectiveBorder == null
                      ? const NeumorphicBorder.none()
                      : NeumorphicBorder(color: effectiveBorder, width: 1),
            ),
            child: Center(
              child:
                  widget.loading
                      ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: fg,
                          strokeWidth: 2,
                        ),
                      )
                      : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(
                              widget.icon,
                              size: widget.iconSize,
                              color: widget.iconColor ?? fg,
                            ),
                            SizedBox(width: widget.spacing),
                          ],
                          DefaultText(
                            text: widget.text,
                            fontSize: widget.fontSize,
                            color: fg,
                            fontWeight: FontWeight.w700,
                          ),
                        ],
                      ),
            ),
          ),
        ),
      ),
    );
  }
}
