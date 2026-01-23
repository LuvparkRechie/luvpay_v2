import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:luvpay/custom_widgets/app_color_v2.dart';
import 'package:luvpay/custom_widgets/custom_text_v2.dart';

import 'luv_neumorphic.dart';

class InfoRowTile extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? value;
  final Widget? trailing;
  final VoidCallback? trailingOnTap;
  final VoidCallback onTap;
  final int? maxLines;
  final String? subtitle;
  final int? subtitleMaxlines;

  const InfoRowTile({
    super.key,
    this.icon,
    required this.title,
    this.value,
    this.subtitle,
    this.trailing,
    this.trailingOnTap,
    required this.onTap,
    this.maxLines,
    this.subtitleMaxlines,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: LuvNeuPress.rect(
        radius: radius,
        onTap: onTap,
        borderColor: null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Neumorphic(
                  style: LuvNeu.icon(
                    radius: BorderRadius.circular(12),
                    color: AppColorV2.background,
                    borderColor: null,
                  ),
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: Center(
                      child: Icon(icon, color: AppColorV2.primary, size: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],

              Expanded(
                child: Column(
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
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      DefaultText(
                        text: subtitle!,
                        maxLines: subtitleMaxlines ?? 1,
                      ),
                    ],
                  ],
                ),
              ),

              if (trailing != null) ...[
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: trailingOnTap,
                  behavior: HitTestBehavior.opaque,
                  child: trailing,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class SectionListView extends StatelessWidget {
  final String sectionTitle;
  final List<Map<String, dynamic>> items;

  const SectionListView({
    super.key,
    required this.sectionTitle,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
              trailing: item['trailing'],
              trailingOnTap: item['trailingOnTap'],
              onTap: item['onTap'] ?? () {},
              maxLines: item['maxLines'],
              subtitle: item['subtitle'],
              subtitleMaxlines: item['subtitleMaxlines'],
            );
          },
        ),
      ],
    );
  }
}

class DefaultContainer extends StatelessWidget {
  final Widget child;
  const DefaultContainer({super.key, required this.child});

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
      child: child,
    );
  }
}
