// ignore_for_file: unused_element_parameter

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_exit_app/flutter_exit_app.dart';
import 'package:get/get.dart';
import 'package:luvpay/auth/authentication.dart';
import 'package:luvpay/http/api_keys.dart';
import 'package:luvpay/http/http_request.dart';
import 'package:luvpay/pages/merchant/pay_merchant.dart';
import 'package:luvpay/pages/scanner_screen.dart';

import '../../custom_widgets/alert_dialog.dart';
import '../../custom_widgets/luvpay/neumorphism.dart';
import '../biller_screen/biller_screen.dart';
import '../profile/profile_screen.dart';
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
  final DashboardController controller = Get.put(DashboardController());
  bool _serviceBusy = false;

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
          onScanStart: () {
            controller.changePage(0);
          },
          onchanged: (args) {
            if (args.isNotEmpty) getService(args);
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
                color: cs.outlineVariant.withOpacity(isDark ? 0.55 : 0.01),
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
          persistentFooterButtons: [
            Obx(
              () => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: _buildFooterNav(),
              ),
            ),
          ],
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
                  activeIconData: Icons.home,
                  inactiveIconData: Icons.home_outlined,
                  active: i == 0,
                  inactiveColor: inactiveColor,
                  onTap: () => controller.changePage(0),
                ),
              ),
              Expanded(
                child: NeoNavIcon.tab(
                  activeIconData: Icons.wallet,
                  inactiveIconData: Icons.wallet_outlined,
                  active: i == 1,
                  inactiveColor: inactiveColor,
                  onTap: () => controller.changePage(1),
                ),
              ),
              Expanded(
                child: NeoNavIcon.tab(
                  activeIconData: Icons.qr_code,
                  inactiveIconData: Icons.qr_code_outlined,
                  active: i == 2,
                  inactiveColor: inactiveColor,
                  onTap: () => controller.changePage(2),
                ),
              ),
              Expanded(
                child: NeoNavIcon.tab(
                  activeIconData: Icons.notifications,
                  inactiveIconData: Icons.notifications_outlined,
                  active: i == 3,
                  onTap: () => controller.changePage(3),
                  inactiveColor: inactiveColor,
                ),
              ),
              Expanded(
                child: NeoNavIcon.tab(
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
