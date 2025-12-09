import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';

import '../../custom_widgets/custom_button.dart';
import '../../custom_widgets/luvpay/custom_scaffold.dart';
import '../../custom_widgets/custom_text_v2.dart';
import '../../custom_widgets/custom_textfield.dart';
import '../../custom_widgets/spacing.dart';
import '../../custom_widgets/variables.dart';
import '../../custom_widgets/vertical_height.dart';
import 'controller.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  _ForgotPasswordState createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final ForgotPasswordController controller = Get.put(
    ForgotPasswordController(),
  );

  @override
  Widget build(BuildContext context) {
    return CustomScaffoldV2(
      enableToolBar: true,
      scaffoldBody: StretchingOverscrollIndicator(
        axisDirection: AxisDirection.down,
        child: SingleChildScrollView(
          child: Form(
            key: controller.formKeyForgotPass,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                spacing(height: 28),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      "assets/images/reset_password2.svg",
                      height: 86,
                    ),
                    spacing(height: 10),
                    DefaultText(
                      horizontalPadding: 77,
                      text: "Recover Account",
                      style: AppTextStyle.h2,
                      maxLines: 1,
                      height: 28 / 24,
                    ),
                    spacing(height: 5),
                    DefaultText(
                      horizontalPadding: 70,
                      textAlign: TextAlign.center,
                      style: AppTextStyle.paragraph2,
                      text:
                          "Enter your phone number and we'll send reset instructions via SMS.",
                      height: 18 / 14,
                    ),
                  ],
                ),

                spacing(height: 25),
                DefaultText(text: "Mobile Number", style: AppTextStyle.h3),
                CustomMobileNumber(
                  hintText: "10 digit mobile number",
                  controller: controller.mobileNumber,
                  inputFormatters: [Variables.maskFormatter],
                  onChange: (value) {
                    controller.onMobileChanged(value);
                    setState(() {});
                  },
                ),
                const VerticalHeight(height: 30),
                CustomButton(
                  isInactive: controller.mobileNumber.length != 12,
                  text: "Submit",
                  onPressed: () async {
                    FocusScope.of(context).requestFocus(FocusNode());
                    if (controller.formKeyForgotPass.currentState!.validate()) {
                      controller.verifyMobile();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
