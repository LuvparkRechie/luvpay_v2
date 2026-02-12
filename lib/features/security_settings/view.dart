// ignore_for_file: prefer_const_constructors, deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:luvpay/shared/dialogs/dialogs.dart';
import '../../shared/widgets/luvpay_loading.dart';
import '../../shared/widgets/custom_scaffold.dart';
import '../../shared/widgets/neumorphism.dart';
import 'controller.dart';
import 'utils/otppreference.dart';

class Security extends GetView<SecuritySettingsController> {
  const Security({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(SecuritySettingsController());

    return CustomScaffoldV2(
      appBarTitle: "Security Settings",
      enableToolBar: true,
      padding: EdgeInsets.zero,
      scaffoldBody: Obx(
        () =>
            controller.isLoading.value
                ? const LoadingCard()
                : StretchingOverscrollIndicator(
                  axisDirection: AxisDirection.down,
                  child: ScrollConfiguration(
                    behavior: ScrollBehavior().copyWith(overscroll: false),
                    child: ListView(
                      padding: EdgeInsets.only(left: 10, right: 10, top: 30),
                      children: [
                        Column(
                          spacing: 8,
                          children: [
                            InfoRowTile(
                              icon: LucideIcons.lock,
                              title: 'Update Password',
                              subtitle:
                                  "Secure your account with a new password.",
                              subtitleMaxlines: 2,
                              onTap: controller.verifyMobile,
                            ),
                            InfoRowTile(
                              icon: LucideIcons.fingerprint,
                              title: "Security Preference",
                              subtitleMaxlines: 2,
                              subtitle:
                                  "Use biometrics for secure transactions.",
                              onTap: () async {
                                CustomDialogStack.showLoading(context);
                                await Future.delayed(
                                  const Duration(milliseconds: 500),
                                );
                                Get.back();
                                Get.to(const OTPPreference());
                              },
                            ),
                            InfoRowTile(
                              icon: LucideIcons.fileX,
                              title: "Delete your account",
                              subtitleMaxlines: 2,
                              subtitle:
                                  "Remove your account and all stored data.",
                              onTap: () {
                                CustomDialogStack.showInfo(
                                  Get.context!,
                                  "🛠️ Delete Account",
                                  "The account deletion feature is currently under development and will be available soon.",
                                  () => Get.back(),
                                );
                              },
                            ),
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
