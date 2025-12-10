import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:luvpay/custom_widgets/custom_button.dart';
import 'package:luvpay/custom_widgets/custom_text_v2.dart';
import 'package:luvpay/custom_widgets/custom_textfield.dart';
import 'package:luvpay/custom_widgets/luvpay/custom_scaffold.dart';

class CustomConfirmPassword<T extends GetxController> extends StatefulWidget {
  final TextEditingController passwordController;
  final Function onConfirm;
  final T controller;
  final GlobalKey<FormState> formKey;
  final bool animated;

  const CustomConfirmPassword({
    Key? key,
    required this.passwordController,
    required this.onConfirm,
    required this.controller,
    required this.formKey,
    required this.animated,
  }) : super(key: key);

  @override
  State<CustomConfirmPassword> createState() =>
      _CustomConfirmPasswordState<T>();
}

class _CustomConfirmPasswordState<T extends GetxController>
    extends State<CustomConfirmPassword<T>> {
  void visibilityChanged(bool visible) {
    setState(() {
      (widget.controller as dynamic).isShowPass.value = visible;
    });
  }

  Widget _buildForm() {
    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 20),
          SvgPicture.asset("assets/images/dialog_success.svg"),
          SizedBox(height: 14),
          DefaultText(text: "Password Required", style: AppTextStyle.h2),
          SizedBox(height: 8),
          DefaultText(
            text: "Please enter password to continue",
            style: AppTextStyle.paragraph2,
            height: 20 / 16,
          ),
          SizedBox(height: 30),
          Align(
            alignment: Alignment.centerLeft,
            child: DefaultText(text: "Password", style: AppTextStyle.h3),
          ),
          CustomTextField(
            hintText: "Enter your password",
            controller: widget.passwordController,
            isObscure: !(widget.controller as dynamic).isShowPass.value,
            suffixIcon:
                (widget.controller as dynamic).isShowPass.value
                    ? Icons.visibility
                    : Icons.visibility_off,
            onIconTap: () {
              visibilityChanged(
                !(widget.controller as dynamic).isShowPass.value,
              );
            },
            validator: (d) {
              if (d == null || d.isEmpty) {
                return "Password is required";
              }
              return null;
            },
          ),
          SizedBox(height: 30),
          CustomButton(
            text: "Continue",
            onPressed: () async {
              if (widget.formKey.currentState!.validate()) {
                widget.onConfirm();
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.animated
        ? _buildForm()
        : CustomScaffoldV2(
          enableToolBar: true,
          appBarTitle: "Confirm Password",
          scaffoldBody: _buildForm(),
        );
  }
}
