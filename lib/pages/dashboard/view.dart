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

  @override
  void initState() {
    super.initState();
    Get.lazyPut<SubWalletController>(() => SubWalletController());
  }

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return WalletScreen();

      case 1:
        return const SubWalletScreen();
      case 2:
        return ScannerScreenV2(
          onchanged: (args) {
            if (args.isNotEmpty) {
              getService(args);
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
          itemCount: 5,
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
                  inactiveColor: AppColorV2.bodyTextColor,
                  onTap: () => controller.changePage(0),
                ),
              ),
              Expanded(
                child: NeoNavIcon.tab(
                  activeIconData: Icons.account_balance_wallet_rounded,
                  inactiveIconData: Icons.account_balance_wallet_outlined,
                  active: i == 1,
                  inactiveColor: AppColorV2.bodyTextColor,
                  onTap: () => controller.changePage(1),
                ),
              ),

              Expanded(
                child: NeoNavIcon.tab(
                  activeIconData: Icons.qr_code_scanner_rounded,
                  inactiveIconData: Icons.qr_code_scanner_outlined,
                  active: i == 2,
                  inactiveColor: AppColorV2.bodyTextColor,
                  onTap: () => controller.changePage(2),
                ),
              ),

              Expanded(
                child: _NotifNavItem(
                  active: i == 3,
                  count: controller.notifCount.value,
                  onTap: () => controller.changePage(3),
                  inactiveColor: AppColorV2.bodyTextColor,
                ),
              ),

              Expanded(
                child: NeoNavIcon.tab(
                  activeIconData: Icons.person_rounded,
                  inactiveIconData: Icons.person_outline_rounded,
                  active: i == 4,
                  inactiveColor: AppColorV2.bodyTextColor,
                  onTap: () => controller.changePage(4),
                ),
              ),
            ],
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
