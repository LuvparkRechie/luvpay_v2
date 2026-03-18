// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:luvpay/auth/authentication.dart';
import 'package:luvpay/shared/widgets/colors.dart';
import 'package:luvpay/shared/widgets/custom_scaffold.dart';
import 'package:luvpay/shared/widgets/luvpay_loading.dart';
import 'package:luvpay/shared/widgets/spacing.dart';
import 'package:luvpay/shared/widgets/variables.dart';
import 'package:luvpay/shared/dialogs/dialogs.dart';
import 'package:luvpay/shared/widgets/neumorphism.dart';
import '../../shared/widgets/luvpay_text.dart';
import '../../shared/widgets/custom_textfield.dart';
import '../../core/utils/functions/functions.dart';
import '../../core/security/security/app_security.dart';
import '../routes/routes.dart';
import 'controller.dart';

Widget _loginHeader(BuildContext context, {String? customTitle}) {
  final cs = Theme.of(context).colorScheme;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 30),
      Image(
        image: const AssetImage("assets/images/luvpay_logo.png"),
        height: 30,
        fit: BoxFit.contain,
      ),
      const SizedBox(height: 30),
      LuvpayText(
        textAlign: TextAlign.center,
        text: customTitle ?? "Login to luvpay",
        style: AppTextStyle.h2(context),
        maxLines: 1,
        color: cs.onSurface.withAlpha(250),
      ),
      LuvpayText(
        text: "Login to your luvpay account to continue using our services.",
        color: cs.onSurface.withAlpha(120),
      ),
    ],
  );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final LoginScreenController controller = Get.put(LoginScreenController());
  bool isEnabledBioLogin = false, isLoadingPage = true;
  List userData = [];
  Widget? screen;

  @override
  void initState() {
    controller.password = TextEditingController();
    super.initState();
    Variables.inactiveTmr?.cancel();
    checkIfEnabledBio();
    getBgTmrStatus();
  }

  void getBgTmrStatus() => Authentication().enableTimer(false);

  Future<void> checkIfEnabledBio() async {
    final usd = await Authentication().getUserLogin();
    isEnabledBioLogin = (await Authentication().getBiometricStatus())!;
    userData = usd == null ? [] : [usd];
    setState(() {
      screen = userData.isEmpty
          ? DefaultLoginScreen()
          : UsePasswordScreen(isAllowBio: isEnabledBioLogin);
      isLoadingPage = false;
    });
  }

  @override
  Widget build(BuildContext context) => CustomScaffoldV2(
        padding: EdgeInsets.all(10),
        bottomNavigationBar: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: LuvpayText(
                style: AppTextStyle.textbox(context),
                text: 'V${Variables.version}')),
        useNormalBody: true,
        enableToolBar: false,
        canPop: false,
        appBar: null,
        backgroundColor: Theme.of(context).colorScheme.surface,
        scaffoldBody: isLoadingPage ? LoadingCard() : screen!,
      );
}

class DefaultLoginScreen extends StatefulWidget {
  const DefaultLoginScreen({super.key});
  @override
  State<DefaultLoginScreen> createState() => _DefaultLoginScreenState();
}

class _DefaultLoginScreenState extends State<DefaultLoginScreen> {
  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(LoginScreenController());
    final cs = Theme.of(context).colorScheme;
    return Obx(() => StretchingOverscrollIndicator(
          axisDirection: AxisDirection.down,
          child: ScrollConfiguration(
            behavior: const ScrollBehavior().copyWith(overscroll: false),
            child: SingleChildScrollView(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _loginHeader(context),
                    spacing(height: 10),
                    DefaultContainer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                LuvpayText(
                                    text: "Mobile Number",
                                    style: AppTextStyle.body1(context),
                                    height: 20 / 16,
                                    color: cs.onSurface.withAlpha(250)),
                                CustomMobileNumber(
                                    textInputAction: TextInputAction.next,
                                    hintText: "10 digit mobile number",
                                    controller: ctrl.mobileNumber,
                                    inputFormatters: [Variables.maskFormatter]),
                                spacing(height: 14),
                                LuvpayText(
                                    text: "Password",
                                    style: AppTextStyle.body1(context),
                                    color: cs.onSurface.withAlpha(250)),
                                CustomTextField(
                                  hintText: "Enter your password",
                                  controller: ctrl.password,
                                  isObscure: !ctrl.isShowPass.value,
                                  suffixIcon: !ctrl.isShowPass.value
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  onIconTap: () => ctrl.visibilityChanged(
                                      !ctrl.isShowPass.value),
                                  onChange: (value) =>
                                      ctrl.canProceed.value = value.isNotEmpty,
                                ),
                              ]),
                          Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: ctrl.isLoading.value
                                    ? () {}
                                    : () => Get.toNamed(
                                        arguments: ctrl.mobileNumber.text,
                                        Routes.forgotPass),
                                child: LuvpayText(
                                    style: AppTextStyle.body1(context),
                                    text: "Forgot Password?",
                                    color: AppColorV2.lpBlueBrand),
                              )),
                          const SizedBox(height: 30),
                          Column(children: [
                            CustomButton(
                              text: "Log in",
                              onPressed: () async {
                                FocusScope.of(context)
                                    .requestFocus(FocusNode());
                                CustomDialogStack.showLoading(context);
                                if (ctrl.mobileNumber.text.isEmpty) {
                                  Get.back();
                                  CustomDialogStack.showSnackBar(
                                      context,
                                      "Mobile number is empty",
                                      Colors.red,
                                      () {});
                                  return;
                                }
                                if (ctrl.mobileNumber.text.length != 12) {
                                  Get.back();
                                  CustomDialogStack.showSnackBar(
                                      context,
                                      "Incorrect mobile number",
                                      Colors.red,
                                      () {});
                                  return;
                                }
                                if (ctrl.password.text.isEmpty) {
                                  Get.back();
                                  CustomDialogStack.showSnackBar(context,
                                      "Password is empty", Colors.red, () {});
                                  return;
                                }
                                String devKey =
                                    await Functions().getUniqueDeviceId();
                                Map<String, dynamic> postParam = {
                                  "mobile_no":
                                      "63${ctrl.mobileNumber.text.toString().replaceAll(" ", "")}",
                                  "pwd": ctrl.password.text,
                                  "device_key": devKey.toString(),
                                };
                                ctrl.postLogin(Get.context!, postParam,
                                    (data) async {
                                  if (data[0]["items"].isNotEmpty) {
                                    final userLogin =
                                        await Authentication().getUserLogin();
                                    if (userLogin == null) {
                                      GetStorage().write('isFirstLogin', true);
                                    }
                                    await Authentication()
                                        .setLogoutStatus(false);
                                    Get.offAllNamed(Routes.dashboard);
                                  }
                                });
                              },
                            ),
                            const SizedBox(height: 14),
                            CustomButton(
                              text: "Create account",
                              btnColor: AppColorV2.background,
                              bordercolor: AppColorV2.lpBlueBrand,
                              textColor: AppColorV2.lpBlueBrand,
                              onPressed: () => Get.toNamed(Routes.registration),
                            ),
                            const SizedBox(height: 14),
                          ]),
                        ],
                      ),
                    ),
                  ]),
            ),
          ),
        ));
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
    setState(() => userData = usd == null ? [] : [usd]);
  }

  @override
  Widget build(BuildContext context) => Builder(builder: (context) {
        if (widget.appbar == null) {
          return SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: bodyWidget());
        }
        return CustomScaffoldV2(
          padding: EdgeInsets.all(10),
          enableToolBar: false,
          canPop: false,
          appBar: null,
          appBarLeadingWidth: 200,
          onPressedLeading: () => Get.offNamed(Routes.login),
          scaffoldBody: bodyWidget(),
        );
      });

  Widget bodyWidget() {
    final ctrl = Get.put(LoginScreenController());
    final cs = Theme.of(context).colorScheme;
    return userData.isEmpty
        ? Container()
        : SingleChildScrollView(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _loginHeader(context),
              spacing(height: 10),
              DefaultContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LayoutBuilder(builder: (context, constraints) {
                      if (userData[0]["first_name"] == null ||
                          userData[0]["first_name"].toString().isEmpty) {
                        return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              LuvNeuPress.rectangle(
                                  radius: BorderRadius.circular(10),
                                  child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: SizedBox(
                                          width: double.infinity,
                                          child: LuvpayText(
                                              text:
                                                  "+${Variables.maskMobileNumber(userData[0]["mobile_no"])}",
                                              style: AppTextStyle.paragraph1(
                                                  context),
                                              maxLines: 1,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primaryContainer)))),
                            ]);
                      }
                      return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LuvNeuPress.rectangle(
                                radius: BorderRadius.circular(10),
                                child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: SizedBox(
                                        width: double.infinity,
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.max,
                                            children: [
                                              LuvpayText(
                                                  text: userData[0]
                                                          ["first_name"]
                                                      .toString(),
                                                  style:
                                                      AppTextStyle.h4(context),
                                                  color: AppColorV2.lpBlueBrand
                                                      .withAlpha(180),
                                                  maxLines: 1),
                                              LuvpayText(
                                                  text: userData[0][
                                                                  "first_name"] ==
                                                              null ||
                                                          userData[0]
                                                                  ["first_name"]
                                                              .toString()
                                                              .isEmpty
                                                      ? ""
                                                      : "+63 ${ctrl.mobnum.substring(2, 5)} ${ctrl.mobnum.substring(5, 8)} ${ctrl.mobnum.substring(8)}",
                                                  style:
                                                      AppTextStyle.paragraph1(
                                                          context),
                                                  maxLines: 1,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primaryContainer),
                                            ])))),
                          ]);
                    }),
                    spacing(height: 10),
                    Align(
                        alignment: Alignment.centerLeft,
                        child: LuvpayText(
                            text: "Password",
                            style: AppTextStyle.body1(context),
                            height: 20 / 16,
                            color: cs.onBackground.withAlpha(250))),
                    Obx(() => CustomTextField(
                          controller: ctrl.password,
                          hintText: "Your password",
                          isObscure: !ctrl.isShowPass.value,
                          onChange: (value) =>
                              ctrl.canProceed.value = value.isNotEmpty,
                          suffixIcon: !ctrl.isShowPass.value
                              ? Icons.visibility_off
                              : Icons.visibility,
                          onIconTap: () =>
                              ctrl.visibilityChanged(!ctrl.isShowPass.value),
                        )),
                    Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Get.toNamed(Routes.forgotPass),
                          child: LuvpayText(
                              style: AppTextStyle.body1(context),
                              text: "Forgot Password?",
                              color: AppColorV2.lpBlueBrand),
                        )),
                    const SizedBox(height: 20),
                    Obx(() => CustomButton(
                          isInactive: !ctrl.canProceed.value,
                          text: "Log in",
                          textColor: AppColorV2.background,
                          onPressed: () async {
                            if (ctrl.password.text.isEmpty) {
                              CustomDialogStack.showSnackBar(
                                  context,
                                  "Password must not be empty",
                                  Colors.red,
                                  () {});
                              return;
                            }
                            final userData =
                                await Authentication().getUserData2();
                            CustomDialogStack.showLoading(Get.context!);
                            String devKey =
                                await Functions().getUniqueDeviceId();
                            Map<String, dynamic> postParam = {
                              "mobile_no": userData["mobile_no"],
                              "pwd": ctrl.password.text,
                              "device_key": devKey.toString()
                            };
                            ctrl.postLogin(Get.context!, postParam,
                                (data) async {
                              Get.back();
                              await Authentication().setLogoutStatus(false);
                              if (data[0]["items"].isNotEmpty) {
                                Get.offAllNamed(Routes.dashboard);
                              }
                            });
                          },
                        )),
                    const SizedBox(height: 18),
                    if (widget.isAllowBio)
                      CustomButton(
                        textColor: AppColorV2.lpBlueBrand,
                        bordercolor: AppColorV2.lpBlueBrand,
                        btnColor: AppColorV2.background,
                        leading: Icon(Icons.fingerprint_rounded,
                            color: AppColorV2.lpBlueBrand, size: 22),
                        text: "Biometrics Login",
                        onPressed: () async {
                          String devKey = await Functions().getUniqueDeviceId();
                          Map<String, dynamic> data =
                              await Authentication().getEncryptedKeys()
                                ..["device_key"] = devKey.toString();
                          if (await AppSecurity.authenticateBio()) {
                            CustomDialogStack.showLoading(Get.context!);
                            ctrl.postLogin(Get.context!, data, (data) async {
                              Get.back();
                              await Authentication().setLogoutStatus(false);
                              if (data[0]["items"].isNotEmpty) {
                                Get.offAllNamed(Routes.dashboard);
                              }
                            });
                          }
                        },
                      ),
                    const SizedBox(height: 14),
                    Center(
                        child: Visibility(
                      visible: widget.appbar == null,
                      child: InkWell(
                          onTap: ctrl.switchAccount,
                          child: LuvpayText(
                              text: "Switch account",
                              style: AppTextStyle.paragraph1(context),
                              color: AppColorV2.lpBlueBrand)),
                    )),
                    spacing(height: 10),
                  ],
                ),
              )
            ]),
          );
  }
}
