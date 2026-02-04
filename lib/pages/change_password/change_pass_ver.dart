import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:luvpay/http/http_request.dart';
import '../../auth/authentication.dart';
import '../../custom_widgets/alert_dialog.dart';
import '../../custom_widgets/app_color_v2.dart';
import '../../custom_widgets/custom_button.dart';
import '../../custom_widgets/custom_text_v2.dart';
import '../../custom_widgets/custom_textfield.dart';
import '../../custom_widgets/luvpay/custom_scaffold.dart';
import '../../custom_widgets/password_indicator.dart';
import '../../custom_widgets/spacing.dart';
import '../../custom_widgets/variables.dart';
import '../../functions/functions.dart';
import '../../http/api_keys.dart';
import '../otp_field/index.dart';
import '../routes/routes.dart';

class ChangePasswordVerified extends StatefulWidget {
  const ChangePasswordVerified({super.key});

  @override
  State<ChangePasswordVerified> createState() => _ChangePasswordVerifiedState();
}

class _ChangePasswordVerifiedState extends State<ChangePasswordVerified> {
  TextEditingController newPass = TextEditingController();
  final secData = Get.arguments["data"][0];
  final paramMobile = Get.arguments["mobile_no"];
  final GlobalKey<FormState> secFormKey = GlobalKey<FormState>();
  TextEditingController secAns = TextEditingController();
  TextEditingController oldPass = TextEditingController();
  RxInt passStrength = 1.obs;

  @override
  void initState() {
    super.initState();
    secAns = TextEditingController();
    oldPass = TextEditingController();
    newPass = TextEditingController();
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

  void secRequestOtp() async {
    CustomDialogStack.showLoading(context);
    DateTime timeNow = await Functions.getTimeNow();
    Get.back();
    Map<String, String> reqParam = {
      "mobile_no": paramMobile.toString(),
      "secq_no": secData["secq_no"].toString(),
      "secq_id": secData["secq_id"].toString(),
      "seca": secAns.text,
      "new_pwd": newPass.text,
      "old_pwd": oldPass.text,
    };

    Functions().requestOtp(reqParam, (obj) async {
      DateTime timeExp = DateFormat(
        "yyyy-MM-dd hh:mm:ss a",
      ).parse(obj["otp_exp_dt"].toString());
      DateTime otpExpiry = DateTime(
        timeExp.year,
        timeExp.month,
        timeExp.day,
        timeExp.hour,
        timeExp.minute,
        timeExp.millisecond,
      );

      // Calculate difference
      Duration difference = otpExpiry.difference(timeNow);

      if (obj["success"] == "Y" || obj["status"] == "PENDING") {
        Map<String, String> putParam = {
          "mobile_no": paramMobile.toString(),
          "otp": obj["otp"].toString(),
          "req_type": "UP",
        };
        Object args = {
          "time_duration": difference,
          "mobile_no": paramMobile,
          "req_otp_param": reqParam,
          "verify_param": putParam,
          "callback": (otp) async {
            if (otp != null) {
              CustomDialogStack.showLoading(context);

              Map<String, dynamic> postParam = {
                "mobile_no": paramMobile.toString(),
                "otp": otp.toString(),
                "new_pwd": newPass.text,
              };

              HttpRequestApi(
                api: ApiKeys.putLogin,
                parameters: postParam,
              ).putBody().then((retvalue) {
                Get.back();
                if (retvalue == "No Internet") {
                  CustomDialogStack.showError(
                    Get.context!,
                    "Error",
                    "Please check your internet connection and try again.",
                    () {
                      Get.back();
                    },
                  );
                  return;
                }
                if (retvalue == null) {
                  CustomDialogStack.showError(
                    Get.context!,
                    "Error",
                    "Error while connecting to server, Please try again.",
                    () {
                      Get.back();
                    },
                  );
                } else {
                  if (retvalue["success"] == "Y") {
                    Map<String, dynamic> data = {
                      "mobile_no": paramMobile,
                      "pwd": newPass.text,
                    };
                    final plainText = jsonEncode(data);

                    Authentication().encryptData(plainText);
                    CustomDialogStack.showSuccess(
                      Get.context!,
                      "Success!",
                      "Your password has been updated",
                      leftText: "Okay",
                      () async {
                        Get.offAllNamed(Routes.login);
                      },
                    );
                  } else {
                    CustomDialogStack.showError(
                      Get.context!,
                      "Error",
                      retvalue["msg"],
                      () {
                        Get.back();
                      },
                    );
                  }
                }
              });
            }
          },
        };

        Get.to(
          OtpFieldScreen(arguments: args),
          transition: Transition.rightToLeftWithFade,
          duration: Duration(milliseconds: 400),
        );
      }
    });
  }

  void onPasswordChanged(String value) {
    passStrength.value = Variables.getPasswordStrength(value);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffoldV2(
      enableToolBar: true,
      scaffoldBody: Form(
        key: secFormKey,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DefaultText(
              text:
                  "Complete verification by providing security details and setting your password.",
            ),
            spacing(height: 20),
            DefaultText(
              text: secData["question"],
              style: AppTextStyle.h3(context),
            ),
            CustomTextField(
              controller: secAns,
              hintText: "Enter your answer",
              textCapitalization: TextCapitalization.characters,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Please provide your security answer";
                }

                return null;
              },
            ),
            spacing(height: 14),
            DefaultText(text: "Old password", style: AppTextStyle.h3(context)),
            CustomTextField(
              hintText: "Enter your old password",
              controller: oldPass,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Field is required";
                }

                return null;
              },
            ),
            spacing(height: 14),
            DefaultText(text: "New password", style: AppTextStyle.h3(context)),
            CustomTextField(
              hintText: "Enter your new password",
              controller: newPass,
              onChange: (value) {
                onPasswordChanged(value);
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Field is required";
                }
                return null;
              },
            ),
            spacing(height: 20),
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: ShapeDecoration(
                shape: RoundedRectangleBorder(
                  side: BorderSide(width: 1, color: Colors.black.withAlpha(15)),
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
                          passStrength.value,
                        ).isNotEmpty)
                          Row(
                            children: [
                              DefaultText(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                text: Variables.getPasswordStrengthText(
                                  passStrength.value,
                                ),
                                color: Variables.getColorForPasswordStrength(
                                  passStrength.value,
                                ),
                              ),
                            ],
                          ),
                        Container(
                          width: Get.width / 2.4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  PasswordStrengthIndicator(
                                    strength: 1,
                                    currentStrength: passStrength.value,
                                    color: getColorForStrength(
                                      passStrength.value,
                                    ),
                                  ),
                                  Container(width: 5),
                                  PasswordStrengthIndicator(
                                    strength: 2,
                                    currentStrength: passStrength.value,
                                    color: getColorForStrength(
                                      passStrength.value,
                                    ),
                                  ),
                                  Container(width: 5),
                                  PasswordStrengthIndicator(
                                    strength: 3,
                                    currentStrength: passStrength.value,
                                    color: getColorForStrength(
                                      passStrength.value,
                                    ),
                                  ),
                                  Container(width: 5),
                                  PasswordStrengthIndicator(
                                    strength: 4,
                                    currentStrength: passStrength.value,
                                    color: getColorForStrength(
                                      passStrength.value,
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

            spacing(height: 30),
            CustomButton(
              isInactive:
                  newPass.text.isEmpty ||
                  !newPass.text.length.isEqual(8) &&
                      !newPass.text.length.isGreaterThan(7) ||
                  !newPass.text.contains(RegExp(r'[A-Z]')) ||
                  !newPass.text.contains(RegExp(r'[0-9]')),

              text: "Continue",
              onPressed: () {
                if (secFormKey.currentState?.validate() ?? false) {
                  secRequestOtp();
                }
              },
            ),
            spacing(height: 20),
          ],
        ),
      ),
    );
  }

  Column passValidation() {
    final password = newPass.text;
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
            SizedBox(width: 5),
            DefaultText(
              height: 18 / 14,
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
            SizedBox(width: 5),
            DefaultText(
              height: 18 / 14,
              text: "At least one number",
              style: AppTextStyle.paragraph2(context),
            ),
          ],
        ),
      ],
    );
  }
}
