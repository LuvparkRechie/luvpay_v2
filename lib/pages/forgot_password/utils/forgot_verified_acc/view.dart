import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../custom_widgets/custom_button.dart';
import '../../../../custom_widgets/luvpay/custom_scaffold.dart';
import '../../../../custom_widgets/custom_text_v2.dart';
import '../../../../custom_widgets/custom_textfield.dart';
import '../../../../custom_widgets/loading.dart';
import '../../../../custom_widgets/no_internet.dart';
import '../../../../custom_widgets/password_indicator.dart';
import '../../../../custom_widgets/spacing.dart';
import '../../../../custom_widgets/variables.dart';
import '../../../../custom_widgets/vertical_height.dart';

import '../../../../custom_widgets/app_color_v2.dart';
import 'controller.dart';

class ForgotVerifiedAcct extends StatefulWidget {
  const ForgotVerifiedAcct({super.key});

  @override
  _ForgotVerifiedAcctState createState() => _ForgotVerifiedAcctState();
}

class _ForgotVerifiedAcctState extends State<ForgotVerifiedAcct> {
  late final ForgotVerifiedAcctController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(ForgotVerifiedAcctController());
  }

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
      scaffoldBody: Obx(
        () =>
            controller.isLoading.value || controller.questionData.isEmpty
                ? const LoadingCard()
                : !controller.isInternetConn.value
                ? NoInternetConnected(onTap: controller.getSecQdata)
                : Form(
                  key: controller.formKeyForgotVerifiedAcc,
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      DefaultText(
                        text:
                            "Complete verification by providing security details and setting your password.",
                      ),
                      spacing(height: 20),
                      DefaultText(
                        text: controller.questionData[0]["question"],
                        style: AppTextStyle.h3,
                      ),
                      CustomTextField(
                        title: "Answer",
                        hintText: "Enter your answer",
                        textCapitalization: TextCapitalization.characters,
                        controller: controller.answer,
                        isReadOnly: controller.isVerifiedAns.value,
                      ),
                      spacing(height: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DefaultText(
                            text: "New Password",
                            style: AppTextStyle.h3,
                          ),
                          CustomTextField(
                            title: "Password",
                            hintText: "Enter your new password",
                            controller: controller.newPass,
                            isObscure: !controller.isShowNewPass.value,
                            suffixIcon:
                                !controller.isShowNewPass.value
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                            onChange: (value) {
                              controller.onPasswordChanged(value);
                            },
                            onIconTap: () {
                              controller.onToggleNewPass(
                                !controller.isShowNewPass.value,
                              );
                            },
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
                          Container(
                            clipBehavior: Clip.antiAlias,
                            decoration: ShapeDecoration(
                              shape: RoundedRectangleBorder(
                                side: BorderSide(
                                  width: 1,
                                  color: Colors.black.withAlpha(15),
                                ),
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      if (Variables.getPasswordStrengthText(
                                        controller.passStrength.value,
                                      ).isNotEmpty)
                                        Row(
                                          children: [
                                            DefaultText(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              text:
                                                  Variables.getPasswordStrengthText(
                                                    controller
                                                        .passStrength
                                                        .value,
                                                  ),
                                              color:
                                                  Variables.getColorForPasswordStrength(
                                                    controller
                                                        .passStrength
                                                        .value,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      SizedBox(
                                        width: Get.width / 2.4,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                PasswordStrengthIndicator(
                                                  strength: 1,
                                                  currentStrength:
                                                      controller
                                                          .passStrength
                                                          .value,
                                                  color: getColorForStrength(
                                                    controller
                                                        .passStrength
                                                        .value,
                                                  ),
                                                ),
                                                Container(width: 5),
                                                PasswordStrengthIndicator(
                                                  strength: 2,
                                                  currentStrength:
                                                      controller
                                                          .passStrength
                                                          .value,
                                                  color: getColorForStrength(
                                                    controller
                                                        .passStrength
                                                        .value,
                                                  ),
                                                ),
                                                Container(width: 5),
                                                PasswordStrengthIndicator(
                                                  strength: 3,
                                                  currentStrength:
                                                      controller
                                                          .passStrength
                                                          .value,
                                                  color: getColorForStrength(
                                                    controller
                                                        .passStrength
                                                        .value,
                                                  ),
                                                ),
                                                Container(width: 5),
                                                PasswordStrengthIndicator(
                                                  strength: 4,
                                                  currentStrength:
                                                      controller
                                                          .passStrength
                                                          .value,
                                                  color: getColorForStrength(
                                                    controller
                                                        .passStrength
                                                        .value,
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
                        ],
                      ),
                      const VerticalHeight(height: 30),
                      CustomButton(
                        text:
                            controller.isVerifiedAns.value
                                ? "Submit"
                                : "Verify",
                        loading: controller.isBtnLoading.value,
                        onPressed: () {
                          FocusScope.of(context).requestFocus(FocusNode());
                          if (controller.formKeyForgotVerifiedAcc.currentState!
                              .validate()) {
                            controller.secRequestOtp();
                          }
                        },
                      ),
                    ],
                  ),
                ),
      ),
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
            SizedBox(width: 5),
            DefaultText(
              height: 18 / 14,
              text: "Minimum of 8 characters",
              style: AppTextStyle.paragraph2,
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
            SizedBox(width: 5),
            DefaultText(
              height: 18 / 14,
              text: "At least one uppercase letter",
              style: AppTextStyle.paragraph2,
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
            SizedBox(width: 5),
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
