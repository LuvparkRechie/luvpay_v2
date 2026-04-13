// ignore_for_file: unused_element_parameter, deprecated_member_use

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_exit_app/flutter_exit_app.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
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
import '../wallet/transaction/transaction_screen.dart';
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

  final DashboardController controller = Get.find<DashboardController>();
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
        return Scaffold(
          body: SizedBox.shrink(),
        );

      case 3:
        return const TransactionHistory(fromTab: true);

      case 4:
        return ProfileSettingsScreen(
          fromBuildHeader: false,
        );

      default:
        return const SizedBox();
    }
  }

  Future<dynamic> getScannedQr(String apiKey) async {
    return await HttpRequestApi(api: apiKey).get();
  }

  Future<void> getService(String args) async {
    if (_serviceBusy) return;
    _serviceBusy = true;

    CustomDialogStack.showLoading(Get.context!);

    try {
      final apiBill = "${ApiKeys.postPayBills}?biller_key=$args";
      final billerResponse = await getScannedQr(apiBill);
      Get.back();
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
        Get.back();
        final resBill = await Get.to(
          BillerScreen(data: billerItems, paymentHk: await getpaymentHK()),
        );

        controller.changePage(0);
        debugPrint("resBill : $resBill");
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

      if (merchantResponse != null) {
        _safeCloseLoading();
        Get.to(
          PayMerchant(
            data: [
              {
                "data": merchantResponse["items"][0],
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
      Get.back();
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
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
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
            body: Stack(children: [
              PageView.builder(
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
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Obx(() => _buildFooterNav()),
              ),
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom +
                    (Platform.isIOS ? 45 : 35),
                left: MediaQuery.of(context).size.width / 2 - 32,
                child: _buildFloatingQR(),
              ),
            ]),
          )),
    );
  }

  Widget _buildFloatingQR() {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () {
        Get.to(ScannerScreenV2(
          isBack: true,
          onScanStart: () {},
          onchanged: (args) async {
            if (_scanHandled) return;

            final raw = args.trim();
            if (raw.isEmpty) return;

            _scanHandled = true;

            try {
              final normalized = normalizePhMobile(raw);

              if (isValidPhMobile(normalized)) {
                Get.back();
                await Get.toNamed(
                  Routes.send,
                  arguments: {"mobile": normalized, "source": "qr_scan"},
                );
                return;
              }

              await getService(raw);
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
        ));
      },
      child: Container(
        height: 64,
        width: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [
              Color(0xFF0EA5E9),
              Color(0xFF22D3EE),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.cyan.withOpacity(0.6),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Icon(
          LucideIcons.qrCode,
          size: 32,
          color: cs.surface,
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
          child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.45 : 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: NeoNavIcon.tab(
                      borderRadius: BorderRadius.circular(40),
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
                      borderRadius: BorderRadius.circular(40),
                      size: Platform.isIOS ? 60 : 48,
                      activeIconData: Icons.wallet,
                      inactiveIconData: Icons.wallet_outlined,
                      active: i == 1,
                      inactiveColor: inactiveColor,
                      onTap: () => controller.changePage(1),
                    ),
                  ),
                  const SizedBox(width: 60),
                  Expanded(
                    child: NeoNavIcon.tab(
                      borderRadius: BorderRadius.circular(40),
                      size: Platform.isIOS ? 60 : 48,
                      activeIconData: Icons.history,
                      inactiveIconData: Icons.history_outlined,
                      active: i == 3,
                      onTap: () => controller.changePage(3),
                      inactiveColor: inactiveColor,
                    ),
                  ),
                  Expanded(
                    child: NeoNavIcon.tab(
                      borderRadius: BorderRadius.circular(40),
                      size: Platform.isIOS ? 60 : 48,
                      activeIconData: Icons.person,
                      inactiveIconData: Icons.person_outlined,
                      active: i == 4,
                      inactiveColor: inactiveColor,
                      onTap: () => controller.changePage(4),
                    ),
                  ),
                ],
              )),
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
