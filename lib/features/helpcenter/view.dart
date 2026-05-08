import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luvpay/core/utils/functions/functions.dart';
import 'package:luvpay/shared/dialogs/dialogs.dart';
import 'package:luvpay/shared/widgets/custom_scaffold.dart';
import 'package:luvpay/shared/widgets/neumorphism.dart';

import '../../shared/widgets/luvpay_text.dart';
import '../../shared/widgets/tap_guard.dart';
import '../routes/routes.dart';
import 'controller.dart';
import 'utils/call_us_screen.dart';
import 'utils/email_support_screen.dart';

class HelpCenter extends StatelessWidget {
  const HelpCenter({super.key});

  HelpCenterController _resolveController() {
    return Get.isRegistered<HelpCenterController>()
        ? Get.find<HelpCenterController>()
        : Get.put(HelpCenterController());
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final supportActions = HelpCenterController.supportActions;

    return CustomScaffoldV2(
        appBarTitle: "Help Center",
        bottomNavigationBar: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: cs.surface),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  GridView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3),
                      itemCount: supportActions.length,
                      itemBuilder: (context, index) {
                        final item = supportActions[index];
                        return _buildSupportActionItem(context, item);
                      }),
                  const SizedBox(height: 18),
                  CustomButton(
                      text: "FAQs",
                      onPressed: () {
                        Get.toNamed(Routes.faqpage);
                      }),
                ])),
        scaffoldBody: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          LuvpayText(
              text: "CONTACT US", style: AppTextStyle.h3_semibold(context)),
          LuvpayText(
              textAlign: TextAlign.center,
              text:
                  "Can't find what you're looking for? Reach out to our support team for assistance."),
        ])));
  }

  Widget _buildSupportActionItem(BuildContext context, HelpCenterAction item) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      NeoNavIcon.icon(
          iconData: item.icon,
          onTap: () {
            TapGuard.run(
                key: item.tapGuardKey,
                action: () => _handleSupportAction(context, item));
          },
          borderRadius: BorderRadius.circular(14)),
      const SizedBox(height: 6),
      LuvpayText(
          text: item.label,
          style: AppTextStyle.paragraph1(context),
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w600,
          maxFontSize: 12,
          minFontSize: 8),
    ]);
  }

  Future<void> _handleSupportAction(
      BuildContext context, HelpCenterAction item) async {
    switch (item.type) {
      case HelpActionType.chat:
        CustomDialogStack.showUnderDevelopment(context, () {
          Get.back();
        });
        return;
      case HelpActionType.call:
        await Get.to(() => const CallUsScreen());
        return;
      case HelpActionType.email:
        await _openEmailSupport(context);
        return;
    }
  }

  Future<void> _openEmailSupport(BuildContext context) async {
    CustomDialogStack.showLoading(context);

    SupportUserProfile? profile;
    try {
      profile = await _resolveController().getEmailSupportProfile();
    } finally {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }

    if (!context.mounted) return;

    final resolvedProfile = profile;
    if (resolvedProfile == null) {
      CustomDialogStack.showSnackBar(context,
          "Unable to load your profile. Please try again.", null, null);
      return;
    }

    if (!resolvedProfile.canUseEmailSupport) {
      _showUpdateProfilePrompt(context, resolvedProfile);
      return;
    }

    await Get.to(() => EmailSupportScreen(profile: resolvedProfile));
  }

  void _showUpdateProfilePrompt(
      BuildContext context, SupportUserProfile profile) {
    final missingFields =
        _formatMissingFields(profile.missingEmailSupportFields);

    CustomDialogStack.showConfirmation(context, "Update Profile",
        "Please add your $missingFields before using email support.", () {
      Get.back();
    }, () async {
      Get.back();

      final regions = await Functions().fetchRegions(context);
      if (regions.isEmpty) return;

      Get.toNamed(Routes.updProfile, arguments: regions);
    }, leftText: "Cancel", rightText: "Update");
  }

  String _formatMissingFields(List<String> fields) {
    if (fields.isEmpty) return "profile details";
    if (fields.length == 1) return fields.first;

    return "${fields.sublist(0, fields.length - 1).join(", ")} and ${fields.last}";
  }
}
