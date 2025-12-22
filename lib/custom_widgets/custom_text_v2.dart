import 'package:flutter/material.dart';
import 'package:flutter_auto_size_text/flutter_auto_size_text.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:luvpay/custom_widgets/app_color_v2.dart';
import 'package:shimmer/shimmer.dart';

class AppTextStyle {
  /// 28
  /// 800
  /// primaryTextColor
  static TextStyle h1 = GoogleFonts.manrope(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    height: 32 / 28,
    color: AppColorV2.primaryTextColor, //0x132C4E
  );

  /// 26
  /// 800
  /// primaryTextColor
  static TextStyle h2_f26 = GoogleFonts.manrope(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    height: 32 / 26,
    color: AppColorV2.primaryTextColor, //0x132C4E
  );

  /// 24
  /// 800
  /// primaryTextColor
  static TextStyle h2 = GoogleFonts.manrope(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    height: 28 / 24,
    color: AppColorV2.primaryTextColor, //0x132C4E
  );

  /// 22
  /// 700
  /// primaryTextColor
  static TextStyle h3_f22 = GoogleFonts.manrope(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 26 / 22,
    color: AppColorV2.primaryTextColor, //0x132C4E
  );

  /// 16
  /// 700
  /// primaryTextColor
  static TextStyle h3 = GoogleFonts.manrope(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 20 / 16,
    color: AppColorV2.primaryTextColor, //0x132C4E
  );

  /// 16
  /// 600
  /// primaryTextColor
  static TextStyle h3_semibold = GoogleFonts.manrope(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 20 / 16,
    color: AppColorV2.primaryTextColor, //0x132C4E
  );

  /// 18
  /// 700
  /// primaryTextColor
  static TextStyle h4 = GoogleFonts.manrope(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 28 / 18,
    color: AppColorV2.primaryTextColor, //0x132C4E
  );

  /// 16
  /// 500
  /// bodyTextColor
  static TextStyle paragraph1 = GoogleFonts.manrope(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 20 / 16,
    color: AppColorV2.bodyTextColor, //0x6B7D91
  );

  /// 14
  /// 500
  /// bodyTextColor
  static TextStyle paragraph2 = GoogleFonts.manrope(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 18 / 14,
    color: AppColorV2.bodyTextColor, //0x6B7D91
  );

  /// 12
  /// 700
  /// bodyTextColor
  static TextStyle body2 = GoogleFonts.manrope(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    height: 18 / 14,
    color: AppColorV2.bodyTextColor, //0x6B7D91
  );

  /// 14
  /// 600
  /// bodyTextColor
  static TextStyle body1 = GoogleFonts.manrope(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 18 / 14,
    color: AppColorV2.bodyTextColor, //0x6B7D91
  );

  /// 14
  /// 500
  /// bodyTextColor
  static TextStyle textbox = GoogleFonts.manrope(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 18 / 14,
    color: AppColorV2.bodyTextColor, //0x6B7D91
  );

  /// 16
  /// 500
  /// background
  static TextStyle textButton = GoogleFonts.manrope(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 20 / 16,
    color: AppColorV2.background, //0xFF0078FF
  );

  /// 22
  /// 800
  /// primaryTextColor
  static TextStyle popup = GoogleFonts.manrope(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    height: 24 / 22,
    color: AppColorV2.primaryTextColor,
  );
}

class DefaultText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? color;
  final double? letterSpacing; //default is 0
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

  /// Creates a DefaultText luvpay widget to display text with customizable styling.
  ///
  /// The default text style is [AppTextStyle.paragraph2].
  ///
  /// The parameters allow overriding the style, font size, weight, color, letter spacing, etc.
  ///
  /// [AppTextStyle.h3] is default for title.
  ///
  /// Example:
  /// ```dart
  /// DefaultText(
  ///  fontSize: 14,
  /// fontWeight: FontWeight.w500,
  /// color: AppColorV2.bodyTextColor, //0x6B7D91/grey
  /// )
  /// ```

  const DefaultText({
    super.key,
    required this.text,
    this.style,
    this.fontSize,
    this.fontWeight,
    this.color,
    this.letterSpacing, //default is 0
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
    final defaultStyle = widget.style ?? AppTextStyle.paragraph2;
    final textStyleValue = defaultStyle.copyWith(
      fontSize: widget.fontSize ?? defaultStyle.fontSize,
      fontWeight: widget.fontWeight ?? defaultStyle.fontWeight,
      color: widget.color ?? defaultStyle.color,
      letterSpacing: widget.letterSpacing ?? 0,
      fontStyle: widget.fontStyle ?? defaultStyle.fontStyle,
      height: widget.height,
      wordSpacing: widget.wordSpacing ?? defaultStyle.wordSpacing,
    );

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: (widget.horizontalPadding ?? 0) / 2,
        vertical: (widget.verticalPadding ?? 0 / 2),
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
    return Shimmer(
      gradient: LinearGradient(
        colors: [AppColorV2.lpBlueBrand.withAlpha(80), Colors.grey[100]!],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColorV2.inactiveButton,
          borderRadius: BorderRadius.circular(5),
        ),
        width: widget.width ?? 100,
        height: 14,
      ),
    );
  }
}
