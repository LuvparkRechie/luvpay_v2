// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:luvpay/auth/authentication.dart';
import 'package:luvpay/custom_widgets/app_color_v2.dart';
import 'package:luvpay/custom_widgets/luvpay/custom_scaffold.dart';
import 'package:luvpay/custom_widgets/luvpay/luvpay_loading.dart';
import 'package:luvpay/custom_widgets/spacing.dart';
import 'package:luvpay/custom_widgets/variables.dart';

import '../../custom_widgets/alert_dialog.dart';
import '../../custom_widgets/luvpay/custom_button.dart';
import '../../custom_widgets/custom_text_v2.dart';
import '../../custom_widgets/custom_textfield.dart';
import '../../custom_widgets/vertical_height.dart';
import '../../functions/functions.dart';
import '../../security/app_security.dart';
import '../routes/routes.dart';
import 'controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final LoginScreenController controller = Get.put(LoginScreenController());
  bool isEnabledBioLogin = false;
  bool isLoadingPage = true;
  List userData = [];
  Widget? screen;

  @override
  void initState() {
    controller.password = TextEditingController();
    super.initState();
    if (Variables.inactiveTmr != null) {
      Variables.inactiveTmr!.cancel();
    }
    checkIfEnabledBio();
    getBgTmrStatus();
  }

  void getBgTmrStatus() async {
    await Authentication().enableTimer(false);
  }

  checkIfEnabledBio() async {
    final usd = await Authentication().getUserLogin();
    bool? isEnabledBio = await Authentication().getBiometricStatus();

    isEnabledBioLogin = isEnabledBio!;

    if (usd == null) {
      userData.clear();
    } else {
      userData.add(usd);
    }

    if (userData.isNotEmpty) {
      setState(() {
        screen = UsePasswordScreen(isAllowBio: isEnabledBioLogin);
        isLoadingPage = false;
      });
      return;
    } else {
      setState(() {
        screen = DefaultLoginScreen();
        isLoadingPage = false;
      });
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffoldV2(
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: DefaultText(
          style: AppTextStyle.textbox(context),
          text: 'V${Variables.version}',
        ),
      ),
      useNormalBody: true,
      enableToolBar: false,
      canPop: false,
      appBar: null,
      backgroundColor: Theme.of(context).colorScheme.surface,

      scaffoldBody: isLoadingPage ? LoadingCard() : screen!,
    );
  }
}

class DefaultLoginScreen extends StatefulWidget {
  const DefaultLoginScreen({super.key});

  @override
  State<DefaultLoginScreen> createState() => _DefaultLoginScreenState();
}

class _DefaultLoginScreenState extends State<DefaultLoginScreen> {
  final box = GetStorage();

  @override
  Widget build(BuildContext context) {
    final LoginScreenController controller = Get.put(LoginScreenController());

    return Obx(
      () => StretchingOverscrollIndicator(
        axisDirection: AxisDirection.down,
        child: ScrollConfiguration(
          behavior: const ScrollBehavior().copyWith(overscroll: false),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 30),
                Image(
                  image: AssetImage("assets/images/luvpay_logo.png"),
                  width: 100,
                ),
                SizedBox(height: 18),
                Column(
                  children: [
                    DefaultText(
                      text: "Welcome to luvpay!",
                      style: AppTextStyle.h1(context),
                      color: AppColorV2.lpBlueBrand,
                      maxLines: 1,
                    ),
                    SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: DefaultText(
                        maxLines: 1,
                        text: "Enter your number and password to log in",
                        style: AppTextStyle.paragraph1(context),
                      ),
                    ),
                  ],
                ),
                VerticalHeight(height: 50),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DefaultText(
                      text: "Mobile Number",
                      style: AppTextStyle.h3(context),

                      height: 20 / 16,
                    ),
                    CustomMobileNumber(
                      textInputAction: TextInputAction.next,
                      hintText: "10 digit mobile number",
                      controller: controller.mobileNumber,
                      inputFormatters: [Variables.maskFormatter],
                    ),
                    spacing(height: 14),
                    DefaultText(
                      text: "Password",
                      style: AppTextStyle.h3(context),
                    ),
                    CustomTextField(
                      hintText: "Enter your password",
                      controller: controller.password,
                      isObscure: !controller.isShowPass.value,
                      suffixIcon:
                          !controller.isShowPass.value
                              ? Icons.visibility_off
                              : Icons.visibility,
                      onIconTap: () {
                        controller.visibilityChanged(
                          !controller.isShowPass.value,
                        );
                      },
                      onChange: (value) {
                        if (value.isNotEmpty) {
                          controller.canProceed.value = true;
                        } else {
                          controller.canProceed.value = false;
                        }
                      },
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed:
                        controller.isLoading.value
                            ? () {}
                            : () async {
                              Get.toNamed(
                                arguments: controller.mobileNumber.text,
                                Routes.forgotPass,
                              );
                            },
                    child: DefaultText(
                      style: AppTextStyle.body1(context),
                      text: "Forgot Password?",
                      color: AppColorV2.lpBlueBrand,
                    ),
                  ),
                ),
                SizedBox(height: 30),
                Column(
                  children: [
                    CustomButton(
                      text: "Log in",
                      onPressed: () async {
                        FocusScope.of(context).requestFocus(FocusNode());
                        CustomDialogStack.showLoading(context);

                        if (controller.mobileNumber.text.isEmpty) {
                          Get.back();
                          CustomDialogStack.showSnackBar(
                            context,
                            "Mobile number is empty",
                            Colors.red,
                            () {},
                          );
                          return;
                        } else if (controller.mobileNumber.text.length != 12) {
                          Get.back();
                          CustomDialogStack.showSnackBar(
                            context,
                            "Incorrect mobile number",
                            Colors.red,
                            () {},
                          );
                          return;
                        }

                        if (controller.password.text.isEmpty) {
                          Get.back();
                          CustomDialogStack.showSnackBar(
                            context,
                            "Password is empty",
                            Colors.red,
                            () {},
                          );
                          return;
                        }

                        String devKey = await Functions().getUniqueDeviceId();

                        Map<String, dynamic> postParam = {
                          "mobile_no":
                              "63${controller.mobileNumber.text.toString().replaceAll(" ", "")}",
                          "pwd": controller.password.text,
                          "device_key": devKey.toString(),
                        };

                        controller.postLogin(Get.context!, postParam, (
                          data,
                        ) async {
                          if (data[0]["items"].isNotEmpty) {
                            final userLogin =
                                await Authentication().getUserLogin();
                            if (userLogin == null) {
                              box.write('isFirstLogin', true);
                            }
                            Get.offAllNamed(Routes.dashboard);
                          }
                        });
                      },
                    ),
                    SizedBox(height: 14),
                    CustomButton(
                      text: "Create account",
                      btnColor: AppColorV2.background,
                      bordercolor: AppColorV2.lpBlueBrand,
                      textColor: AppColorV2.lpBlueBrand,
                      onPressed: () {
                        Get.toNamed(Routes.registration);
                      },
                    ),
                    SizedBox(height: 14),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class UsePasswordScreen extends StatefulWidget {
  final Widget? appbar;
  final bool isAllowBio;

  const UsePasswordScreen({super.key, this.appbar, required this.isAllowBio});

  @override
  State<UsePasswordScreen> createState() => _UsePasswordScreenState();
}

class _UsePasswordScreenState extends State<UsePasswordScreen> {
  List userData = [];

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  void getUserData() async {
    final usd = await Authentication().getUserData2();

    if (usd == null) {
      setState(() {
        userData.clear();
      });
    } else {
      setState(() {
        userData.add(usd);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        if (widget.appbar == null) {
          return SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: bodyWidget(),
          );
        }
        return CustomScaffoldV2(
          enableToolBar: false,
          canPop: false,
          appBar: null,
          appBarLeadingWidth: 200,
          onPressedLeading: () {
            Get.offNamed(Routes.login);
          },
          scaffoldBody: bodyWidget(),
        );
      },
    );
  }

  Widget bodyWidget() {
    final LoginScreenController controller = Get.put(LoginScreenController());

    return Center(
      child:
          userData.isEmpty
              ? Container()
              : SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image(
                      image: AssetImage("assets/images/luvpay_logo.png"),
                      width: 100,
                    ),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (userData[0]["first_name"] == null ||
                            userData[0]["first_name"].toString().isEmpty) {
                          return Text(
                            "+${Variables.maskMobileNumber(userData[0]["mobile_no"])}",
                            style: GoogleFonts.openSans(
                              fontSize: 25,
                              fontWeight: FontWeight.w700,
                              color: AppColorV2.primaryTextColor,
                            ),
                            textAlign: TextAlign.center,
                          );
                        }
                        return DefaultText(
                          text:
                              "Welcome, ${userData[0]["first_name"].toString()}!",
                          style: AppTextStyle.h1(context),
                          maxLines: 1,
                        );
                      },
                    ),
                    SizedBox(height: 8),
                    DefaultText(
                      maxLines: 1,
                      text:
                          userData[0]["first_name"] == null ||
                                  userData[0]["first_name"].toString().isEmpty
                              ? ""
                              : "+63 ${controller.mobnum.substring(2, 5)} ${controller.mobnum.substring(5, 8)} ${controller.mobnum.substring(8)}",
                      style: AppTextStyle.paragraph1(context),
                    ),

                    spacing(height: 48),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: DefaultText(
                        text: "Password",
                        style: AppTextStyle.h3(context),
                      ),
                    ),
                    spacing(height: 8),
                    Obx(
                      () => CustomTextField(
                        controller: controller.password,
                        hintText: "Enter your password",
                        isObscure: !controller.isShowPass.value,
                        onChange: (value) {
                          if (value.isNotEmpty) {
                            controller.canProceed.value = true;
                          } else {
                            controller.canProceed.value = false;
                          }
                        },
                        suffixIcon:
                            !controller.isShowPass.value
                                ? Icons.visibility_off
                                : Icons.visibility,
                        onIconTap: () {
                          controller.visibilityChanged(
                            !controller.isShowPass.value,
                          );
                        },
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Get.toNamed(Routes.forgotPass);
                        },
                        child: DefaultText(
                          style: AppTextStyle.body1(context),
                          text: "Forgot Password?",
                          color: AppColorV2.lpBlueBrand,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Obx(
                      () => CustomButton(
                        isInactive: !controller.canProceed.value,
                        text: "Log in",
                        textColor: AppColorV2.background,
                        onPressed: () async {
                          if (controller.password.text.isEmpty) {
                            CustomDialogStack.showSnackBar(
                              context,
                              "Password must not be empty",
                              Colors.red,
                              () {},
                            );
                            return;
                          }

                          final userData =
                              await Authentication().getUserData2();

                          CustomDialogStack.showLoading(Get.context!);
                          String devKey = await Functions().getUniqueDeviceId();

                          Map<String, dynamic> postParam = {
                            "mobile_no": userData["mobile_no"],
                            "pwd": controller.password.text,
                            "device_key": devKey.toString(),
                          };

                          controller.postLogin(Get.context!, postParam, (data) {
                            Get.back();
                            if (data[0]["items"].isNotEmpty) {
                              Get.offAllNamed(Routes.dashboard);
                            }
                          });
                        },
                      ),
                    ),
                    SizedBox(height: 18),
                    if (widget.isAllowBio)
                      CustomButton(
                        textColor: AppColorV2.lpBlueBrand,
                        bordercolor: AppColorV2.lpBlueBrand,
                        btnColor: AppColorV2.background,
                        leading: Icon(
                          Icons.fingerprint_rounded,
                          color: AppColorV2.lpBlueBrand,
                          size: 22,
                        ),
                        text: "Biometrics Login",
                        onPressed: () async {
                          String devKey = await Functions().getUniqueDeviceId();

                          Map<String, dynamic> data =
                              await Authentication().getEncryptedKeys();
                          data["device_key"] = devKey.toString();

                          bool isEnabledBio =
                              await AppSecurity.authenticateBio();

                          if (isEnabledBio) {
                            CustomDialogStack.showLoading(Get.context!);

                            controller.postLogin(Get.context!, data, (data) {
                              Get.back();

                              if (data[0]["items"].isNotEmpty) {
                                Get.offAllNamed(Routes.dashboard);
                              }
                            });
                          }
                        },
                      ),
                    SizedBox(height: 14),
                    Visibility(
                      visible: widget.appbar == null,
                      child: InkWell(
                        onTap: controller.switchAccount,
                        child: DefaultText(
                          text: "Switch account",
                          style: AppTextStyle.paragraph1(context),
                          color: AppColorV2.lpBlueBrand,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
