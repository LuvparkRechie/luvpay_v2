// ignore_for_file: unused_element_parameter

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_exit_app/flutter_exit_app.dart';
import 'package:get/get.dart';
import 'package:luvpay/auth/authentication.dart';
import 'package:luvpay/http/api_keys.dart';
import 'package:luvpay/http/http_request.dart';
import 'package:luvpay/pages/merchant/pay_merchant.dart';
import 'package:luvpay/pages/scanner_screen.dart';

import '../../custom_widgets/alert_dialog.dart';
import '../../custom_widgets/app_color_v2.dart';
import '../biller_screen/biller_screen.dart';
import '../profile/profile_screen.dart';
import '../wallet/wallet_screen.dart';
import 'controller.dart';
import 'refresh_wallet.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  final DashboardController controller = Get.put(DashboardController());

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return WalletScreen();
      case 1:
        return const SizedBox();
      case 2:
        return ProfileSettingsScreen();
      default:
        return const SizedBox();
    }
  }

  late final AnimationController _bottomBarController;

  @override
  void initState() {
    super.initState();
    _bottomBarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
      value: 1,
    );
  }

  @override
  void dispose() {
    _bottomBarController.dispose();
    super.dispose();
  }

  void _handleScroll(UserScrollNotification n) {
    if (n.direction == ScrollDirection.reverse) {
      _bottomBarController.reverse();
    } else if (n.direction == ScrollDirection.forward) {
      _bottomBarController.forward();
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
        body: Stack(
          children: [
            PageView.builder(
              controller: controller.pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              itemBuilder: (_, index) {
                return NotificationListener<UserScrollNotification>(
                  onNotification: (n) {
                    _handleScroll(n);
                    return false;
                  },
                  child: Obx(() {
                    return controller.currentIndex.value == index
                        ? _buildScreen(index)
                        : const SizedBox();
                  }),
                );
              },
            ),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: AnimatedBuilder(
        animation: _bottomBarController,
        builder: (_, child) {
          return Transform.translate(
            offset: Offset(0, 80 * (1 - _bottomBarController.value)),
            child: Opacity(opacity: _bottomBarController.value, child: child),
          );
        },
        child: Obx(() {
          final i = controller.currentIndex.value;

          final base = AppColorV2.background;
          final radius = BorderRadius.circular(28);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
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
                    child: _NeoNavIcon(
                      activeIconName: "luvpay_home",
                      inactiveIconName: "luvpay_home_inactive",
                      active: i == 0,
                      onTap: () => controller.changePage(0),
                    ),
                  ),
                  Expanded(
                    child: _NeoNavIcon(
                      activeIconName: "luvpay_qr_button",
                      inactiveIconName: "luvpay_qr_button",
                      active: false,
                      height: 40,
                      width: 40,
                      onTap: _onScanPressed,
                    ),
                  ),
                  Expanded(
                    child: _NeoNavIcon(
                      activeIconName: "luvpay_profile",
                      inactiveIconName: "luvpay_profile_inactive",
                      active: i == 2,
                      onTap: () => controller.changePage(2),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _NeoNavIcon extends StatefulWidget {
  final String activeIconName;
  final String inactiveIconName;
  final bool active;
  final VoidCallback onTap;
  final double? width;
  final double? height;

  const _NeoNavIcon({
    required this.activeIconName,
    required this.inactiveIconName,
    required this.active,
    required this.onTap,
    this.width,
    this.height,
  });

  @override
  State<_NeoNavIcon> createState() => _NeoNavIconState();
}

class _NeoNavIconState extends State<_NeoNavIcon> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final base = AppColorV2.background;
    final activeColor = AppColorV2.lpBlueBrand;

    final r = BorderRadius.circular(18);

    final iconName =
        widget.active ? widget.activeIconName : widget.inactiveIconName;

    final iconW = widget.width ?? 26;
    final iconH = widget.height ?? 26;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: base,
            borderRadius: r,
            border: Border.all(
              color:
                  widget.active
                      ? activeColor.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.010),
            ),
            boxShadow:
                widget.active
                    ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.07),
                        blurRadius: 6,
                        offset: const Offset(3, 3),
                      ),
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.60),
                        blurRadius: 6,
                        offset: const Offset(-3, -3),
                      ),
                    ]
                    : [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.60),
                        blurRadius: 8,
                        offset: const Offset(-4, -4),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 9,
                        offset: const Offset(4, 4),
                      ),
                    ],
          ),
          child: Center(
            child: Image.asset(
              "assets/images/$iconName.png",
              width: iconW,
              height: iconH,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
