import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:luvpay/shared/widgets/luvpay_text.dart';

import '../widgets/custom_scaffold.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/neumorphism.dart';

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
          LuvpayText(text: "Password Required"),
          SizedBox(height: 8),
          LuvpayText(
            text: "Please enter password to continue",

            height: 20 / 16,
          ),
          SizedBox(height: 30),
          Align(
            alignment: Alignment.centerLeft,
            child: LuvpayText(text: "Password"),
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
