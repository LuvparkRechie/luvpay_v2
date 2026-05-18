// ignore_for_file: deprecated_member_use

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:luvpay/core/services/wallet_notification_poller.dart';
import 'package:luvpay/shared/widgets/colors.dart';
import '../../shared/widgets/confetti.dart';
import '../splash_screen/advisory_modal.dart';
import '../splash_screen/advisory_model.dart';
import '../splash_screen/advisory_service.dart';

class DashboardController extends GetxController {
  final currentIndex = 0.obs;
  final pageController = PageController();
  final box = GetStorage();
  final notifCount = 0.obs;
  final SplashAdvisoryService _advisoryService = const SplashAdvisoryService();
  bool _didFetchAdvisories = false;
  @override
  void onInit() {
    super.onInit();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await WalletNotificationPoller.pollNow();
      await _checkFirstLogin();
      // await _showAdvisoriesIfAvailable();
    });
  }

  void changePage(int index) {
    currentIndex.value = index;
    pageController.jumpToPage(index);
  }

  Future<void> _checkFirstLogin() async {
    final isFirstLogin = box.read('isFirstLogin') ?? true;
    if (!isFirstLogin) return;

    await Get.to(
        () => CelebrationScreen(
            title: "Welcome to luvpay!",
            message:
                "This looks like your first time logging in on this device.\nStart exploring now.",
            buttonText: "Let's Go!",
            icon: Icons.waving_hand_rounded,
            iconColor: AppColorV2.lpBlueBrand,
            showConfetti: true,
            onButtonPressed: () {
              box.write('isFirstLogin', false);
              Get.back();
            }),
        transition: Transition.fadeIn,
        duration: const Duration(milliseconds: 260));
  }

  Future<void> _showAdvisoriesIfAvailable() async {
    if (_didFetchAdvisories) return;
    _didFetchAdvisories = true;

    var advisories = await _advisoryService.fetchSplashAdvisories();
    if (advisories.isEmpty && kDebugMode) {
      advisories = _debugAdvisories;
    }
    if (advisories.isEmpty) return;

    final context = Get.overlayContext ?? Get.context;
    if (context == null) return;
    if (!context.mounted) return;

    await SplashAdvisoryModal.show(
      context: context,
      advisories: advisories,
    );
  }

  static const List<SplashAdvisory> _debugAdvisories = [
    SplashAdvisory(
      id: "debug-1",
      order: 1,
      iconName: "campaign",
      title: "LuvPay Advisory",
      subtitle:
          "This is a debug-only preview of the advisory modal without an image.",
      primaryButton: SplashAdvisoryButton(
        text: "Okay",
        action: SplashAdvisoryButtonAction.next,
      ),
      secondaryButton: null,
    ),
    SplashAdvisory(
      id: "debug-2",
      order: 2,
      iconName: "security",
      title: "Security Reminder",
      subtitle: "Never share your OTP, PIN, password, or account credentials.",
      primaryButton: SplashAdvisoryButton(
        text: "Continue",
        action: SplashAdvisoryButtonAction.next,
      ),
      secondaryButton: SplashAdvisoryButton(
        text: "Skip",
        action: SplashAdvisoryButtonAction.dismiss,
      ),
    ),
  ];
}
