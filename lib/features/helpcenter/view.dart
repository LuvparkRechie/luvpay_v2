import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:luvpay/shared/widgets/custom_scaffold.dart';
import 'package:luvpay/shared/widgets/neumorphism.dart';

import '../../shared/widgets/luvpay_text.dart';
import '../routes/routes.dart';

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
  List<HelpActionItem> get _merchantGridItems => [
    HelpActionItem(
      icon: Iconsax.message,
      label: 'Chat with us',
      onTap: () async {},
    ),
    HelpActionItem(icon: Iconsax.call, label: 'Call us', onTap: () {}),
    HelpActionItem(icon: Iconsax.direct_inbox, label: 'Email us', onTap: () {}),
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
          onTap: item.onTap,
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
