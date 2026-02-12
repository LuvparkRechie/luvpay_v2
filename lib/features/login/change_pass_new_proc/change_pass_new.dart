import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:luvpay/auth/authentication.dart';
import 'package:luvpay/shared/dialogs/dialogs.dart';
import 'package:luvpay/shared/widgets/colors.dart';
import 'package:luvpay/shared/widgets/neumorphism.dart';

import 'package:luvpay/shared/widgets/luvpay_text.dart';
import 'package:luvpay/shared/widgets/custom_textfield.dart';
import 'package:luvpay/shared/widgets/password_indicator.dart';
import 'package:luvpay/shared/widgets/spacing.dart';
import 'package:luvpay/shared/widgets/variables.dart' show Variables;
import 'package:luvpay/shared/widgets/vertical_height.dart';
import 'package:luvpay/core/utils/functions/functions.dart';
import 'package:luvpay/core/network/http/api_keys.dart';
import 'package:luvpay/core/network/http/http_request.dart';
import 'package:luvpay/shared/components/otp_field/view.dart';

import '../../routes/routes.dart';

class ChangePassNewProtocol extends StatefulWidget {
  final String mobileNo;
  final String userId;

  const ChangePassNewProtocol({
    super.key,
    required this.mobileNo,
    required this.userId,
  });

  @override
  State<ChangePassNewProtocol> createState() => _ChangePassNewProtocolState();
}

class _ChangePassNewProtocolState extends State<ChangePassNewProtocol> {
  final GlobalKey<FormState> formKeyChangePass = GlobalKey<FormState>();

  final TextEditingController oldPassword = TextEditingController();
  final TextEditingController newPassword = TextEditingController();
  final TextEditingController newConfirmPassword = TextEditingController();

  final RxBool isShowOldPass = false.obs;
  final RxBool isShowNewPass = false.obs;
  final RxBool isShowNewPassConfirm = false.obs;

  final RxInt passStrength = 0.obs;

  void onToggleOldPass(bool isShow) {
    isShowOldPass.value = isShow;
    setState(() {});
  }

  void onToggleNewPass(bool isShow) {
    isShowNewPass.value = isShow;
    setState(() {});
  }

  void onToggleConfirmNewPass(bool isShow) {
    isShowNewPassConfirm.value = isShow;
    setState(() {});
  }

  void onPasswordChanged(String value) {
    passStrength.value = Variables.getPasswordStrength(value);
    setState(() {});
  }

  void onPasswordConfirmChanged(String value) {
    setState(() {});
  }

  Future<void> onSubmit() async {
    CustomDialogStack.showLoading(context);
    DateTime timeNow = await Functions.getTimeNow();
    Get.back();

    FocusManager.instance.primaryFocus?.unfocus();

    if (!formKeyChangePass.currentState!.validate()) {
      return;
    }

    if (newPassword.text != newConfirmPassword.text) {
      CustomDialogStack.showError(
        Get.context!,
        "luvpay",
        "Passwords do not match, please try again.",
        () {
          Get.back();
        },
      );
      return;
    }

    Map<String, String> reqParam = {
      "mobile_no": widget.mobileNo.toString(),
      "new_pwd": newPassword.text,
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

      Duration difference = otpExpiry.difference(timeNow);

      if (obj["success"] == "Y" || obj["status"] == "PENDING") {
        Map<String, String> putParam = {
          "mobile_no": widget.mobileNo.toString(),
          "otp": obj["otp"].toString(),
          "req_type": "SR",
        };

        Object args = {
          "time_duration": difference,
          "mobile_no": widget.mobileNo,
          "req_otp_param": reqParam,
          "verify_param": putParam,
          "is_forget_vfd_pass": true,
          "callback": (otp) async {
            if (otp != null) {
              CustomDialogStack.showLoading(Get.context!);

              Map<String, dynamic> postParam = {
                "mobile_no": widget.mobileNo,
                "otp": otp.toString(),
                "new_pwd": newPassword.text,
              };

              HttpRequestApi(
                api: ApiKeys.putLogin,
                parameters: postParam,
              ).putBody().then((retvalue) async {
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
                  return;
                }

                if (retvalue["success"] == "Y") {
                  Get.back();
                  CustomDialogStack.showSuccess(
                    Get.context!,
                    "Success",
                    retvalue["msg"],
                    leftText: "Okay",
                    () async {
                      Get.back();
                      CustomDialogStack.showLoading(Get.context!);
                      await Future.delayed(const Duration(seconds: 1));

                      final userLogin = await Authentication().getUserLogin();
                      if (userLogin == null) {
                        Get.back();
                        Get.offAllNamed(Routes.login);
                        return;
                      }

                      List userData = [userLogin];
                      userData =
                          userData.map((e) {
                            e["is_login"] = "N";
                            return e;
                          }).toList();

                      await Authentication().setLogin(jsonEncode(userData[0]));
                      await Authentication().setBiometricStatus(false);

                      Get.back();
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        backgroundColor: AppColorV2.lpBlueBrand,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: AppColorV2.lpBlueBrand,
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.light,
        ),
        title: Text("Reset password"),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(Iconsax.arrow_left, color: Colors.white),
        ),
      ),
      backgroundColor: AppColorV2.background,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
        child: Form(
          key: formKeyChangePass,
          child: StretchingOverscrollIndicator(
            axisDirection: AxisDirection.down,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  spacing(height: 20),
                  LuvpayText(
                    text:
                        "Your new password must be different from previous used passwords.",
                  ),
                  spacing(height: 20),
                  LuvpayText(
                    text: "New Password",
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurface,
                  ),
                  CustomTextField(
                    title: "New Password",
                    hintText: "Create your new password",
                    controller: newPassword,
                    isObscure: !isShowNewPass.value,
                    suffixIcon:
                        !isShowNewPass.value
                            ? Icons.visibility_off
                            : Icons.visibility,
                    onChange: (value) => onPasswordChanged(value),
                    onIconTap: () => onToggleNewPass(!isShowNewPass.value),
                    inputFormatters: [
                      FilteringTextInputFormatter.deny(RegExp(r'\s')),
                    ],
                    validator: (txtValue) {
                      if (txtValue == null || txtValue.isEmpty) {
                        return "Field is required";
                      }
                      if (txtValue == oldPassword.text) {
                        return "New password must be different";
                      }
                      if (txtValue.trim().length < 8 ||
                          txtValue.trim().length > 32) {
                        return "Password must be between 8 and 32 characters";
                      }
                      if (passStrength.value == 1) return "Very Weak Password";
                      if (passStrength.value == 2) return "Weak Password";
                      if (passStrength.value == 3) return "Medium Password";
                      return null;
                    },
                  ),
                  LuvpayText(
                    text: "Confirm Password",
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurface,
                  ),
                  CustomTextField(
                    title: "Confirm Password",
                    hintText: "Confirm your new password",
                    controller: newConfirmPassword,
                    isObscure: !isShowNewPassConfirm.value,
                    suffixIcon:
                        !isShowNewPassConfirm.value
                            ? Icons.visibility_off
                            : Icons.visibility,
                    onChange: (value) => onPasswordConfirmChanged(value),
                    onIconTap:
                        () =>
                            onToggleConfirmNewPass(!isShowNewPassConfirm.value),
                    inputFormatters: [
                      FilteringTextInputFormatter.deny(RegExp(r'\s')),
                    ],
                    validator: (txtValue) {
                      if (txtValue == null || txtValue.isEmpty) {
                        return "Field is required";
                      }
                      if (txtValue.trim().length < 8 ||
                          txtValue.trim().length > 32) {
                        return "Password must be between 8 and 32 characters";
                      }
                      if (txtValue != newPassword.text) {
                        return "New passwords do not match";
                      }
                      return null;
                    },
                  ),
                  Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: ShapeDecoration(
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          width: 1,
                          color: (isDark ? Colors.white : Colors.black)
                              .withOpacity(0.06),
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 15, 11, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LuvpayText(
                            text: "Password Strength",
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -.1,
                            wordSpacing: 2,
                            color: cs.onSurface,
                          ),
                          spacing(height: 15),
                          Row(
                            children: [
                              PasswordStrengthIndicator(
                                strength: 1,
                                currentStrength: passStrength.value,
                              ),
                              spacing(width: 5),
                              PasswordStrengthIndicator(
                                strength: 2,
                                currentStrength: passStrength.value,
                              ),
                              spacing(width: 5),
                              PasswordStrengthIndicator(
                                strength: 3,
                                currentStrength: passStrength.value,
                              ),
                              spacing(width: 5),
                              PasswordStrengthIndicator(
                                strength: 4,
                                currentStrength: passStrength.value,
                              ),
                            ],
                          ),
                          spacing(height: 15),
                          if (Variables.getPasswordStrengthText(
                            passStrength.value,
                          ).isNotEmpty)
                            Row(
                              children: [
                                Icon(
                                  Icons.shield_moon,
                                  color: Variables.getColorForPasswordStrength(
                                    passStrength.value,
                                  ),
                                  size: 18,
                                ),
                                SizedBox(width: 6),
                                LuvpayText(
                                  text: Variables.getPasswordStrengthText(
                                    passStrength.value,
                                  ),
                                  color: Variables.getColorForPasswordStrength(
                                    passStrength.value,
                                  ),
                                ),
                              ],
                            ),
                          spacing(height: 10),
                          LuvpayText(
                            text:
                                "The password should have a minimum of 8 characters, including at least one uppercase letter and a number.",
                            color: cs.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                  VerticalHeight(height: 30),
                  if (MediaQuery.of(context).viewInsets.bottom == 0)
                    CustomButton(text: "Submit", onPressed: onSubmit),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
