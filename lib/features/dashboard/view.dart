// ignore_for_file: unused_element_parameter, deprecated_member_use

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_exit_app/flutter_exit_app.dart';
import 'package:get/get.dart';
import 'package:luvpay/auth/authentication.dart';
import 'package:luvpay/core/network/http/api_keys.dart';
import 'package:luvpay/core/network/http/http_request.dart';
import 'package:luvpay/features/merchant/pay_merchant.dart';
import 'package:luvpay/features/scanner_screen.dart';

import 'package:luvpay/shared/dialogs/dialogs.dart';
import '../../shared/widgets/neumorphism.dart';
import '../biller_screen/biller_screen.dart';
import '../profile/profile_screen.dart';
import '../routes/routes.dart';
import '../subwallet/controller.dart';
import '../subwallet/view.dart';
import '../wallet/notifications.dart';
import '../wallet/wallet_screen.dart';
import 'controller.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? normalizePhMobile(String input) {
    final s = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (s.isEmpty) return null;

    if (s.length == 12 && s.startsWith('63') && s[2] == '9') return s;

    if (s.length == 11 && s.startsWith('09')) return '63${s.substring(1)}';

    if (s.length == 10 && s.startsWith('9')) return '63$s';

    if (s.length >= 10) {
      final last10 = s.substring(s.length - 10);
      if (last10.startsWith('9')) return '63$last10';
    }

    return null;
  }

  bool isValidPhMobile(String? normalized) {
    if (normalized == null) return false;
    if (normalized.length != 12) return false;
    if (!normalized.startsWith('639')) return false;
    if (!RegExp(r'^639\d{9}$').hasMatch(normalized)) return false;
    return true;
  }

  final DashboardController controller = Get.put(DashboardController());
  bool _serviceBusy = false;
  bool _scanHandled = false;
  @override
  void initState() {
    super.initState();
    Get.lazyPut<SubWalletController>(() => SubWalletController());
  }

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return WalletScreen(fromTab: true);

      case 1:
        return const SubWalletScreen();

      case 2:
        return ScannerScreenV2(
          isBack: false,
          onScanStart: () async {
            controller.changePage(0);
          },
          onchanged: (args) async {
            if (_scanHandled) return;

            final raw = args.trim();
            if (raw.isEmpty) return;

            _scanHandled = true;

            try {
              final normalized = normalizePhMobile(raw);

              if (isValidPhMobile(normalized)) {
                debugPrint('PH Mobile detected: $normalized');

                controller.changePage(0);

                Get.toNamed(
                  Routes.send,
                  arguments: {"mobile": normalized, "source": "qr_scan"},
                );
                return;
              }
              final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
              if (digits.isNotEmpty &&
                  digits.length >= 10 &&
                  normalized == null) {
                CustomDialogStack.showError(
                  Get.context!,
                  "Invalid Mobile Number",
                  "Invalid mobile number format.",
                  () => Get.back(),
                );
                return;
              }

              getService(raw);
            } catch (e) {
              debugPrint("Dashboard scan error: $e");

              CustomDialogStack.showError(
                Get.context!,
                "Scan Error",
                "Something went wrong. Please try again.",
                () => Get.back(),
              );
            } finally {
              Future.delayed(const Duration(milliseconds: 1200), () {
                _scanHandled = false;
              });
            }
          },
        );

      case 3:
        return const WalletNotifications(fromTab: true);

      case 4:
        return ProfileSettingsScreen();

      default:
        return const SizedBox();
    }
  }

  Future<dynamic> getScannedQr(String apiKey) async {
    return await HttpRequestApi(api: apiKey).get();
  }

  void getService(String args) async {
    if (_serviceBusy) return;
    _serviceBusy = true;

    CustomDialogStack.showLoading(Get.context!);

    try {
      final apiBill = "${ApiKeys.postPayBills}?biller_key=$args";
      final billerResponse = await getScannedQr(apiBill);

      if (billerResponse == "No Internet") {
        _handleScanError(
          "Error",
          "Please check your internet connection and try again.",
        );
        return;
      }

      final billerItems =
          (billerResponse is Map) ? billerResponse["items"] : null;
      if (billerItems is List && billerItems.isNotEmpty) {
        _safeCloseLoading();
        Get.to(
          BillerScreen(data: billerItems, paymentHk: await getpaymentHK()),
        );
        return;
      }

      final apiMerchant = "${ApiKeys.getMerchantScan}?merchant_key=$args";
      final merchantResponse = await getScannedQr(apiMerchant);

      if (merchantResponse == "No Internet") {
        _handleScanError(
          "Error",
          "Please check your internet connection and try again.",
        );
        return;
      }

      final merchantItems =
          (merchantResponse is Map) ? merchantResponse["items"] : null;
      if (merchantItems is List && merchantItems.isNotEmpty) {
        _safeCloseLoading();
        Get.to(
          PayMerchant(
            data: [
              {
                "data": merchantItems[0],
                "merchant_key": args,
                "payment_key": await getpaymentHK(),
              },
            ],
          ),
        );
        return;
      }

      _handleScanError(
        "Invalid QR Code",
        "This QR code is not registered in the system.",
      );
    } catch (e) {
      debugPrint("getService error: $e");
      _handleScanError("Scan Error", "Something went wrong. Please try again.");
    } finally {
      _serviceBusy = false;
    }
  }

  void _safeCloseLoading() {
    while (Get.isDialogOpen == true) {
      Get.back();
    }
  }

  Future<dynamic> getpaymentHK() async {
    final userID = await Authentication().getUserId();
    final paymentKey =
        await HttpRequestApi(api: "${ApiKeys.getPaymentKey}$userID").get();

    if (paymentKey == "No Internet") {
      CustomDialogStack.showConnectionLost(Get.context!, () {
        Get.back();
      });
      return null;
    }

    if (paymentKey == null) {
      CustomDialogStack.showServerError(Get.context!, () {
        Get.back();
      });
      return null;
    }

    final items = (paymentKey is Map) ? paymentKey["items"] : null;
    if (items is List && items.isNotEmpty) {
      return items[0]["payment_hk"]?.toString();
    }

    CustomDialogStack.showServerError(Get.context!, () {
      Get.back();
    });
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final navBg = cs.surface;
    final navShadow = Colors.black.withOpacity(isDark ? 0.45 : 0.10);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
          .copyWith(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness:
                isDark ? Brightness.light : Brightness.dark,
            statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
          ),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, dynamic result) {
          CustomDialogStack.showConfirmation(
            context,
            "Close Application",
            "Are you sure you want to close application?",
            leftText: "No",
            rightText: "Yes",
            () => Get.back(),
            () {
              Get.back();
              Future.delayed(const Duration(milliseconds: 500), () {
                FlutterExitApp.exitApp(iosForceExit: true);
              });
            },
          );
        },
        child: Scaffold(
          body: PageView.builder(
            controller: controller.pageController,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 5,
            itemBuilder: (_, index) {
              return Obx(() {
                return controller.currentIndex.value == index
                    ? _buildScreen(index)
                    : const SizedBox();
              });
            },
          ),
          persistentFooterDecoration: BoxDecoration(
            color: navBg,
            border: Border(
              top: BorderSide(
                color: cs.outlineVariant.withOpacity(isDark ? 0.05 : 0.01),
                width: 0.8,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: navShadow,
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          persistentFooterButtons: [Obx(() => _buildFooterNav())],
        ),
      ),
    );
  }

  Widget _buildFooterNav() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final i = controller.currentIndex.value;

    final inactiveColor = cs.onSurface.withOpacity(isDark ? 0.65 : 0.55);

    return SafeArea(
      top: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Row(
            children: [
              Expanded(
                child: NeoNavIcon.tab(
                  size: Platform.isIOS ? 60 : 48,
                  activeIconData: Icons.home,
                  inactiveIconData: Icons.home_outlined,
                  active: i == 0,
                  inactiveColor: inactiveColor,
                  onTap: () => controller.changePage(0),
                ),
              ),
              Expanded(
                child: NeoNavIcon.tab(
                  size: Platform.isIOS ? 60 : 48,
                  activeIconData: Icons.wallet,
                  inactiveIconData: Icons.wallet_outlined,
                  active: i == 1,
                  inactiveColor: inactiveColor,
                  onTap: () => controller.changePage(1),
                ),
              ),
              Expanded(
                child: NeoNavIcon.tab(
                  size: Platform.isIOS ? 60 : 48,
                  activeIconData: Icons.qr_code,
                  inactiveIconData: Icons.qr_code_outlined,
                  active: i == 2,
                  inactiveColor: inactiveColor,
                  onTap: () => controller.changePage(2),
                ),
              ),
              Expanded(
                child: NeoNavIcon.tab(
                  size: Platform.isIOS ? 60 : 48,
                  activeIconData: Icons.notifications,
                  inactiveIconData: Icons.notifications_outlined,
                  active: i == 3,
                  onTap: () => controller.changePage(3),
                  inactiveColor: inactiveColor,
                ),
              ),
              Expanded(
                child: NeoNavIcon.tab(
                  size: Platform.isIOS ? 60 : 48,
                  activeIconData: Icons.person,
                  inactiveIconData: Icons.person_outlined,
                  active: i == 4,
                  inactiveColor: inactiveColor,
                  onTap: () => controller.changePage(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _goToWalletTab() {
    controller.changePage(0);
  }

  void _handleScanError(String title, String message) {
    _goToWalletTab();

    Future.delayed(const Duration(milliseconds: 30), () {
      if (!mounted) return;

      _safeCloseLoading();

      CustomDialogStack.showError(Get.context!, title, message, () {
        Get.back();
        Get.back();
      });
    });
  }
}
