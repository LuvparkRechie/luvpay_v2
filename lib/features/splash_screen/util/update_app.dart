import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:luvpay/shared/dialogs/dialogs.dart';
import 'package:luvpay/shared/widgets/colors.dart';
import 'package:luvpay/shared/widgets/custom_scaffold.dart';
import 'package:luvpay/shared/widgets/luvpay_text.dart';
import 'package:luvpay/shared/widgets/neumorphism.dart';

class UpdateApp extends StatelessWidget {
  const UpdateApp({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<dynamic, dynamic>?;
    final data = args?["data"];

    final String latestVersion = _readStoreVersion(data);
    final String? releaseNotes = _readReleaseNotes(data);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return CustomScaffoldV2(
        canPop: false,
        showAppBar: false,
        bodyColor: cs.surface,
        scaffoldBody: Center(
            child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
                decoration: BoxDecoration(
                    color: isDark ? AppColorV2.darkSurface2 : cs.surface,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                        color: isDark
                            ? AppColorV2.darkStroke.withValues(alpha: 0.85)
                            : AppColorV2.boxStroke),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black
                              .withValues(alpha: isDark ? 0.18 : 0.05),
                          blurRadius: isDark ? 24 : 16,
                          offset: const Offset(0, 10)),
                    ]),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                          gradient: AppColorV2.primaryGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: AppColorV2.lpBlueBrand
                                    .withValues(alpha: isDark ? 0.32 : 0.22),
                                blurRadius: 20,
                                offset: const Offset(0, 10)),
                          ]),
                      child: const Icon(Icons.system_update_rounded,
                          size: 42, color: Colors.white)),
                  const SizedBox(height: 22),
                  LuvpayText(
                      text: "Update Required",
                      textAlign: TextAlign.center,
                      style: AppTextStyle.h2(context),
                      color: cs.onSurface,
                      maxLines: 2),
                  const SizedBox(height: 10),
                  LuvpayText(
                      text:
                          "You must update to version $latestVersion to continue using luvpay.",
                      textAlign: TextAlign.center,
                      style: AppTextStyle.paragraph1(context),
                      color: AppColorV2.onSurfaceVariant,
                      maxLines: 4,
                      minFontSize: 12,
                      maxFontSize: 16),
                  if (releaseNotes != null && releaseNotes.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: isDark
                                ? AppColorV2.darkSurface
                                : AppColorV2.pastelBlueAccent,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                                color: isDark
                                    ? AppColorV2.darkStroke
                                    : AppColorV2.boxStroke)),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              LuvpayText(
                                  text: "What’s new",
                                  style: AppTextStyle.body1(context),
                                  color: AppColorV2.lpBlueBrand,
                                  maxLines: 1),
                              const SizedBox(height: 8),
                              LuvpayText(
                                  text: releaseNotes,
                                  style: AppTextStyle.paragraph2(context),
                                  color: cs.onSurface,
                                  maxLines: 20,
                                  overflow: TextOverflow.visible,
                                  minFontSize: 12,
                                  maxFontSize: 14),
                            ])),
                  ],
                  const SizedBox(height: 28),
                  CustomButton(
                      text: "Update Now",
                      onPressed: _openStore,
                      btnColor: AppColorV2.lpBlueBrand,
                      textColor: Colors.white,
                      leading: const Icon(Icons.open_in_new_rounded, size: 18))
                ]))));
  }

  void _openStore() async {
    final args = Get.arguments as Map<dynamic, dynamic>?;
    final data = args?["data"];

    final url = _readStoreUrl(data);

    if (url != null && url.isNotEmpty) {
      final uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }

    if (Get.context != null) {
      CustomDialogStack.showError(
        Get.context!,
        "luvpay",
        "Unable to open the app store right now. Please try again in a moment.",
        () => Get.back(),
      );
    }
  }

  String _readStoreVersion(dynamic data) {
    final version = _readDynamicString(
      data,
      readers: [
        (value) => value["storeVersion"],
        (value) => value.storeVersion,
      ],
    );

    return version?.trim().isNotEmpty == true ? version!.trim() : "Latest";
  }

  String? _readReleaseNotes(dynamic data) {
    return _readDynamicString(
      data,
      readers: [
        (value) => value["releaseNotes"],
        (value) => value.releaseNotes,
      ],
    );
  }

  String? _readStoreUrl(dynamic data) {
    final storeUrl = _readDynamicString(
      data,
      readers: [
        (value) => value["storeUrl"],
        (value) => value["appStoreLink"],
        (value) => value.storeUrl,
        (value) => value.appStoreLink,
      ],
    );

    if (storeUrl != null && storeUrl.trim().isNotEmpty) {
      return storeUrl.trim();
    }

    final playStoreId = _readDynamicString(
      data,
      readers: [
        (value) => value["playStoreId"],
        (value) => value.playStoreId,
      ],
    );
    final appleId = _readDynamicString(
      data,
      readers: [
        (value) => value["appleId"],
        (value) => value.appleId,
      ],
    );

    if (Platform.isAndroid && playStoreId != null && playStoreId.isNotEmpty) {
      return "https://play.google.com/store/apps/details?id=$playStoreId";
    }

    if (Platform.isIOS && appleId != null && appleId.isNotEmpty) {
      return "https://apps.apple.com/app/id$appleId";
    }

    return null;
  }

  String? _readDynamicString(
    dynamic data, {
    required List<dynamic Function(dynamic)> readers,
  }) {
    for (final reader in readers) {
      try {
        final value = reader(data);
        if (value is String && value.isNotEmpty) {
          return value;
        }
      } catch (_) {
        continue;
      }
    }

    return null;
  }
}
