import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../auth/authentication.dart';
import '../../../shared/widgets/colors.dart';
import '../../../shared/dialogs/dialogs.dart';
import '../../../shared/widgets/custom_scaffold.dart';
import '../../../shared/widgets/neumorphism.dart';
import '../../../core/security/security/app_security.dart';
import '../controller.dart';

class OTPPreference extends StatefulWidget {
  const OTPPreference({super.key});

  @override
  State<OTPPreference> createState() => _OTPPreferenceState();
}

class _OTPPreferenceState extends State<OTPPreference> {
  bool? isBioTrans = false;
  bool isInAppOtp = false;
  bool isInAppPending = false;
  bool hasInAppSecret = false;
  DateTime? inAppActivationDate;

  @override
  void initState() {
    super.initState();
    initializeBioMetric();
  }

  void initializeBioMetric() async {
    isBioTrans = await Authentication().getBiometricTrans();
    await _refreshInAppOtpState();
    setState(() {});
  }

  Future<void> _refreshInAppOtpState() async {
    isInAppOtp = await Authentication().getInAppOtp() ?? false;
    hasInAppSecret = await Authentication().hasInAppOtpSecret();
    inAppActivationDate = await Authentication().getInAppOtpActivationDate();
    isInAppPending = await Authentication().isInAppOtpPending();
  }

  void setBioTrans() async {
    bool isBioTransEnabled = await AppSecurity.authenticateBio();

    if (isBioTransEnabled) {
      if (isBioTrans!) {
        setState(() {
          isBioTrans = false;
        });
        await Authentication().setBiometricTrans(false);
      } else {
        setState(() {
          isBioTrans = true;
        });
        await Authentication().setBiometricTrans(true);
      }
    } else {
      AppSettings.openAppSettings();
    }
  }

  ///inap otp
  void toggleInAppOtp() async {
    bool isAuthenticated = await AppSecurity.authenticateBio();

    if (!isAuthenticated) {
      CustomDialogStack.showError(
          context, "Authentication required", "Unable to verify biometrics.",
          () {
        Get.back();
      });
      return;
    }

    final enable = !isInAppOtp;

    if (enable && !hasInAppSecret) {
      CustomDialogStack.showInfo(context, "In-App OTP unavailable",
          "This account does not have an active TOTP secret yet. Please wait for backend support or sync your account again.",
          () {
        Get.back();
      });
      return;
    }

    CustomDialogStack.showConfirmation(
        context,
        enable ? "Enable In-App OTP?" : "Disable In-App OTP?",
        enable
            ? "Supported transactions will use your registered device for in-app OTP. Login and password recovery will stay on SMS."
            : "Supported transactions will go back to SMS OTP only.", () {
      Get.back();
    }, () async {
      Get.back();
      await Authentication().setInAppOtp(enable);
      await _refreshInAppOtpState();

      if (!mounted) {
        return;
      }

      setState(() {});

      if (enable && isInAppPending && inAppActivationDate != null) {
        CustomDialogStack.showInfo(context, "Activation pending",
            "In-app OTP will activate 24 hours after device registration.\nAvailable on ${DateFormat('MMM d, yyyy hh:mm a').format(inAppActivationDate!)}.",
            () {
          Get.back();
        });
        return;
      }

      CustomDialogStack.showSuccess(
          context,
          "Updated",
          enable
              ? "In-app OTP is now enabled for supported transactions."
              : "In-app OTP has been turned off.", () {
        Get.back();
      });
    });
  }

  String _buildInAppOtpSubtitle() {
    if (!hasInAppSecret) {
      return "Unavailable until the backend returns a TOTP secret for this device.";
    }

    if (isInAppOtp && isInAppPending && inAppActivationDate != null) {
      return "Pending activation until ${DateFormat('MMM d, yyyy hh:mm a').format(inAppActivationDate!)}. Login and password recovery stay on SMS.";
    }

    if (isInAppOtp) {
      return "Enabled for supported transactions. Login and password recovery stay on SMS.";
    }

    return "Turn on to use in-app OTP for supported transactions. Login and password recovery stay on SMS.";
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SecuritySettingsController());

    return CustomScaffoldV2(
        appBarTitle: "Security Preference",
        enableToolBar: true,
        padding: EdgeInsets.only(left: 10, right: 10, top: 10),
        scaffoldBody: Column(children: [
          Obx(() =>
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  InfoRowTile(
                      icon: LucideIcons.user,
                      title: 'In-app OTP Generator',
                      subtitle: _buildInAppOtpSubtitle(),
                      subtitleMaxlines: 3,
                      onTap: toggleInAppOtp,
                      trailing: Container(
                          width: 50,
                          height: 25,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              color: isInAppOtp
                                  ? AppColorV2.lpBlueBrand
                                  : AppColorV2.inactiveButton),
                          child: Stack(alignment: Alignment.center, children: [
                            AnimatedPositioned(
                                duration: Duration(milliseconds: 200),
                                left: isInAppOtp ? 30 : 5,
                                child: Container(
                                    width: 15,
                                    height: 15,
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(30),
                                        boxShadow: [
                                          BoxShadow(
                                              color: Colors.black26,
                                              blurRadius: 2.0,
                                              spreadRadius: 1.0),
                                        ]))),
                          ])),
                      trailingOnTap: toggleInAppOtp),

                  InfoRowTile(
                      icon: LucideIcons.shield,
                      title: 'Login Security',
                      subtitle: "Enable secure login with biometrics.",
                      subtitleMaxlines: 2,
                      onTap: () {
                        controller.toggleBiometricAuthentication(
                            !controller.isToggle.value);
                      },
                      trailing: Container(
                          width: 50,
                          height: 25,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              color: controller.isToggle.value
                                  ? AppColorV2.lpBlueBrand
                                  : AppColorV2.inactiveButton),
                          child: Stack(alignment: Alignment.center, children: [
                            AnimatedPositioned(
                                duration: Duration(milliseconds: 200),
                                left: controller.isToggle.value ? 30 : 5,
                                child: Container(
                                    width: 15,
                                    height: 15,
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(30),
                                        boxShadow: [
                                          BoxShadow(
                                              color: Colors.black26,
                                              blurRadius: 2.0,
                                              spreadRadius: 1.0),
                                        ]))),
                          ])),
                      trailingOnTap: () {
                        controller.toggleBiometricAuthentication(
                            !controller.isToggle.value);
                      }),
                  // InfoRowTile(
                  //   icon: LucideIcons.receipt,
                  //   title: 'Transaction Security',
                  //   subtitle: "Secure transactions with biometrics.",
                  //   subtitleMaxlines: 2,
                  //   onTap: () {
                  //     controller.toggleBiometricAuthentication(
                  //       !controller.isToggle.value,
                  //     );
                  //   },
                  //   trailing: Container(
                  //     width: 50,
                  //     height: 25,
                  //     decoration: BoxDecoration(
                  //       borderRadius: BorderRadius.circular(30),
                  //       color: controller.isToggle.value
                  //           ? AppColorV2.lpBlueBrand
                  //           : AppColorV2.inactiveButton,
                  //     ),
                  //     child: Stack(
                  //       alignment: Alignment.center,
                  //       children: [
                  //         AnimatedPositioned(
                  //           duration: Duration(milliseconds: 200),
                  //           left: controller.isToggle.value ? 30 : 5,
                  //           child: Container(
                  //             width: 15,
                  //             height: 15,
                  //             decoration: BoxDecoration(
                  //               color: Colors.white,
                  //               borderRadius: BorderRadius.circular(30),
                  //               boxShadow: [
                  //                 BoxShadow(
                  //                   color: Colors.black26,
                  //                   blurRadius: 2.0,
                  //                   spreadRadius: 1.0,
                  //                 ),
                  //               ],
                  //             ),
                  //           ),
                  //         ),
                  //       ],
                  //     ),
                  //   ),
                  //   trailingOnTap: setBioTrans,
                  // ),
                ]),
              ])),
        ]));
  }
}
