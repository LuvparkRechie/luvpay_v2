import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:luvpay/shared/widgets/colors.dart';
import '../../shared/widgets/custom_scaffold.dart';
import '../../shared/widgets/luvpay_text.dart';
import '../../shared/widgets/custom_textfield.dart';
import '../../shared/widgets/neumorphism.dart';
import '../../shared/widgets/spacing.dart';
import '../../shared/widgets/variables.dart';
import '../../shared/widgets/vertical_height.dart';
import 'controller.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final ForgotPasswordController controller = Get.put(
    ForgotPasswordController(),
  );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return CustomScaffoldV2(
      enableToolBar: true,
      backgroundColor: cs.surface,
      bodyColor: cs.surface,
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
                    LuvpayText(
                      horizontalPadding: 77,
                      text: "Recover Account",
                      style: AppTextStyle.h2(context),
                      color: AppColorV2.lpBlueBrand,
                      maxLines: 1,
                      height: 28 / 24,
                    ),
                    spacing(height: 5),
                    LuvpayText(
                      horizontalPadding: 70,
                      textAlign: TextAlign.center,
                      style: AppTextStyle.paragraph2(context),
                      text:
                          "Enter your phone number and we'll send reset instructions via SMS.",
                      height: 18 / 14,
                    ),
                  ],
                ),
                spacing(height: 25),
                LuvpayText(
                  text: "Mobile Number",
                  style: AppTextStyle.h3(context),
                ),
                CustomMobileNumber(
                  hintText: "10 digit mobile number",
                  controller: controller.mobileNumber,
                  inputFormatters: [Variables.maskFormatter],
                  onChange: (value) {
                    controller.onMobileChanged(value);
                    if (mounted) setState(() {});
                  },
                ),
                const VerticalHeight(height: 30),
                CustomButton(
                  isInactive: controller.mobileNumber.text.length != 12,
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
