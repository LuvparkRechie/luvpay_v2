import 'package:flutter/material.dart';
import 'package:luvpay/shared/widgets/luvpay_text.dart';

class NoDataFound extends StatelessWidget {
  final VoidCallback? onTap;
  final String? text;
  final String? subtext;
  final String? buttonText;
  final IconData icon;
  final IconData? buttonIcon;

  const NoDataFound({
    super.key,
    this.onTap,
    this.text,
    this.subtext,
    this.icon = Icons.search_off_rounded,
    this.buttonText,
    this.buttonIcon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: MediaQuery.of(context).size.width * 0.25,
            color: primary.withOpacity(0.75),
          ),
          const SizedBox(height: 5),
          LuvpayText(
            text: text ?? "No data found",
            fontSize: 16,
            fontWeight: FontWeight.w700,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          LuvpayText(
            text: subtext ?? "We’ll show items here once available.",
            fontSize: 12.5,
            fontWeight: FontWeight.normal,
            textAlign: TextAlign.center,
          ),
          if (onTap != null) ...[
            TextButton.icon(
              onPressed: onTap,
              icon: Icon(buttonIcon ?? Icons.refresh, size: 18),
              label: LuvpayText(text: buttonText ?? "Try again"),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
