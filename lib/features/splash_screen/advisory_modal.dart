import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../shared/widgets/colors.dart';
import '../../shared/widgets/luvpay_text.dart';
import 'advisory_model.dart';

typedef SplashAdvisoryContentBuilder = Widget? Function(
  BuildContext context,
  SplashAdvisory advisory,
  int index,
);

class SplashAdvisoryModal {
  const SplashAdvisoryModal._();

  static Future<void> show({
    required BuildContext context,
    required List<SplashAdvisory> advisories,
    SplashAdvisoryContentBuilder? iconBuilder,
    SplashAdvisoryContentBuilder? titleBuilder,
    SplashAdvisoryContentBuilder? subtitleBuilder,
  }) async {
    if (advisories.isEmpty) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => _SplashAdvisoryDialog(
        advisories: advisories,
        iconBuilder: iconBuilder,
        titleBuilder: titleBuilder,
        subtitleBuilder: subtitleBuilder,
      ),
    );
  }
}

class _SplashAdvisoryDialog extends StatefulWidget {
  final List<SplashAdvisory> advisories;
  final SplashAdvisoryContentBuilder? iconBuilder;
  final SplashAdvisoryContentBuilder? titleBuilder;
  final SplashAdvisoryContentBuilder? subtitleBuilder;

  const _SplashAdvisoryDialog({
    required this.advisories,
    required this.iconBuilder,
    required this.titleBuilder,
    required this.subtitleBuilder,
  });

  @override
  State<_SplashAdvisoryDialog> createState() => _SplashAdvisoryDialogState();
}

class _SplashAdvisoryDialogState extends State<_SplashAdvisoryDialog> {
  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _isLastSlide => _currentIndex >= widget.advisories.length - 1;

  void _handleButton(SplashAdvisoryButton button) {
    if (button.action == SplashAdvisoryButtonAction.dismiss || _isLastSlide) {
      Navigator.of(context, rootNavigator: true).pop();
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: cs.onSurface.withValues(alpha: isDark ? 0.12 : 0.06),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.14),
                  blurRadius: 24,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: _dialogBodyHeight(context),
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: widget.advisories.length,
                      onPageChanged: (index) {
                        setState(() => _currentIndex = index);
                      },
                      itemBuilder: (context, index) {
                        return _AdvisorySlide(
                          advisory: widget.advisories[index],
                          index: index,
                          total: widget.advisories.length,
                          iconBuilder: widget.iconBuilder,
                          titleBuilder: widget.titleBuilder,
                          subtitleBuilder: widget.subtitleBuilder,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildFooter(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _dialogBodyHeight(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    return height < 650 ? height * 0.46 : 320;
  }

  Widget _buildFooter(BuildContext context) {
    final advisory = widget.advisories[_currentIndex];
    final primaryText = advisory.primaryButton.text.trim().isNotEmpty
        ? advisory.primaryButton.text.trim()
        : (_isLastSlide ? "Okay" : "Next");
    final primaryButton = SplashAdvisoryButton(
      text: primaryText,
      action: advisory.primaryButton.action,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.advisories.length > 1) ...[
          SmoothPageIndicator(
            controller: _pageController,
            count: widget.advisories.length,
            effect: ExpandingDotsEffect(
              dotHeight: 7,
              dotWidth: 7,
              spacing: 5,
              expansionFactor: 2.8,
              dotColor: Theme.of(context).colorScheme.onSurface.withValues(
                    alpha: Theme.of(context).brightness == Brightness.dark
                        ? 0.22
                        : 0.16,
                  ),
              activeDotColor: AppColorV2.lpBlueBrand,
            ),
          ),
          const SizedBox(height: 14),
        ],
        Row(
          children: [
            if (advisory.secondaryButton != null) ...[
              Expanded(
                child: _AdvisoryButton(
                  text: advisory.secondaryButton!.text,
                  onPressed: () => _handleButton(advisory.secondaryButton!),
                  isPrimary: false,
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: _AdvisoryButton(
                text: primaryButton.text,
                onPressed: () => _handleButton(primaryButton),
                isPrimary: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AdvisorySlide extends StatelessWidget {
  final SplashAdvisory advisory;
  final int index;
  final int total;
  final SplashAdvisoryContentBuilder? iconBuilder;
  final SplashAdvisoryContentBuilder? titleBuilder;
  final SplashAdvisoryContentBuilder? subtitleBuilder;

  const _AdvisorySlide({
    required this.advisory,
    required this.index,
    required this.total,
    required this.iconBuilder,
    required this.titleBuilder,
    required this.subtitleBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final showTitle = advisory.title.trim().isNotEmpty;
    final showSubtitle = advisory.subtitle.trim().isNotEmpty;
    final icon = iconBuilder?.call(context, advisory, index) ??
        _AdvisoryIcon(advisory: advisory);
    final title = titleBuilder?.call(context, advisory, index) ??
        (showTitle
            ? LuvpayText(
                text: advisory.title.trim(),
                style: AppTextStyle.h2(context),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              )
            : null);
    final subtitle = subtitleBuilder?.call(context, advisory, index) ??
        (showSubtitle
            ? LuvpayText(
                text: advisory.subtitle.trim(),
                style: AppTextStyle.paragraph2(context),
                color: cs.onSurface.withValues(alpha: 0.68),
                textAlign: TextAlign.center,
                maxLines: 12,
                overflow: TextOverflow.ellipsis,
              )
            : null);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (total > 1)
            Align(
              alignment: Alignment.centerLeft,
              child: LuvpayText(
                text: "${index + 1} of $total",
                style: AppTextStyle.body2(context),
                color: AppColorV2.lpBlueBrand,
                maxLines: 1,
              ),
            ),
          if (total > 1) const SizedBox(height: 10),
          Center(child: icon),
          const SizedBox(height: 16),
          if (title != null) title,
          if (title != null && subtitle != null) const SizedBox(height: 8),
          if (subtitle != null) subtitle,
        ],
      ),
    );
  }
}

class _AdvisoryIcon extends StatelessWidget {
  final SplashAdvisory advisory;

  const _AdvisoryIcon({required this.advisory});

  @override
  Widget build(BuildContext context) {
    final color = _resolveIconColor(advisory.iconColor);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: isDark ? 0.18 : 0.12),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.28 : 0.18),
          width: 0.8,
        ),
      ),
      child: Icon(
        _resolveIconData(advisory.iconName),
        color: color,
        size: 30,
      ),
    );
  }

  Color _resolveIconColor(String rawColor) {
    final parsed = _tryParseHexColor(rawColor);
    if (parsed != null) return parsed;

    return AppColorV2.lpBlueBrand;
  }

  Color? _tryParseHexColor(String rawColor) {
    final cleaned = rawColor.trim().replaceFirst("#", "");
    if (cleaned.length != 6 && cleaned.length != 8) return null;

    final value = int.tryParse(cleaned, radix: 16);
    if (value == null) return null;

    return cleaned.length == 6 ? Color(0xFF000000 | value) : Color(value);
  }

  IconData _resolveIconData(String rawIcon) {
    final normalized =
        rawIcon.trim().toLowerCase().replaceAll(RegExp(r'[\s\-]+'), '_');

    switch (normalized) {
      case "alert":
      case "warning":
      case "notice":
        return Icons.warning_amber_rounded;
      case "security":
      case "secure":
      case "shield":
      case "privacy":
        return Icons.shield_rounded;
      case "maintenance":
      case "settings":
      case "service":
        return Icons.build_circle_rounded;
      case "wallet":
      case "payment":
      case "pay":
        return Icons.account_balance_wallet_rounded;
      case "success":
      case "check":
      case "check_circle":
        return Icons.check_circle_rounded;
      case "error":
      case "failed":
        return Icons.error_rounded;
      case "notification":
      case "notifications":
      case "bell":
        return Icons.notifications_active_rounded;
      case "campaign":
      case "advisory":
      case "announcement":
        return Icons.campaign_rounded;
      case "info":
      case "information":
      default:
        return Icons.info_rounded;
    }
  }
}

class _AdvisoryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isPrimary;

  const _AdvisoryButton({
    required this.text,
    required this.onPressed,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = isPrimary
        ? AppColorV2.lpBlueBrand
        : AppColorV2.lpBlueBrand.withValues(alpha: 0.12);
    final fg = isPrimary ? cs.onPrimary : AppColorV2.lpBlueBrand;

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 86, minHeight: 44),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          backgroundColor: bg,
          foregroundColor: fg,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: LuvpayText(
          text: text,
          style: AppTextStyle.body1(context),
          color: fg,
          textAlign: TextAlign.center,
          maxLines: 1,
          minFontSize: 10,
        ),
      ),
    );
  }
}
