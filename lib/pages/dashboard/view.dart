import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_exit_app/flutter_exit_app.dart';
import 'package:get/get.dart';
import 'package:luvpay/auth/authentication.dart';
import 'package:luvpay/http/api_keys.dart';
import 'package:luvpay/pages/merchant/pay_merchant.dart';
import 'package:luvpay/pages/scanner_screen.dart';

import '../../custom_widgets/alert_dialog.dart';
import '../biller_screen/biller_screen.dart';
import '../profile/profile_screen.dart';
import '../wallet/wallet_screen.dart';
import 'controller.dart';
import 'package:luvpay/http/http_request.dart';

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
        return ProfileSettingsScreen();
      default:
        return const SizedBox();
    }
  }

  late final AnimationController _bottomBarController;
  late final AnimationController _fabController;

  @override
  void initState() {
    super.initState();

    _bottomBarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: 1,
    );

    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: 1,
    );
  }

  @override
  void dispose() {
    _bottomBarController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  void _handleScroll(UserScrollNotification n) {
    if (n.direction == ScrollDirection.reverse) {
      _bottomBarController.reverse();
      _fabController.reverse();
    } else if (n.direction == ScrollDirection.forward) {
      _bottomBarController.forward();
      _fabController.forward();
    }
  }

  void _onFabPressed() {
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
          () {
            Get.back();
          },
          () {
            Get.back();
            Future.delayed(Duration(milliseconds: 500), () {
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
              itemCount: 2,
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
            // _buildQrFab(context),
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
            offset: Offset(0, 70 * (1 - _bottomBarController.value)),
            child: Opacity(opacity: _bottomBarController.value, child: child),
          );
        },
        child: Obx(
          () => Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 100,
                width: 280,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  image: DecorationImage(
                    fit: BoxFit.fill,
                    image: AssetImage("assets/images/luvpay_bottom_bg.png"),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 30, left: 30, right: 30),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _navIcon(
                        controller.currentIndex.value == 0
                            ? "luvpay_home"
                            : "luvpay_home_inactive",
                        0,
                      ),

                      _navIcon(
                        controller.currentIndex.value == 1
                            ? "luvpay_profile"
                            : "luvpay_profile_inactive",
                        1,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 15,
                left: 0,
                right: 0,
                child: AnimatedBuilder(
                  animation: _fabController,
                  builder: (_, child) {
                    return Transform.translate(
                      offset: Offset(0, 70 * (1 - _fabController.value)),
                      child: Opacity(
                        opacity: _fabController.value,
                        child: child,
                      ),
                    );
                  },
                  child: Center(
                    child: GestureDetector(
                      onTap: _onFabPressed,
                      child: Image.asset(
                        "assets/images/luvpay_qr_button.png",
                        height: 75,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navIcon(String icon, int index) {
    return InkWell(
      onTap: () {
        controller.changePage(index);
      },
      child: Image.asset("assets/images/$icon.png", height: 25),
    );
  }
}
