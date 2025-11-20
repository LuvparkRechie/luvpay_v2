// ignore_for_file: prefer_const_constructors

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_auto_size_text/flutter_auto_size_text.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:luvpay/custom_widgets/app_color_v2.dart';
import 'package:luvpay/custom_widgets/custom_text_v2.dart';
import 'package:luvpay/custom_widgets/spacing.dart';
import 'package:luvpay/custom_widgets/variables.dart';

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

  final numericRegex = RegExp(r'[0-9]');
  final upperCaseRegex = RegExp(r'[A-Z]');
  @override
  void initState() {
    super.initState();
    // focusNode.addListener(() {
    //   if (mounted) {
    //     setState(() {});
    //   }
    // });

    // widget.controller.addListener(() {
    //   if (mounted) {
    //     setState(() {});
    //   }
    // });
  }

  @override
  void dispose() {
    focusNode.dispose();
    // widget.controller.removeListener(() {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          widget.allowFieldPadding!
              ? EdgeInsets.only(top: 6.0)
              : EdgeInsets.zero,
      child: TextFormField(
        keyboardAppearance: Brightness.light,
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
        keyboardType: widget.keyboardType!,
        textAlign:
            widget.textAlign != null ? widget.textAlign! : TextAlign.left,
        focusNode: focusNode,
        decoration: InputDecoration(
          errorText: widget.errorText,
          filled: widget.isFilled,
          fillColor: widget.filledColor ?? Colors.transparent,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(widget.circularRadius!),
            ),
            borderSide: BorderSide(width: 2, color: AppColorV2.boxStroke),
          ),
          errorStyle: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.normal,
            fontSize: 11,
          ),
          contentPadding: EdgeInsets.only(top: 15, bottom: 12, left: 11),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(widget.circularRadius!),
            ),
            borderSide: BorderSide(width: 2, color: AppColorV2.lpBlueBrand),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(widget.circularRadius!),
            ),
            borderSide: BorderSide(width: 2, color: AppColorV2.boxStroke),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(widget.circularRadius!),
            ),
            borderSide: BorderSide(width: 2, color: AppColorV2.incorrectState),
          ),
          suffixIcon: _buildSuffixIcon(),
          prefixIcon:
              widget.prefixIcon != null
                  ? widget.isPota!
                      ? widget.prefixIcon!
                      : InkWell(
                        onTap: () {
                          widget.onIconTap!();
                        },
                        child: widget.prefixIcon,
                      )
                  : null,
          prefix: widget.prefix,
          hintMaxLines: 1,
          maintainHintSize: true,
          hintText: widget.hintText,
          hintStyle: GoogleFonts.manrope(
            color: AppColorV2.bodyTextColor,
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
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColorV2.primaryTextColor,
              letterSpacing: 0.0,
              height: 18 / 14,
            ),
        onChanged: (value) {
          if (widget.onChange != null) {
            if (mounted) {
              widget.onChange!(value);
            }
          }
        },
        onTap: () {
          if (widget.onTap != null) {
            if (mounted) {
              widget.onTap!();
            }
          }
        },
        validator: widget.validator,
      ),
    );
  }

  Widget? _buildSuffixIcon() {
    if (widget.suffixWidget != null) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: widget.suffixBgC,
          borderRadius: BorderRadius.only(
            bottomRight: Radius.circular(widget.circularRadius!),
            topRight: Radius.circular(widget.circularRadius!),
          ),
        ),
        height: 24,
        width: 60,
        child: Center(child: widget.suffixWidget),
      );
    } else if (widget.suffixIcon != null) {
      return InkWell(
        onTap: () {
          if (widget.onIconTap != null) {
            widget.onIconTap!();
          }
        },
        child: Icon(
          widget.suffixIcon!,
          color:
              focusNode.hasFocus
                  ? (widget.controller.text.isEmpty
                      ? AppColorV2.inactiveState
                      : AppColorV2.lpBlueBrand)
                  : AppColorV2.inactiveState,
        ),
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
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6.0),
      child: TextFormField(
        maxLines: 1,
        autofocus: false,
        inputFormatters: [Variables.maskFormatter],
        controller: widget.controller,
        textInputAction: widget.textInputAction ?? TextInputAction.done,
        readOnly: !widget.isEnabled || widget.isReadOnly!,
        textAlign: TextAlign.left,
        enabled: widget.isEnabled,
        keyboardType:
            Platform.isAndroid
                ? TextInputType.phone
                : TextInputType.numberWithOptions(signed: true, decimal: false),
        decoration: InputDecoration(
          errorStyle: TextStyle(color: Colors.red, fontSize: 11),
          isDense: true,

          contentPadding: const EdgeInsets.only(top: 15, bottom: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(7)),
            borderSide: BorderSide(width: 2, color: AppColorV2.boxStroke),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(7)),
            borderSide: BorderSide(width: 2, color: AppColorV2.lpBlueBrand),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(7)),
            borderSide: BorderSide(color: AppColorV2.lpBlueBrand),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(7)),
            borderSide: BorderSide(width: 2, color: AppColorV2.incorrectState),
          ),
          suffixIcon:
              widget.suffixIcon != null
                  ? InkWell(
                    onLongPress: () {},
                    onTap: () {
                      widget.onIconTap!();
                    },
                    child: Icon(widget.suffixIcon!),
                  )
                  : null,
          prefixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              spacing(height: 15),
              DefaultText(
                height: 18 / 14,
                letterSpacing: 0,
                text: '+63',
                style:
                    Platform.isAndroid
                        ? GoogleFonts.manrope(
                          color: AppColorV2.primaryTextColor,
                          fontWeight: FontWeight.w700,
                          height: 20 / 14,
                          fontSize: 14,
                        )
                        : TextStyle(
                          fontFamily: "SFProTextReg",
                          color: AppColorV2.primaryTextColor,
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
            color: AppColorV2.bodyTextColor,
            fontWeight: FontWeight.w500,
            fontSize: 14,
            height: 18 / 14,
          ),
        ),
        style: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColorV2.primaryTextColor,
          letterSpacing: 0.0,
          height: 18 / 14,
        ),
        onTap: widget.isEnabled ? widget.onTap : null,
        onChanged: (value) {
          if (widget.onChange != null) {
            widget.onChange!(value);
          }
        },
        validator:
            widget.validator ??
            (value) {
              if (widget.hintText == "10 digit mobile number") {
                if (value!.isEmpty) {
                  return 'Field is required';
                }
                if (value.toString().replaceAll(" ", "").length < 10) {
                  return 'Invalid mobile number';
                }
                if (value.toString().replaceAll(" ", "")[0] == '0') {
                  return 'Invalid mobile number';
                }
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
    return InkWell(
      onTap: () {
        widget.onTap();
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: AppColorV2.lpBlueBrand,
        ),
        child: const Padding(
          padding: EdgeInsets.all(4.0),
          child: Icon(Icons.close, size: 23, color: Colors.white),
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
}) {
  return DropdownButtonFormField<String>(
    decoration: InputDecoration(
      prefixIcon: prefixIcon,
      filled: isDisabled,
      fillColor: Colors.grey.shade200,
      contentPadding: const EdgeInsets.only(top: 15, bottom: 12, left: 11),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(width: 2, color: AppColorV2.boxStroke),
        borderRadius: BorderRadius.all(Radius.circular(7)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(7)),
        borderSide: BorderSide(width: 2, color: AppColorV2.lpBlueBrand),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(7)),
        borderSide: BorderSide(width: 2, color: AppColorV2.boxStroke),
      ),
      hintMaxLines: 1,
      maintainHintSize: true,
      hintText: labelText,
      hintStyle: GoogleFonts.manrope(
        color: AppColorV2.bodyTextColor,
        fontWeight: FontWeight.w500,
        fontSize: 14,
        height: 18 / 14,
      ),
      errorStyle: TextStyle(
        color: Colors.red,
        fontWeight: FontWeight.normal,
        fontSize: 11,
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(7)),
        borderSide: BorderSide(width: 2, color: AppColorV2.incorrectState),
      ),
    ),
    style: GoogleFonts.manrope(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: AppColorV2.primaryTextColor,
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
                color: Colors.black,
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
      color: items.isEmpty || isDisabled ? Colors.grey : Colors.black,
    ),
    dropdownColor: Colors.white,
    autovalidateMode: AutovalidateMode.onUserInteraction,
  );
}
