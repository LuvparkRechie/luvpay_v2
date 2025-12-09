import 'package:flutter/material.dart';
import 'package:luvpay/custom_widgets/app_color_v2.dart';
import 'package:luvpay/custom_widgets/custom_text_v2.dart';

class InfoRowTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? value;
  final IconData? trailingIcon;
  final VoidCallback onTap;
  final bool showIcon;
  final int? maxLines;

  const InfoRowTile({
    super.key,
    required this.icon,
    required this.title,
    this.value,
    this.trailingIcon,
    required this.onTap,
    this.showIcon = true,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minVerticalPadding: 0,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColorV2.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColorV2.primary, size: 20),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (value != null)
            DefaultText(text: value!, style: AppTextStyle.body1),
          DefaultText(
            maxLines: maxLines ?? 2,
            text: title,
            color: AppColorV2.primaryTextColor,
            style: AppTextStyle.body1,
          ),
        ],
      ),
      trailing:
          showIcon
              ? Icon(trailingIcon, color: AppColorV2.lpTealBrand, size: 16)
              : null,
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
}

class SectionListView extends StatelessWidget {
  final String sectionTitle;
  final List<Map<String, dynamic>> items;
  final bool showTrailingIcon;

  const SectionListView({
    super.key,
    required this.sectionTitle,
    required this.items,
    this.showTrailingIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: AppColorV2.background,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColorV2.primaryTextColor.withValues(alpha: .05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DefaultText(text: sectionTitle, style: AppTextStyle.h3),
          const SizedBox(height: 8),
          ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return InfoRowTile(
                icon: item['icon'],
                title: item['title'],
                value: item['value'],
                trailingIcon: item['trailingIcon'],
                onTap: item['onTap'] ?? () {},
                showIcon: item['showIcon'] ?? showTrailingIcon,
                maxLines: item['maxLines'],
              );
            },
          ),
        ],
      ),
    );
  }
}
