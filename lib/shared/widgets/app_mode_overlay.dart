import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:luvpay/core/network/http/api_keys.dart';
import 'package:luvpay/shared/widgets/colors.dart';
import 'package:luvpay/shared/widgets/luvpay_text.dart';
import 'package:luvpay/shared/widgets/neumorphism.dart';

class AppModeOverlay extends StatefulWidget {
  final Widget child;
  final String appVersion;
  final String themeModeLabel;

  const AppModeOverlay({
    super.key,
    required this.child,
    required this.appVersion,
    required this.themeModeLabel,
  });

  @override
  State<AppModeOverlay> createState() => _AppModeOverlayState();
}

class _AppModeOverlayState extends State<AppModeOverlay>
    with TickerProviderStateMixin {
  late Offset _chipPosition;
  bool _initialized = false;
  late AnimationController _snapController;
  late Animation<Offset> _snapAnimation;

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _snapAnimation = Tween<Offset>(begin: Offset.zero, end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _snapController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _snapController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final topInset = MediaQuery.of(context).padding.top;
      _chipPosition = Offset(0, topInset + 12);
      _initialized = true;
    }
  }

  bool get _isVisible => ApiKeys.showModeBanner && !ApiKeys.isProduction;

  void _snapToNearestEdge() {
    final size = MediaQuery.of(context).size;
    final topInset = MediaQuery.of(context).padding.top;
    const chipWidth = 60.0;
    const chipHeight = 60.0;
    const padding = 8.0;

    // Keep Y within bounds
    final minY = topInset;
    final maxY = size.height - chipHeight - padding;
    final clampedY = _chipPosition.dy.clamp(minY, maxY);

    // Determine nearest edge (center is at size.width / 2)
    final midPoint = size.width / 2;
    final targetX = _chipPosition.dx < midPoint
        ? padding
        : size.width - chipWidth - padding;

    final targetPosition = Offset(targetX, clampedY);

    // Create animation
    _snapAnimation = Tween<Offset>(
      begin: _chipPosition,
      end: targetPosition,
    ).animate(CurvedAnimation(parent: _snapController, curve: Curves.easeOut));

    _snapController.forward(from: 0.0).then((_) {
      setState(() {
        _chipPosition = targetPosition;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) {
      return widget.child;
    }

    return Stack(children: [
      Positioned.fill(child: widget.child),
      AnimatedBuilder(
        animation: _snapAnimation,
        builder: (context, child) {
          final displayPosition = _snapController.isAnimating
              ? _snapAnimation.value
              : _chipPosition;

          return Positioned(
            left: displayPosition.dx,
            top: displayPosition.dy,
            child: GestureDetector(
              onPanUpdate: (details) {
                if (_snapController.isAnimating) {
                  _snapController.stop();
                }
                setState(() {
                  _chipPosition = Offset(
                    _chipPosition.dx + details.delta.dx,
                    _chipPosition.dy + details.delta.dy,
                  );
                });
              },
              onPanEnd: (_) {
                _snapToNearestEdge();
              },
              child: _ModeChip(
                appVersion: widget.appVersion,
                themeModeLabel: widget.themeModeLabel,
              ),
            ),
          );
        },
      ),
    ]);
  }
}

class _ModeChip extends StatelessWidget {
  final String appVersion;
  final String themeModeLabel;

  const _ModeChip({
    required this.appVersion,
    required this.themeModeLabel,
  });

  Color _accent() {
    return ApiKeys.enforceSecurity
        ? AppColorV2.partialState
        : AppColorV2.incorrectState;
  }

  void _showStatusSheet(BuildContext context) {
    // Prevent opening multiple modals
    if (Get.isBottomSheetOpen ?? false) {
      return;
    }

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final accent = _accent();

    final sheet = SafeArea(
        top: false,
        child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Container(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
                decoration: BoxDecoration(
                    color: isDark
                        ? AppColorV2.darkSurface2
                        : AppColorV2.background,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                        color: isDark
                            ? AppColorV2.darkStroke
                            : AppColorV2.boxStroke),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black
                              .withValues(alpha: isDark ? 0.20 : 0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 12)),
                    ]),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                          color: cs.onSurface.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999))),
                  const SizedBox(height: 16),
                  Row(children: [
                    Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(colors: [
                              accent,
                              AppColorV2.lpBlueBrand,
                            ])),
                        child: const Icon(LucideIcons.shieldCheck,
                            color: Colors.white, size: 20)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          LuvpayText(
                              text: "Build Status",
                              style: AppTextStyle.h3(context),
                              color: cs.onSurface,
                              maxLines: 1),
                          LuvpayText(
                              text: "Visible only outside production builds.",
                              style: AppTextStyle.paragraph2(context),
                              color: AppColorV2.onSurfaceVariant,
                              maxLines: 2,
                              minFontSize: 11,
                              maxFontSize: 13),
                        ])),
                    NeoNavIcon.icon(
                        size: 38,
                        iconSize: 18,
                        padding: const EdgeInsets.all(8),
                        iconData: Icons.close_rounded,
                        iconColor: cs.onSurface,
                        onTap: () => Get.back()),
                  ]),
                  const SizedBox(height: 18),
                  _StatusCard(
                      label: "Environment",
                      value: ApiKeys.environmentLabel,
                      accent: AppColorV2.lpBlueBrand,
                      icon: LucideIcons.serverCog),
                  const SizedBox(height: 10),
                  _StatusCard(
                      label: "Security",
                      value: ApiKeys.securityLabel,
                      accent: accent,
                      icon: ApiKeys.enforceSecurity
                          ? LucideIcons.lock
                          : Icons.lock_open_rounded),
                  const SizedBox(height: 10),
                  _StatusCard(
                      label: "App Version",
                      value: "v$appVersion",
                      accent: AppColorV2.lpTealBrand,
                      icon: LucideIcons.badgeInfo),
                  const SizedBox(height: 10),
                  _StatusCard(
                      label: "Theme Mode",
                      value: themeModeLabel,
                      accent: AppColorV2.darkMintAccent,
                      icon: LucideIcons.palette),
                  const SizedBox(height: 10),
                  _StatusCard(
                      label: "API Target",
                      value:
                          "${ApiKeys.luvApi.toUpperCase()} / ${ApiKeys.parkSpaceApi.toUpperCase()}",
                      accent: AppColorV2.correctState,
                      icon: LucideIcons.network),
                ]))));
    Get.bottomSheet(
      sheet,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final accent = _accent();

    return LuvNeuPress.rectangle(
        radius: BorderRadius.circular(18),
        onTap: () => _showStatusSheet(context),
        depth: isDark ? 0.7 : 1.0,
        pressedDepth: isDark ? -0.25 : -0.55,
        background: isDark ? AppColorV2.darkSurface2 : AppColorV2.background,
        borderColor: accent.withValues(alpha: isDark ? 0.55 : 0.22),
        overlayOpacity: isDark ? 0.0 : 0.02,
        child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: accent.withValues(alpha: 0.34),
                            blurRadius: 10,
                            offset: const Offset(0, 0)),
                      ])),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                LuvpayText(
                    text: ApiKeys.modeBannerLabel,
                    style: AppTextStyle.body1(context),
                    color: cs.onSurface,
                    maxLines: 1,
                    minFontSize: 11,
                    maxFontSize: 13),
                LuvpayText(
                    text: "v$appVersion",
                    style: AppTextStyle.body2(context),
                    color: AppColorV2.onSurfaceVariant,
                    maxLines: 1,
                    minFontSize: 10,
                    maxFontSize: 12),
              ]),
              const SizedBox(width: 10),
              Icon(LucideIcons.chevronUp, size: 16, color: cs.onSurface),
            ])));
  }
}

class _StatusCard extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  final IconData icon;

  const _StatusCard({
    required this.label,
    required this.value,
    required this.accent,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color:
                isDark ? AppColorV2.darkSurface : AppColorV2.pastelBlueAccent,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: isDark ? AppColorV2.darkStroke : AppColorV2.boxStroke)),
        child: Row(children: [
          Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                  color: accent.withValues(alpha: isDark ? 0.22 : 0.12),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: accent, size: 18)),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                LuvpayText(
                    text: label,
                    style: AppTextStyle.body2(context),
                    color: AppColorV2.onSurfaceVariant,
                    maxLines: 1,
                    minFontSize: 10,
                    maxFontSize: 12),
                const SizedBox(height: 2),
                LuvpayText(
                    text: value,
                    style: AppTextStyle.body1(context),
                    color: cs.onSurface,
                    maxLines: 2,
                    minFontSize: 11,
                    maxFontSize: 14),
              ])),
        ]));
  }
}
