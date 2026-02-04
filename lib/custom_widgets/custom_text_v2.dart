import 'package:flutter/material.dart';
import 'package:flutter_auto_size_text/flutter_auto_size_text.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import 'package:luvpay/custom_widgets/app_color_v2.dart';

class AppTextStyle {
  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color _primaryText(BuildContext context) =>
      _isDark(context)
          ? AppColorV2.darkPrimaryText
          : AppColorV2.primaryTextColor;

  static Color _bodyText(BuildContext context) =>
      _isDark(context) ? AppColorV2.darkBodyText : AppColorV2.bodyTextColor;

  static Color _onBrand(BuildContext context) =>
      _isDark(context) ? AppColorV2.darkBackground : AppColorV2.background;

  static TextStyle h1(BuildContext context) => GoogleFonts.manrope(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    height: 32 / 28,
    color: _primaryText(context),
  );

  static TextStyle h2_f26(BuildContext context) => GoogleFonts.manrope(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    height: 32 / 26,
    color: _primaryText(context),
  );

  static TextStyle h2(BuildContext context) => GoogleFonts.manrope(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    height: 28 / 24,
    color: _primaryText(context),
  );

  static TextStyle h3_f22(BuildContext context) => GoogleFonts.manrope(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 26 / 22,
    color: _primaryText(context),
  );

  static TextStyle h3(BuildContext context) => GoogleFonts.manrope(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 20 / 16,
    color: _primaryText(context),
  );

  static TextStyle h3_semibold(BuildContext context) => GoogleFonts.manrope(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 20 / 16,
    color: _primaryText(context),
  );

  static TextStyle h4(BuildContext context) => GoogleFonts.manrope(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 28 / 18,
    color: _primaryText(context),
  );

  static TextStyle paragraph1(BuildContext context) => GoogleFonts.manrope(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 20 / 16,
    color: _bodyText(context),
  );

  static TextStyle paragraph2(BuildContext context) => GoogleFonts.manrope(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 18 / 14,
    color: _bodyText(context),
  );

  static TextStyle body2(BuildContext context) => GoogleFonts.manrope(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    height: 18 / 14,
    color: _bodyText(context),
  );

  static TextStyle body1(BuildContext context) => GoogleFonts.manrope(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 18 / 14,
    color: _bodyText(context),
  );

  static TextStyle textbox(BuildContext context) => GoogleFonts.manrope(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 18 / 14,
    color: _bodyText(context),
  );

  static TextStyle textButton(BuildContext context) => GoogleFonts.manrope(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 20 / 16,
    color: _onBrand(context),
  );

  static TextStyle popup(BuildContext context) => GoogleFonts.manrope(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    height: 24 / 22,
    color: _primaryText(context),
  );
}

class DefaultText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? color;
  final double? letterSpacing;
  final FontStyle? fontStyle;
  final double? height;
  final double? wordSpacing;
  final int? maxLines;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final double? minFontSize;
  final double? maxFontSize;
  final double? verticalPadding;
  final double? horizontalPadding;

  const DefaultText({
    super.key,
    required this.text,
    this.style,
    this.fontSize,
    this.fontWeight,
    this.color,
    this.letterSpacing,
    this.fontStyle,
    this.height,
    this.wordSpacing,
    this.maxLines,
    this.textAlign,
    this.overflow,
    this.minFontSize,
    this.maxFontSize,
    this.verticalPadding,
    this.horizontalPadding,
  });

  @override
  State<DefaultText> createState() => _DefaultTextState();
}

class _DefaultTextState extends State<DefaultText> {
  @override
  Widget build(BuildContext context) {
    final defaultStyle = widget.style ?? AppTextStyle.paragraph2(context);

    final textStyleValue = defaultStyle.copyWith(
      fontSize: widget.fontSize ?? defaultStyle.fontSize,
      fontWeight: widget.fontWeight ?? defaultStyle.fontWeight,
      color: widget.color ?? defaultStyle.color,
      letterSpacing: widget.letterSpacing ?? 0,
      fontStyle: widget.fontStyle ?? defaultStyle.fontStyle,
      height: widget.height ?? defaultStyle.height,
      wordSpacing: widget.wordSpacing ?? defaultStyle.wordSpacing,
    );

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: (widget.horizontalPadding ?? 0) / 2,
        vertical: (widget.verticalPadding ?? 0) / 2,
      ),
      child: AutoSizeText(
        widget.text,
        softWrap: true,
        style: textStyleValue,
        textAlign: widget.textAlign ?? TextAlign.left,
        maxLines: widget.maxLines ?? 2,
        overflow: widget.overflow ?? TextOverflow.ellipsis,
        minFontSize: widget.minFontSize ?? 12,
        maxFontSize: widget.maxFontSize ?? 28,
      ),
    );
  }
}

class IsLoading extends StatefulWidget {
  final double? width;
  const IsLoading({super.key, this.width});

  @override
  State<IsLoading> createState() => _IsLoadingState();
}

class _IsLoadingState extends State<IsLoading> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer(
      gradient: LinearGradient(
        colors: [
          AppColorV2.lpBlueBrand.withOpacity(isDark ? 0.25 : 0.35),
          (isDark ? AppColorV2.darkSurface2 : Colors.grey[100]!).withOpacity(
            isDark ? 0.65 : 1.0,
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColorV2.darkSurface2 : AppColorV2.inactiveButton,
          borderRadius: BorderRadius.circular(5),
        ),
        width: widget.width ?? 100,
        height: 14,
      ),
    );
  }
}
