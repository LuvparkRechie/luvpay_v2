import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../auth/authentication.dart';
import '../../../custom_widgets/app_color_v2.dart';
import '../../../custom_widgets/luvpay/custom_scaffold.dart';
import '../../../custom_widgets/luvpay/neumorphism.dart';
import '../../../security/app_security.dart';
import '../controller.dart';

class OTPPreference extends StatefulWidget {
  const OTPPreference({super.key});

  @override
  State<OTPPreference> createState() => _OTPPreferenceState();
}

class _OTPPreferenceState extends State<OTPPreference> {
  bool? isBioTrans = false;
  @override
  void initState() {
    super.initState();
    initializeBioMetric();
  }

  void initializeBioMetric() async {
    isBioTrans = await Authentication().getBiometricTrans();
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

  @override
  Widget build(BuildContext context) {
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
                DefaultContainer(
                  child: Column(
                    children: [
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
                            color:
                                controller.isToggle.value
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
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Column(
          //   crossAxisAlignment: CrossAxisAlignment.start,
          //   children: [
          //     Row(
          //       crossAxisAlignment: CrossAxisAlignment.center,
          //       children: [
          //         Icon(
          //           Iconsax.receipt_2,
          //           color: AppColorV2.lpBlueBrand,
          //           size: 30,
          //         ),
          //         SizedBox(width: 14),
          //         Expanded(
          //           child: Column(
          //             crossAxisAlignment: CrossAxisAlignment.start,
          //             children: [
          //               DefaultText(
          //                 text: "Transaction Security",
          //                 style: AppTextStyle.h3(context),(context),
          //               ),
          //               SizedBox(height: 4),
          //               DefaultText(
          //                 text: "Secure transactions with biometrics.",
          //               ),
          //             ],
          //           ),
          //         ),
          //         SizedBox(width: 10),
          //         InkWell(
          //           onTap: setBioTrans,
          //           child: Container(
          //             width: 50,
          //             height: 25,
          //             decoration: BoxDecoration(
          //               borderRadius: BorderRadius.circular(30),
          //               color:
          //                   (isBioTrans ?? false)
          //                       ? AppColorV2.lpBlueBrand
          //                       : AppColorV2.inactiveButton,
          //             ),
          //             child: Stack(
          //               alignment: Alignment.center,
          //               children: [
          //                 AnimatedPositioned(
          //                   duration: Duration(milliseconds: 200),
          //                   left: (isBioTrans ?? false) ? 30 : 5,
          //                   child: Container(
          //                     width: 15,
          //                     height: 15,
          //                     decoration: BoxDecoration(
          //                       color: Colors.white,
          //                       borderRadius: BorderRadius.circular(30),
          //                       boxShadow: [
          //                         BoxShadow(
          //                           color: Colors.black26,
          //                           blurRadius: 2.0,
          //                           spreadRadius: 1.0,
          //                         ),
          //                       ],
          //                     ),
          //                   ),
          //                 ),
          //               ],
          //             ),
          //           ),
          //         ),
          //       ],
          //     ),
          //     SizedBox(height: 14),
          //     Divider(color: AppColorV2.bodyTextColor.withAlpha(80)),
          //     SizedBox(height: 14),
          //   ],
          // ),
        ],
      ),
    );
  }
}
