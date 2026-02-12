import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../../../shared/widgets/colors.dart';
import '../../../../shared/widgets/custom_scaffold.dart';
import '../../../../shared/widgets/luvpay_text.dart';
import '../../../../shared/widgets/custom_textfield.dart';
import '../../../../shared/widgets/neumorphism.dart';
import '../../../../shared/widgets/password_indicator.dart';
import '../../../../shared/widgets/spacing.dart';
import '../../../../shared/widgets/variables.dart';
import '../../../../shared/widgets/vertical_height.dart';
import 'controller.dart';

class CreateNewPassword extends StatefulWidget {
  const CreateNewPassword({super.key});

  @override
  _CreateNewPasswordState createState() => _CreateNewPasswordState();
}

class _CreateNewPasswordState extends State<CreateNewPassword> {
  final CreateNewPassController controller = Get.put(CreateNewPassController());

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

  @override
  Widget build(BuildContext context) {
    return CustomScaffoldV2(
      enableToolBar: true,
      scaffoldBody: Obx(() {
        int minutes = controller.remainingSeconds.value ~/ 60;
        int seconds = controller.remainingSeconds.value % 60;

        return Form(
          key: controller.formKeyCreatePass,
          child: StretchingOverscrollIndicator(
            axisDirection: AxisDirection.down,
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  spacing(height: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        "assets/images/reset_password2.svg",
                        height: 86,
                      ),
                      spacing(height: 10),
                      LuvpayText(
                        text: "Reset password ",
                        style: AppTextStyle.h2(context),
                        height: 28 / 24,
                      ),
                      spacing(height: 5),
                      LuvpayText(
                        height: 18 / 14,
                        textAlign: TextAlign.center,
                        style: AppTextStyle.paragraph2(context),
                        text:
                            "Your new password must be different from\nany passwords you've used before.",
                      ),
                    ],
                  ),
                  spacing(height: 25),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LuvpayText(
                        text: "New password",
                        style: AppTextStyle.h3(context),
                      ),
                      CustomTextField(
                        hintText: "New password",
                        controller: controller.newPass,
                        isObscure: !controller.isShowNewPass.value,
                        suffixIcon:
                            !controller.isShowNewPass.value
                                ? Icons.visibility_off
                                : Icons.visibility,
                        onChange: (value) {
                          controller.onPasswordChanged(value);
                          setState(() {
                            controller.newPass = controller.newPass;
                          });
                        },
                        onIconTap: () {
                          controller.onToggleNewPass(
                            !controller.isShowNewPass.value,
                          );
                        },
                        inputFormatters: [
                          FilteringTextInputFormatter.deny(RegExp(r'\s')),
                          LengthLimitingTextInputFormatter(30),
                        ],
                        validator: (txtValue) {
                          if (txtValue == null || txtValue.isEmpty) {
                            return "Field is required";
                          }
                          if (txtValue.length < 8 || txtValue.length > 32) {
                            return "Password must be between 8 and 32 characters";
                          }
                          if (controller.passStrength.value == 1) {
                            return "Very Weak Password";
                          }
                          if (controller.passStrength.value == 2) {
                            return "Weak Password";
                          }
                          if (controller.passStrength.value == 3) {
                            return "Medium Password";
                          }
                          return null;
                        },
                      ),
                      spacing(height: 14),
                      LuvpayText(
                        text: "Confirm password",
                        style: AppTextStyle.h3(context),
                      ),
                      CustomTextField(
                        onChange: (value) {
                          setState(() {
                            controller.confirmPass = controller.confirmPass;
                          });
                        },
                        hintText: "Confirm password",
                        controller: controller.confirmPass,
                        isObscure: !controller.isShowConfirmPass.value,
                        suffixIcon:
                            !controller.isShowConfirmPass.value
                                ? Icons.visibility_off
                                : Icons.visibility,
                        onIconTap: () {
                          controller.onToggleConfirmPass(
                            !controller.isShowConfirmPass.value,
                          );
                        },
                        inputFormatters: [
                          FilteringTextInputFormatter.deny(RegExp(r'\s')),
                          LengthLimitingTextInputFormatter(30),
                        ],
                        validator: (txtValue) {
                          if (txtValue == null || txtValue.isEmpty) {
                            return "Field is required";
                          }
                          if (txtValue != controller.newPass.text) {
                            return "Password do not match";
                          }
                          if (Variables.getPasswordStrengthText(
                                controller.passStrength.value,
                              ) !=
                              "Strong Password") {
                            return "For enhanced security, please create a stronger password.";
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                  spacing(height: 14),
                  Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: ShapeDecoration(
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          width: 1,
                          color: Colors.black.withValues(
                            alpha: 0.05999999865889549,
                          ),
                        ),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (Variables.getPasswordStrengthText(
                                controller.passStrength.value,
                              ).isNotEmpty)
                                Row(
                                  children: [
                                    LuvpayText(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      text: Variables.getPasswordStrengthText(
                                        controller.passStrength.value,
                                      ),
                                      color:
                                          Variables.getColorForPasswordStrength(
                                            controller.passStrength.value,
                                          ),
                                    ),
                                  ],
                                ),
                              SizedBox(
                                width: Get.width / 2.5,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        PasswordStrengthIndicator(
                                          strength: 1,
                                          currentStrength:
                                              controller.passStrength.value,
                                          color: getColorForStrength(
                                            controller.passStrength.value,
                                          ),
                                        ),
                                        Container(width: 5),
                                        PasswordStrengthIndicator(
                                          strength: 2,
                                          currentStrength:
                                              controller.passStrength.value,
                                          color: getColorForStrength(
                                            controller.passStrength.value,
                                          ),
                                        ),
                                        Container(width: 5),
                                        PasswordStrengthIndicator(
                                          strength: 3,
                                          currentStrength:
                                              controller.passStrength.value,
                                          color: getColorForStrength(
                                            controller.passStrength.value,
                                          ),
                                        ),
                                        Container(width: 5),
                                        PasswordStrengthIndicator(
                                          strength: 4,
                                          currentStrength:
                                              controller.passStrength.value,
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
                          passValidation(),
                        ],
                      ),
                    ),
                  ),
                  const VerticalHeight(height: 34),

                  CustomButton(
                    isInactive:
                        controller.newPass.text.isEmpty ||
                        !controller.newPass.text.length.isEqual(8) &&
                            !controller.newPass.text.length.isGreaterThan(7) ||
                        !controller.newPass.text.contains(RegExp(r'[A-Z]')) ||
                        !controller.newPass.text.contains(RegExp(r'[0-9]')),

                    text:
                        "${!controller.isFinish.value ? "Time left" : "Submit"} ${!controller.isFinish.value ? "- ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}" : ""}",

                    onPressed:
                        !controller.isFinish.value
                            ? () {}
                            : () async {
                              FocusScope.of(context).requestFocus(FocusNode());
                              if (controller.formKeyCreatePass.currentState!
                                  .validate()) {
                                controller.requestOtp();
                              }
                            },
                  ),
                  spacing(height: 20),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Column passValidation() {
    final password = controller.newPass.text;
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
            LuvpayText(
              text: "Minimum of 8 characters",
              style: AppTextStyle.paragraph2(context),
            ),
          ],
        ),
        SizedBox(height: 8),
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
            LuvpayText(
              text: "At least one uppercase letter",
              style: AppTextStyle.paragraph2(context),
            ),
          ],
        ),
        SizedBox(height: 8),
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
            LuvpayText(
              text: "At least one number",
              style: AppTextStyle.paragraph2(context),
            ),
          ],
        ),
      ],
    );
  }
}
