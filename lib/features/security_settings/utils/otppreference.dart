import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../auth/authentication.dart';
import '../../../shared/widgets/colors.dart';
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

  @override
  void initState() {
    super.initState();
    initializeBioMetric();
  }

  void initializeBioMetric() async {
    isBioTrans = await Authentication().getBiometricTrans();

    ///this is for in-app otp
    isInAppOtp = await Authentication().getInAppOtp() ?? false;

    setState(() {});
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
      AppSettings.openAppSettings();
      return;
    }

    setState(() {
      isInAppOtp = !isInAppOtp;
    });

    await Authentication().setInAppOtp(isInAppOtp);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final controller = Get.put(SecuritySettingsController());

    return CustomScaffoldV2(
      appBarTitle: "Security Preference",
      enableToolBar: true,
      padding: EdgeInsets.only(left: 10, right: 10, top: 10),
      scaffoldBody: Column(
        children: [
          Obx(
            () => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InfoRowTile(
                      icon: LucideIcons.user,
                      title: 'In-app OTP Generator',
                      subtitle:
                          "Turn on to use in-app OTP authentication (default is SMS OTP).",
                      subtitleMaxlines: 2,
                      onTap: toggleInAppOtp,
                      trailing: Container(
                        width: 50,
                        height: 25,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          color: isInAppOtp
                              ? AppColorV2.lpBlueBrand
                              : AppColorV2.inactiveButton,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
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
                                      spreadRadius: 1.0,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      trailingOnTap: toggleInAppOtp,
                    ),

                    InfoRowTile(
                      icon: LucideIcons.shield,
                      title: 'Login Security',
                      subtitle: "Enable secure login with biometrics.",
                      subtitleMaxlines: 2,
                      onTap: () {
                        controller.toggleBiometricAuthentication(
                          !controller.isToggle.value,
                        );
                      },
                      trailing: Container(
                        width: 50,
                        height: 25,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          color: controller.isToggle.value
                              ? AppColorV2.lpBlueBrand
                              : AppColorV2.inactiveButton,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
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
                                      spreadRadius: 1.0,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      trailingOnTap: () {
                        controller.toggleBiometricAuthentication(
                          !controller.isToggle.value,
                        );
                      },
                    ),
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
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
