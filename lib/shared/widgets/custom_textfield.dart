// ignore_for_file: prefer_const_constructors

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_auto_size_text/flutter_auto_size_text.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:luvpay/shared/widgets/colors.dart';
import 'package:luvpay/shared/widgets/luvpay_text.dart';
import 'package:luvpay/shared/widgets/spacing.dart';
import 'package:luvpay/shared/widgets/variables.dart';

class CustomTextField extends StatefulWidget {
  const CustomTextField({
    super.key,
    this.title,
    this.labelText,
    this.hintText,
    required this.controller,
    this.fontweight,
    this.fontsize = 14,
    this.onChange,
    this.prefixIcon,
    this.isObscure = false,
    this.isReadOnly = false,
    this.inputFormatters,
    this.prefix = const Text(""),
    this.suffixIcon,
    this.onIconTap,
    this.maxLength,
    this.textAlign,
    this.filledColor,
    this.isFilled = false,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.textCapitalization = TextCapitalization.none,
    this.onTap,
    this.errorText,
    this.maxLines = 1,
    this.minLines = 1,
    this.isPota = false,
    this.textInputAction,
    this.style,
    this.allowFieldPadding = true,
    this.suffixWidget,
    this.suffixBgC,
    this.circularRadius = 7,
  });

  final Widget? suffixWidget;
  final TextEditingController controller;
  final String? errorText;
  final Color? filledColor;
  final double? fontsize;
  final FontWeight? fontweight;
  final String? hintText;
  final List<TextInputFormatter>? inputFormatters;
  final bool? isReadOnly;
  final bool isObscure;
  final TextInputType? keyboardType;
  final String? labelText;
  final int? maxLength;
  final bool isFilled;
  final int? maxLines;
  final int? minLines;
  final ValueChanged<String>? onChange;
  final Function? onIconTap;
  final Function? onTap;
  final Widget? prefix;
  final Widget? prefixIcon;
  final IconData? suffixIcon;
  final TextAlign? textAlign;
  final TextCapitalization textCapitalization;
  final String? title;
  final FormFieldValidator<String>? validator;
  final TextInputAction? textInputAction;
  final TextStyle? style;
  final bool? allowFieldPadding;
  final bool? isPota;
  final Color? suffixBgC;
  final double? circularRadius;

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  FocusNode focusNode = FocusNode();

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  OutlineInputBorder _border({
    required double radius,
    required Color color,
    double width = 2,
  }) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(radius)),
      borderSide: BorderSide(width: width, color: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final radius = widget.circularRadius ?? 7;

    final stroke = isDark ? AppColorV2.darkStroke : AppColorV2.boxStroke;
    final focused = AppColorV2.lpBlueBrand;
    final error = AppColorV2.incorrectState;

    final fill =
        widget.filledColor ??
        (widget.isFilled ? cs.surface : Colors.transparent);

    final hintColor = cs.onSurfaceVariant.withOpacity(isDark ? 0.75 : 0.80);
    final textColor = cs.onSurface;
    final iconInactive = cs.onSurfaceVariant.withOpacity(0.70);

    return Padding(
      padding:
          (widget.allowFieldPadding ?? true)
              ? EdgeInsets.only(top: 6.0)
              : EdgeInsets.zero,
      child: TextFormField(
        keyboardAppearance: isDark ? Brightness.dark : Brightness.light,
        minLines: widget.minLines,
        maxLines: widget.maxLines,
        maxLength: widget.maxLength,
        textCapitalization: widget.textCapitalization,
        obscureText: widget.isObscure,
        autofocus: false,
        inputFormatters: widget.inputFormatters,
        controller: widget.controller,
        textInputAction: widget.textInputAction ?? TextInputAction.done,
        readOnly: widget.isReadOnly ?? false,
        keyboardType: widget.keyboardType ?? TextInputType.text,
        textAlign: widget.textAlign ?? TextAlign.left,
        focusNode: focusNode,
        decoration: InputDecoration(
          errorText: widget.errorText,
          filled: widget.isFilled,
          fillColor: fill,
          enabledBorder: _border(radius: radius, color: stroke),
          focusedBorder: _border(radius: radius, color: focused),
          border: _border(radius: radius, color: stroke),
          errorBorder: _border(radius: radius, color: error),
          focusedErrorBorder: _border(radius: radius, color: error),
          errorStyle: TextStyle(
            color: error,
            fontWeight: FontWeight.normal,
            fontSize: 11,
          ),
          contentPadding: EdgeInsets.only(top: 15, bottom: 12, left: 11),
          suffixIcon: _buildSuffixIcon(
            context: context,
            activeColor: focused,
            inactiveColor: iconInactive,
          ),
          prefixIcon:
              widget.prefixIcon != null
                  ? (widget.isPota == true
                      ? widget.prefixIcon!
                      : InkWell(
                        onTap: () {
                          if (widget.onIconTap != null) widget.onIconTap!();
                        },
                        child: widget.prefixIcon,
                      ))
                  : null,
          prefix: widget.prefix,
          hintMaxLines: 1,
          maintainHintSize: true,
          hintText: widget.hintText,
          hintStyle: GoogleFonts.manrope(
            color: hintColor,
            fontWeight: FontWeight.w500,
            fontSize: 14,
            height: 18 / 14,
          ),
        ),
        buildCounter: (
          BuildContext context, {
          required int currentLength,
          required bool isFocused,
          required int? maxLength,
        }) {
          return null;
        },
        style:
            widget.style ??
            GoogleFonts.manrope(
              fontSize: widget.fontsize ?? 14,
              fontWeight: widget.fontweight ?? FontWeight.w500,
              color: textColor,
              letterSpacing: 0.0,
              height: 18 / 14,
            ),
        onChanged: (value) {
          if (widget.onChange != null && mounted) widget.onChange!(value);
        },
        onTap: () {
          if (widget.onTap != null && mounted) widget.onTap!();
        },
        validator: widget.validator,
      ),
    );
  }

  Widget? _buildSuffixIcon({
    required BuildContext context,
    required Color activeColor,
    required Color inactiveColor,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;

    if (widget.suffixWidget != null) {
      final bg =
          widget.suffixBgC ??
          (isDark ? cs.surfaceContainerHighest : cs.surface);

      return Container(
        padding: EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.only(
            bottomRight: Radius.circular(widget.circularRadius ?? 7),
            topRight: Radius.circular(widget.circularRadius ?? 7),
          ),
        ),
        height: 24,
        width: 60,
        child: Center(child: widget.suffixWidget),
      );
    }

    if (widget.suffixIcon != null) {
      final canHighlight =
          focusNode.hasFocus && widget.controller.text.isNotEmpty;
      final iconColor = canHighlight ? activeColor : inactiveColor;

      return InkWell(
        onTap: () {
          if (widget.onIconTap != null) widget.onIconTap!();
        },
        child: Icon(widget.suffixIcon!, color: iconColor),
      );
    }

    return null;
  }
}

class CustomMobileNumber extends StatefulWidget {
  const CustomMobileNumber({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChange,
    this.prefixIcon,
    this.isReadOnly = false,
    this.inputFormatters,
    this.prefix = const Text(""),
    this.onTap,
    this.isEnabled = true,
    this.validator,
    this.suffixIcon,
    this.onIconTap,
    this.textInputAction,
  });

  final void Function()? onTap;
  final String? Function(String?)? validator;
  final TextEditingController controller;
  final String? hintText;
  final List<TextInputFormatter>? inputFormatters;
  final bool isEnabled;
  final bool? isReadOnly;
  final ValueChanged<String>? onChange;
  final Function? onIconTap;
  final Widget? prefix;
  final Icon? prefixIcon;
  final IconData? suffixIcon;
  final TextInputAction? textInputAction;

  @override
  State<CustomMobileNumber> createState() => _CustomMobileNumberState();
}

class _CustomMobileNumberState extends State<CustomMobileNumber> {
  OutlineInputBorder _border({
    required double radius,
    required Color color,
    double width = 2,
  }) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(radius)),
      borderSide: BorderSide(width: width, color: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final stroke = isDark ? AppColorV2.darkStroke : AppColorV2.boxStroke;
    final focused = AppColorV2.lpBlueBrand;
    final error = AppColorV2.incorrectState;

    final hintColor = cs.onSurfaceVariant.withOpacity(isDark ? 0.75 : 0.80);
    final textColor = cs.onSurface;

    return Padding(
      padding: const EdgeInsets.only(top: 6.0),
      child: TextFormField(
        keyboardAppearance: isDark ? Brightness.dark : Brightness.light,
        maxLines: 1,
        autofocus: false,
        inputFormatters: widget.inputFormatters ?? [Variables.maskFormatter],
        controller: widget.controller,
        textInputAction: widget.textInputAction ?? TextInputAction.done,
        readOnly: !widget.isEnabled || (widget.isReadOnly ?? false),
        textAlign: TextAlign.left,
        enabled: widget.isEnabled,
        keyboardType:
            Platform.isAndroid
                ? TextInputType.phone
                : TextInputType.numberWithOptions(signed: true, decimal: false),
        decoration: InputDecoration(
          errorStyle: TextStyle(color: error, fontSize: 11),
          isDense: true,
          contentPadding: const EdgeInsets.only(top: 15, bottom: 12),
          enabledBorder: _border(radius: 7, color: stroke),
          focusedBorder: _border(radius: 7, color: focused),
          border: _border(radius: 7, color: focused),
          errorBorder: _border(radius: 7, color: error),
          focusedErrorBorder: _border(radius: 7, color: error),
          suffixIcon:
              widget.suffixIcon != null
                  ? InkWell(
                    onTap: () {
                      if (widget.onIconTap != null) widget.onIconTap!();
                    },
                    child: Icon(widget.suffixIcon!, color: cs.onSurfaceVariant),
                  )
                  : null,
          prefixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              spacing(height: 15),
              LuvpayText(
                height: 18 / 14,
                letterSpacing: 0,
                text: '+63',
                style:
                    Platform.isAndroid
                        ? GoogleFonts.manrope(
                          color: textColor,
                          fontWeight: FontWeight.w700,
                          height: 20 / 14,
                          fontSize: 14,
                        )
                        : TextStyle(
                          fontFamily: "SFProTextReg",
                          color: textColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
              ),
            ],
          ),
          hintMaxLines: 1,
          maintainHintSize: true,
          hintText: widget.hintText,
          hintStyle: GoogleFonts.manrope(
            color: hintColor,
            fontWeight: FontWeight.w500,
            fontSize: 14,
            height: 18 / 14,
          ),
        ),
        style: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textColor,
          letterSpacing: 0.0,
          height: 18 / 14,
        ),
        onTap: widget.isEnabled ? widget.onTap : null,
        onChanged: (value) {
          if (widget.onChange != null) widget.onChange!(value);
        },
        validator:
            widget.validator ??
            (value) {
              if (widget.hintText == "10 digit mobile number") {
                if (value == null || value.isEmpty) return 'Field is required';
                final v = value.replaceAll(" ", "");
                if (v.length < 10) return 'Invalid mobile number';
                if (v[0] == '0') return 'Invalid mobile number';
              }
              return null;
            },
      ),
    );
  }
}

class CustomButtonClose extends StatefulWidget {
  const CustomButtonClose({super.key, required this.onTap});

  final Function onTap;

  @override
  State<CustomButtonClose> createState() => _CustomButtonCloseState();
}

class _CustomButtonCloseState extends State<CustomButtonClose> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;

    final bg = isDark ? AppColorV2.lpBlueBrand : AppColorV2.lpBlueBrand;
    final fg = Colors.white;

    return InkWell(
      onTap: () => widget.onTap(),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: bg,
        ),
        child: Padding(
          padding: EdgeInsets.all(4.0),
          child: Icon(Icons.close, size: 23, color: fg),
        ),
      ),
    );
  }
}

DropdownButtonFormField<String> customDropdown({
  required bool isDisabled,
  required String labelText,
  required List items,
  required String? selectedValue,
  required ValueChanged<String?> onChanged,
  Widget? prefixIcon,
  String? Function(String?)? validator,
  BuildContext? context,
}) {
  final ctx = context ?? Get.context!;
  final theme = Theme.of(ctx);
  final cs = theme.colorScheme;
  final isDark = theme.brightness == Brightness.dark;

  final stroke = isDark ? AppColorV2.darkStroke : AppColorV2.boxStroke;
  final focused = AppColorV2.lpBlueBrand;
  final error = AppColorV2.incorrectState;

  return DropdownButtonFormField<String>(
    decoration: InputDecoration(
      prefixIcon: prefixIcon,
      filled: isDisabled,
      fillColor:
          isDisabled
              ? (isDark ? cs.surfaceContainerHighest : cs.surface)
              : null,
      contentPadding: const EdgeInsets.only(top: 15, bottom: 12, left: 11),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(width: 2, color: stroke),
        borderRadius: BorderRadius.all(Radius.circular(7)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(7)),
        borderSide: BorderSide(width: 2, color: focused),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(7)),
        borderSide: BorderSide(width: 2, color: stroke),
      ),
      hintMaxLines: 1,
      maintainHintSize: true,
      hintText: labelText,
      hintStyle: GoogleFonts.manrope(
        color: cs.onSurfaceVariant.withOpacity(isDark ? 0.75 : 0.80),
        fontWeight: FontWeight.w500,
        fontSize: 14,
        height: 18 / 14,
      ),
      errorStyle: TextStyle(
        color: error,
        fontWeight: FontWeight.normal,
        fontSize: 11,
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(7)),
        borderSide: BorderSide(width: 2, color: error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(7)),
        borderSide: BorderSide(width: 2, color: error),
      ),
    ),
    style: GoogleFonts.manrope(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: cs.onSurface,
      letterSpacing: 0.0,
      height: 18 / 14,
    ),
    items:
        items.map((item) {
          return DropdownMenuItem(
            value: item['value'].toString(),
            child: AutoSizeText(
              item['text'].toString(),
              style: TextStyle(
                color: cs.onSurface,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxFontSize: 16,
              maxLines: 2,
            ),
          );
        }).toList(),
    value: selectedValue,
    onChanged: isDisabled ? null : onChanged,
    validator: validator,
    isExpanded: true,
    focusNode: FocusNode(),
    icon: Icon(
      Icons.arrow_drop_down,
      color:
          (items.isEmpty || isDisabled)
              ? cs.onSurfaceVariant.withOpacity(0.5)
              : cs.onSurfaceVariant,
    ),
    dropdownColor: cs.surface,
    autovalidateMode: AutovalidateMode.onUserInteraction,
  );
}
