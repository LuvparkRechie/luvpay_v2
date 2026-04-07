import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:luvpay/shared/dialogs/dialogs.dart';
import 'package:luvpay/shared/widgets/custom_scaffold.dart';
import 'package:luvpay/shared/widgets/neumorphism.dart';

import '../../shared/widgets/luvpay_text.dart';
import '../../shared/widgets/tap_guard.dart';
import '../routes/routes.dart';
import 'controller.dart';
import 'utils/call_us_screen.dart';
import 'utils/chat/chat_screen.dart';

class HelpActionItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const HelpActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

class HelpCenter extends StatefulWidget {
  const HelpCenter({super.key});

  @override
  State<HelpCenter> createState() => _HelpCenterState();
}

class _HelpCenterState extends State<HelpCenter> {
  final HelpCenterController controller = Get.put(HelpCenterController());

  static const String chatKey = "chat_support";
  static const String callKey = "call_support";
  static const String emailKey = "email_support";

  List<HelpActionItem> get _merchantGridItems => [
        HelpActionItem(
          icon: Iconsax.message,
          label: 'Chat with us',
          onTap: () {
            TapGuard.run(
              key: chatKey,
              action: () async {
                // Get.to(() => const ChatScreen());
                CustomDialogStack.showUnderDevelopment(Get.context!, () {
                  Get.back();
                });
              },
            );
          },
        ),
        HelpActionItem(
          icon: Iconsax.call,
          label: 'Call us',
          onTap: () {
            TapGuard.run(
              key: callKey,
              action: () async {
                Get.to(() => const CallUsScreen());
              },
            );
          },
        ),
        HelpActionItem(
          icon: Iconsax.direct_inbox,
          label: 'Email us',
          onTap: () {
            TapGuard.run(
              key: emailKey,
              action: () async {
                await controller.sendEmail();
              },
            );
          },
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

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
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
              ),
              itemCount: _merchantGridItems.length,
              itemBuilder: (context, index) {
                final item = _merchantGridItems[index];
                return _buildMerchantGridItem(item);
              },
            ),
            const SizedBox(height: 18),
            CustomButton(
              text: "FAQs",
              onPressed: () {
                Get.toNamed(Routes.faqpage);
              },
            ),
          ],
        ),
      ),
      scaffoldBody: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LuvpayText(
              text: "CONTACT US",
              style: AppTextStyle.h3_semibold(context),
            ),
            LuvpayText(
              textAlign: TextAlign.center,
              text:
                  "Can't find what you're looking for? Reach out to our support team for assistance.",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMerchantGridItem(HelpActionItem item) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        NeoNavIcon.icon(
          iconData: item.icon,
          onTap: () {
            TapGuard.run(
              key: item.label,
              action: () async {
                item.onTap();
              },
            );
          },
          borderRadius: BorderRadius.circular(14),
        ),
        const SizedBox(height: 6),
        LuvpayText(
          text: item.label,
          style: AppTextStyle.paragraph1(context),
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w600,
          maxFontSize: 12,
          minFontSize: 8,
        ),
      ],
    );
  }
}
