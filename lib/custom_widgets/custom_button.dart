import 'package:flutter/material.dart';
import 'package:flutter_auto_size_text/flutter_auto_size_text.dart'
    show AutoSizeText;
import 'package:google_fonts/google_fonts.dart';
import 'package:luvpay/custom_widgets/app_color_v2.dart';
import 'package:luvpay/custom_widgets/custom_text_v2.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final Function onPressed;
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

  //custombutton

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap:
          isInactive
              ? () {}
              : () {
                onPressed();
              },
      child: Container(
        margin: margin,
        height: btnHeight,
        width: width ?? MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          color:
              isInactive
                  ? AppColorV2.inactiveButton
                  : btnColor ?? AppColorV2.lpBlueBrand,
          border: Border.all(
            width: 2,
            color: bordercolor ?? Colors.transparent,
          ),
          borderRadius: BorderRadius.circular(borderRadius!),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: verticalPadding ?? 12),
          child: Center(
            child:
                loading == null
                    ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (leading != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 10.0),
                            child: leading!,
                          ),
                        Flexible(
                          child: DefaultText(
                            maxLines: maxLines ?? 1,
                            text: text,
                            textAlign: TextAlign.center,
                            color: textColor ?? AppColorV2.background,
                            fontSize: fontSize,
                            style: AppTextStyle.textButton,
                            fontWeight: fontWeight ?? FontWeight.w600,
                            height: 20 / 16,
                          ),
                        ),
                        if (trailing != null) trailing!,
                      ],
                    )
                    : loading!
                    ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: AppColorV2.background,
                        strokeWidth: 2,
                      ),
                    )
                    : DefaultText(
                      minFontSize: 8,
                      maxLines: maxLines ?? 1,
                      text: text,
                      textAlign: TextAlign.center,
                      color: textColor ?? AppColorV2.background,
                      fontSize: fontSize,
                      style: AppTextStyle.textButton,
                      fontWeight: FontWeight.w600,
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
  final Function onPressed;
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
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        widget.onPressed();
      },
      child: Container(
        decoration: BoxDecoration(
          color: widget.color!,
          borderRadius: BorderRadius.circular(7),
          border:
              widget.borderColor == null
                  ? null
                  : Border.all(color: widget.borderColor!),
        ),
        clipBehavior: Clip.antiAlias,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: AutoSizeText(
              widget.text,
              style: GoogleFonts.lato(
                color: widget.textColor!,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class CustomDialogButton extends StatelessWidget {
  final String text;
  final Color? borderColor;
  final Color? btnColor;
  final Color? txtColor;
  final Function onTap;
  const CustomDialogButton({
    super.key,
    required this.text,
    this.borderColor,
    this.btnColor,
    this.txtColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        decoration: ShapeDecoration(
          color: btnColor ?? Color(0xFFF9FBFC),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(74),
          ),
        ),
        child: DefaultText(
          text: text,
          color: txtColor ?? Color(0xFF0078FF),
          fontSize: 14,
          letterSpacing: 0.50,
          textAlign: TextAlign.center,
          fontWeight: FontWeight.w500,
          minFontSize: 8,
        ),
      ),
    );
  }
}

class CustomElevatedButton extends StatelessWidget {
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
    Key? key,
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
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: btnHeight ?? 50.0,
      width: btnwidth,
      child: ElevatedButton(
        onPressed: (loading || disabled) ? null : onPressed,
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all<Color>(
            disabled ? Colors.grey : btnColor ?? Colors.blue,
          ),
          foregroundColor: WidgetStateProperty.all<Color>(
            textColor ?? Colors.white,
          ),
          shape: WidgetStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(7), // Adjust radius
            ),
          ),
        ),
        child:
            loading
                ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(
                        icon,
                        size: iconSize,
                        color: iconColor ?? textColor ?? Colors.white,
                      ),
                      SizedBox(width: spacing),
                    ],
                    DefaultText(
                      text: text,
                      fontSize: fontSize,
                      color: textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ],
                ),
      ),
    );
  }
}
