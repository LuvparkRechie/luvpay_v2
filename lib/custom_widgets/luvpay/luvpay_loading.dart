import 'package:flutter/material.dart';
import 'package:luvpay/custom_widgets/custom_text_v2.dart';

class LoadingCard extends StatelessWidget {
  final String text;

  final EdgeInsetsGeometry padding;

  final double radius;

  const LoadingCard({
    super.key,
    this.text = "Loading...",
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    this.radius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.35 : 0.10),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(
            color: cs.onSurface.withOpacity(isDark ? 0.12 : 0.06),
            width: 0.8,
          ),
        ),
        child: DefaultText(
          text: text,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          color: cs.onSurface.withOpacity(0.75),
        ),
      ),
    );
  }
}
