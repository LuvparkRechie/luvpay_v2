// ignore_for_file: unused_element_parameter

import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import 'package:flutter_exit_app/flutter_exit_app.dart';
import 'package:get/get.dart';
import 'package:luvpay/auth/authentication.dart';
import 'package:luvpay/http/api_keys.dart';
import 'package:luvpay/http/http_request.dart';
import 'package:luvpay/pages/merchant/pay_merchant.dart';
import 'package:luvpay/pages/scanner_screen.dart';

import '../../custom_widgets/alert_dialog.dart';
import '../../custom_widgets/app_color_v2.dart';
import '../../custom_widgets/luvpay/dashboard_tab_icons.dart';
import '../biller_screen/biller_screen.dart';
import '../profile/profile_screen.dart';
import '../wallet/notifications.dart';
import '../wallet/wallet_screen.dart';
import 'controller.dart';
import 'refresh_wallet.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardController controller = Get.put(DashboardController());

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return WalletScreen();
      case 1:
        return const WalletNotifications(fromTab: true);
      case 2:
        return ProfileSettingsScreen();
      case 3:
        return const SizedBox();
      default:
        return const SizedBox();
    }
  }

  void _onScanPressed() {
    final result = Get.to(
      ScannerScreenV2(
        onchanged: (args) {
          if (args.isNotEmpty) {
            getService(args);
          }
        },
      ),
    );
    if (result != null) {
      WalletRefreshBus.refresher();
    }
  }

  Future<dynamic> getScannedQr(String apiKey) async {
    return await HttpRequestApi(api: apiKey).get();
  }

  void getService(String args) async {
    CustomDialogStack.showLoading(Get.context!);

    final apiBill = "${ApiKeys.postPayBills}?biller_key=$args";
    final apiMerchant = "${ApiKeys.getMerchantScan}?merchant_key=$args";

    final billerResponse = await getScannedQr(apiBill);
    if (_isValidResponse(billerResponse)) {
      Get.back();
      Get.to(
        BillerScreen(
          data: billerResponse["items"],
          paymentHk: await getpaymentHK(),
        ),
      );
      return;
    }

    final merchantResponse = await getScannedQr(apiMerchant);

    if (_isValidResponse(merchantResponse)) {
      Get.back();
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

    Get.back();
    CustomDialogStack.showError(
      Get.context!,
      "Invalid QR Code",
      "This QR code is not registered in the system.",
      () => Get.back(),
    );
  }

  bool _isValidResponse(dynamic res) {
    return res != null && res["items"] != null && res["items"].isNotEmpty;
  }

  Future<dynamic> getpaymentHK() async {
    final userID = await Authentication().getUserId();
    final res =
        await HttpRequestApi(api: "${ApiKeys.getPaymentKey}$userID").get();
    return res?["items"]?[0]?["payment_hk"];
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
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
          itemCount: 4,
          itemBuilder: (_, index) {
            return Obx(() {
              return controller.currentIndex.value == index
                  ? _buildScreen(index)
                  : const SizedBox();
            });
          },
        ),

        persistentFooterDecoration: const BoxDecoration(),
        persistentFooterButtons: [Obx(() => _buildFooterNav())],
      ),
    );
  }

  Widget _buildFooterNav() {
    final i = controller.currentIndex.value;

    final base = AppColorV2.background;
    final radius = BorderRadius.circular(28);

    return SafeArea(
      top: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: base,
              borderRadius: radius,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.55),
                  blurRadius: 10,
                  offset: const Offset(-4, -4),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(5, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: NeoNavIcon.tab(
                    activeIconData: Icons.home_rounded,
                    inactiveIconData: Icons.home_outlined,
                    active: i == 0,
                    inactiveColor: AppColorV2.bodyTextColor,
                    onTap: () => controller.changePage(0),
                  ),
                ),
                Expanded(
                  child: NeoNavIcon.icon(
                    iconData: Icons.qr_code_scanner_rounded,
                    iconColor: AppColorV2.bodyTextColor,
                    width: 30,
                    height: 30,
                    buttonSize: 54,
                    padding: const EdgeInsets.all(10),
                    borderRadius: BorderRadius.circular(18),
                    onTap: _onScanPressed,
                  ),
                ),
                Expanded(
                  child: _NotifNavItem(
                    active: i == 1,
                    count: controller.notifCount.value,
                    onTap: () => controller.changePage(1),
                    inactiveColor: AppColorV2.bodyTextColor,
                  ),
                ),
                Expanded(
                  child: NeoNavIcon.tab(
                    activeIconData: Icons.person_rounded,
                    inactiveIconData: Icons.person_outline_rounded,
                    active: i == 2,
                    inactiveColor: AppColorV2.bodyTextColor,
                    onTap: () => controller.changePage(2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotifNavItem extends StatelessWidget {
  final bool active;
  final int count;
  final VoidCallback onTap;
  final Color inactiveColor;

  const _NotifNavItem({
    required this.active,
    required this.count,
    required this.onTap,
    required this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        NeoNavIcon.tab(
          activeIconData: Icons.notifications_rounded,
          inactiveIconData: Icons.notifications_none_rounded,
          active: active,
          inactiveColor: inactiveColor,
          onTap: onTap,
        ),
        if (count > 0)
          Positioned(
            right: 12,
            top: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: AppColorV2.error,
                borderRadius: BorderRadius.circular(999),
              ),
              constraints: const BoxConstraints(minWidth: 18),
              child: Text(
                count > 99 ? "99+" : "$count",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
