// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:luvpay/custom_widgets/alert_dialog.dart';
import 'package:luvpay/custom_widgets/custom_button.dart';
import 'package:luvpay/custom_widgets/luvpay/custom_scaffold.dart';
import 'package:luvpay/custom_widgets/custom_text_v2.dart';
import 'package:luvpay/custom_widgets/custom_textfield.dart';
import 'package:luvpay/custom_widgets/password_indicator.dart';
import 'package:luvpay/custom_widgets/spacing.dart';
import 'package:luvpay/custom_widgets/variables.dart';
import 'package:luvpay/custom_widgets/vertical_height.dart';
import 'package:luvpay/pages/registration/controller.dart';

import '../../custom_widgets/app_color_v2.dart';
import '../routes/routes.dart';

class RegistrationPage extends GetView<RegistrationController> {
  const RegistrationPage({super.key});

  @override
  Widget build(BuildContext context) {
    Color getColorForStrength(int strength) {
      switch (strength) {
        case 1:
        case 2:
          return AppColorV2.incorrectState;
        case 3:
          return AppColorV2.partialState;
        case 4:
          return AppColorV2.correctState;
        default:
          return AppColorV2.incorrectState;
      }
    }

    return CustomScaffoldV2(
      backgroundColor: AppColorV2.background,
      useNormalBody: true,
      enableToolBar: true,
      canPop: false,
      onPressedLeading: () {
        controller.mobileNumber.text = "";
        controller.password.text = "";
        Get.back();
      },
      scaffoldBody: SizedBox(
        height: MediaQuery.of(context).size.height,
        child: ScrollConfiguration(
          behavior: ScrollBehavior().copyWith(overscroll: false),
          child: StretchingOverscrollIndicator(
            axisDirection: AxisDirection.down,
            child: SingleChildScrollView(
              child: GetBuilder<RegistrationController>(
                builder: (ctxt) {
                  return Form(
                    key: controller.formKeyRegister,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Image(
                            image: AssetImage("assets/images/luvpay_logo.png"),
                            width: 60,
                            fit: BoxFit.contain,
                          ),
                        ),
                        SizedBox(height: 10),
                        Center(
                          child: DefaultText(
                            textAlign: TextAlign.center,
                            text: "Create your LuvPay Wallet account",
                            style: AppTextStyle.h1,
                            maxLines: 1,
                            minFontSize: 18,
                            height: 32 / 28,
                          ),
                        ),
                        SizedBox(height: 5),

                        DefaultText(
                          textAlign: TextAlign.center,
                          text:
                              "Quick, secure, and hassle-free setup to access seamless digital payments.",
                          height: 20 / 16,
                          style: AppTextStyle.paragraph1,
                        ),

                        const VerticalHeight(height: 30),

                        DefaultText(
                          text: "Mobile Number",
                          style: AppTextStyle.h3,
                          height: 20 / 16,
                        ),
                        CustomMobileNumber(
                          hintText: "10 digit mobile number",
                          controller: controller.mobileNumber,
                          inputFormatters: [Variables.maskFormatter],
                          onChange: (value) {
                            controller.onMobileChanged(value);
                          },
                        ),

                        spacing(height: 14),

                        DefaultText(
                          text: "Password",
                          style: AppTextStyle.h3,
                          height: 20 / 16,
                        ),
                        Obx(
                          () => CustomTextField(
                            hintText: "Create a password",
                            controller: controller.password,
                            isObscure: controller.isShowPass.value,
                            suffixIcon:
                                controller.isShowPass.value
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                            onIconTap: () {
                              controller.visibilityChanged(
                                !controller.isShowPass.value,
                              );
                            },
                            inputFormatters: [
                              FilteringTextInputFormatter.deny(RegExp(r'\s')),
                              LengthLimitingTextInputFormatter(30),
                            ],
                            validator: (txtValue) {
                              if (txtValue == null || txtValue.isEmpty) {
                                return "Password is required";
                              }
                              if (txtValue.length < 8 || txtValue.length > 32) {
                                return "Password must be between 8 and 32 characters";
                              }
                              return null;
                            },
                            onChange: (value) {
                              controller.onPasswordChanged(value);
                            },
                          ),
                        ),

                        spacing(height: 14),

                        Obx(
                          () => Container(
                            padding: const EdgeInsets.all(10),
                            clipBehavior: Clip.antiAlias,
                            decoration: ShapeDecoration(
                              shape: RoundedRectangleBorder(
                                side: BorderSide(
                                  width: 1,
                                  color: Colors.black.withValues(alpha: 0.06),
                                ),
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            child: passwordStrength(getColorForStrength),
                          ),
                        ),

                        const SizedBox(height: 46.0),

                        CustomButton(
                          text: "Continue",
                          isInactive:
                              Variables.getPasswordStrengthText(
                                controller.passStrength.value,
                              ) !=
                              "Strong Password",
                          textColor: Colors.white,
                          onPressed: () {
                            FocusScope.of(
                              Get.context!,
                            ).requestFocus(FocusNode());
                            if (controller.formKeyRegister.currentState!
                                .validate()) {
                              if (Variables.getPasswordStrengthText(
                                    controller.passStrength.value,
                                  ) !=
                                  "Strong Password") {
                                CustomDialogStack.showInfo(
                                  context,
                                  "Weak Password",
                                  "For your security, please choose a stronger password.",
                                  () {
                                    Get.back();
                                  },
                                );
                                return;
                              }
                              controller.onSubmit();
                            }
                          },
                        ),

                        spacing(height: 30),

                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              DefaultText(
                                style: AppTextStyle.paragraph2,
                                color: AppColorV2.primaryTextColor,
                                text: "Already have a LuvPay Wallet account?",
                                height: 18 / 14,
                              ),
                              SizedBox(width: 6),
                              InkWell(
                                onTap: () async {
                                  Get.offNamed(Routes.login);
                                },
                                child: DefaultText(
                                  text: "Log In",
                                  style: GoogleFonts.manrope(
                                    fontWeight: FontWeight.w700,
                                    decoration: TextDecoration.underline,
                                    decorationColor: AppColorV2.lpBlueBrand,
                                  ),
                                  color: AppColorV2.lpBlueBrand,
                                  height: 18 / 14,
                                ),
                              ),
                            ],
                          ),
                        ),

                        spacing(height: 30),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Column passwordStrength(Color Function(int strength) getColorForStrength) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (Variables.getPasswordStrengthText(
              controller.passStrength.value,
            ).isNotEmpty)
              Row(
                children: [
                  DefaultText(
                    fontSize: 14,
                    height: 18 / 14,
                    fontWeight: FontWeight.w700,
                    text: Variables.getPasswordStrengthText(
                      controller.passStrength.value,
                    ),
                    color: Variables.getColorForPasswordStrength(
                      controller.passStrength.value,
                    ),
                  ),
                ],
              ),
            SizedBox(
              width: Get.width / 2.4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      PasswordStrengthIndicator(
                        strength: 1,
                        currentStrength: controller.passStrength.value,
                        color: getColorForStrength(
                          controller.passStrength.value,
                        ),
                      ),
                      SizedBox(width: 5),
                      PasswordStrengthIndicator(
                        strength: 2,
                        currentStrength: controller.passStrength.value,
                        color: getColorForStrength(
                          controller.passStrength.value,
                        ),
                      ),
                      SizedBox(width: 5),
                      PasswordStrengthIndicator(
                        strength: 3,
                        currentStrength: controller.passStrength.value,
                        color: getColorForStrength(
                          controller.passStrength.value,
                        ),
                      ),
                      SizedBox(width: 5),
                      PasswordStrengthIndicator(
                        strength: 4,
                        currentStrength: controller.passStrength.value,
                        color: getColorForStrength(
                          controller.passStrength.value,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 14),
        passwordValidation(),
      ],
    );
  }

  Column passwordValidation() {
    final password = controller.password.text;
    final bool hasMinLength = password.length >= 8;
    final bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final bool hasNumber = password.contains(RegExp(r'[0-9]'));

    return Column(
      children: [
        Row(
          children: [
            Image(
              image: AssetImage(
                "assets/images/${hasMinLength ? "check_active" : "check_inactive"}.png",
              ),
              height: 20,
              fit: BoxFit.contain,
            ),
            SizedBox(width: 8),
            DefaultText(
              height: 18 / 14,
              text: "Minimum of 8 characters",
              style: AppTextStyle.paragraph2,
            ),
          ],
        ),
        SizedBox(height: 5),
        Row(
          children: [
            Image(
              image: AssetImage(
                "assets/images/${hasUppercase ? "check_active" : "check_inactive"}.png",
              ),
              height: 20,
              fit: BoxFit.contain,
            ),
            SizedBox(width: 8),
            DefaultText(
              height: 18 / 14,
              text: "At least one uppercase letter",
              style: AppTextStyle.paragraph2,
            ),
          ],
        ),
        SizedBox(height: 5),
        Row(
          children: [
            Image(
              image: AssetImage(
                "assets/images/${hasNumber ? "check_active" : "check_inactive"}.png",
              ),
              height: 20,
              fit: BoxFit.contain,
            ),
            SizedBox(width: 8),
            DefaultText(
              height: 18 / 14,
              text: "At least one number",
              style: AppTextStyle.paragraph2,
            ),
          ],
        ),
      ],
    );
  }
}
