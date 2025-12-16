import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../custom_widgets/alert_dialog.dart';
import '../../custom_widgets/app_color_v2.dart';
import '../../custom_widgets/custom_text_v2.dart';
import '../../custom_widgets/loading.dart';
import '../../custom_widgets/luvpay/custom_scaffold.dart';
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

      scaffoldBody: Obx(
        () =>
            controller.isLoading.value
                ? LoadingCard()
                : SizedBox(
                  width: double.infinity,
                  child: StretchingOverscrollIndicator(
                    axisDirection: AxisDirection.down,
                    child: ScrollConfiguration(
                      behavior: ScrollBehavior().copyWith(overscroll: false),
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          SizedBox(height: 14),
                          updatePassword(),
                          SizedBox(height: 10),
                          Divider(
                            color: AppColorV2.bodyTextColor.withAlpha(80),
                          ),
                          SizedBox(height: 10),
                          securityPreference(context),
                          deleteAccout(),
                          SizedBox(height: 10),
                          Divider(
                            color: AppColorV2.bodyTextColor.withAlpha(80),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
      ),
    );
  }

  InkWell deleteAccout() {
    return InkWell(
      onTap: () {
        // controller.deleteAccount();
        CustomDialogStack.showInfo(
          Get.context!,
          "🛠️ Delete Account",
          "The account deletion feature is currently under development and will be available soon.",
          () {
            Get.back();
          },
        );
      },
      child: Row(
        children: [
          Icon(LucideIcons.fileX, color: AppColorV2.lpBlueBrand),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DefaultText(
                  text: "Delete your account",
                  style: AppTextStyle.h3,
                ),
                SizedBox(height: 4),
                DefaultText(
                  text: "Remove your account and all stored data.",
                  maxLines: 1,
                ),
              ],
            ),
          ),
          SizedBox(width: 10),
          Icon(
            LucideIcons.chevronRight,
            color: AppColorV2.bodyTextColor,
            size: 24,
          ),
        ],
      ),
    );
  }

  Visibility securityPreference(BuildContext context) {
    return Visibility(
      visible: controller.isBiometricSupported.value,
      child: InkWell(
        onTap: () async {
          CustomDialogStack.showLoading(context);
          await Future.delayed(Duration(milliseconds: 500));
          Get.back();
          Get.to(OTPPreference());
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.fingerprint, color: AppColorV2.lpBlueBrand),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DefaultText(
                        text: "Security Preference",
                        style: AppTextStyle.h3,
                      ),
                      SizedBox(height: 4),
                      DefaultText(
                        text: "Use biometrics for secure transactions.",
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 10),
                Icon(
                  LucideIcons.chevronRight,
                  color: AppColorV2.bodyTextColor,
                  size: 24,
                ),
              ],
            ),
            SizedBox(height: 10),
            Divider(color: AppColorV2.bodyTextColor.withAlpha(80)),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  InkWell updatePassword() {
    return InkWell(
      onTap: controller.verifyMobile,
      child: Row(
        children: [
          Icon(LucideIcons.lock, color: AppColorV2.lpBlueBrand),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DefaultText(text: "Update Password", style: AppTextStyle.h3),
                SizedBox(height: 4),
                DefaultText(
                  text: "Secure your account with a new password.",
                  maxLines: 1,
                ),
              ],
            ),
          ),
          SizedBox(width: 10),
          Icon(
            LucideIcons.chevronRight,
            color: AppColorV2.bodyTextColor,
            size: 24,
          ),
        ],
      ),
    );
  }
}
