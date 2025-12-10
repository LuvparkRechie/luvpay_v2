import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:luvpay/auth/authentication.dart';
import 'package:luvpay/custom_widgets/scanner.dart';
import 'package:luvpay/http/api_keys.dart';
import 'package:luvpay/pages/merchant/pay_merchant.dart';
import 'package:luvpay/pages/scanner_screen.dart';
import 'package:luvpay/pages/wallet/wallet_screen.dart';

import '../../custom_widgets/alert_dialog.dart';
import '../../custom_widgets/app_color_v2.dart';
import '../biller_screen/biller_screen.dart';
import '../profile/profile_screen.dart';
import '../qr/qr_return/scanned_qr.dart';
import '../transaction/transaction_screen.dart';
import 'controller.dart';

import 'package:luvpay/http/http_request.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  final DashboardController controller = Get.put(DashboardController());
  final List<Widget> _screens = [
    const WalletScreen(),
    const TransactionHistory(),
    const ProfileSettingsScreen(),
  ];

  late AnimationController _fabController;
  late AnimationController _bottomBarController;

  @override
  void initState() {
    super.initState();

    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
      value: 1.0,
    );

    _bottomBarController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _fabController.dispose();
    _bottomBarController.dispose();
    super.dispose();
  }

  void _handlePageChange(int index) {
    if (index == 1) {
      _fabController.reverse();
    } else {
      _fabController.forward();
    }
  }

  void _onFabPressed() {
    Get.to(
      ScannerScreenV2(
        onchanged: (args) async {
          if (args.isNotEmpty) {
            // await Get.to(() => ScannedQR(args: args));
            getService(args);
          }
        },
      ),
    );
  }

  Future<dynamic> getScannedQr(String apiKey) async {
    print("Calling API: $apiKey");
    final response = await HttpRequestApi(api: apiKey).get();
    return response;
  }

  void getService(String args) async {
    CustomDialogStack.showLoading(Get.context!);

    // API #1 and API #2
    String apiBill = "${ApiKeys.postPayBills}?biller_key=$args";
    String apiMerchant = "${ApiKeys.getMerchantScan}?merchant_key=$args";

    /// ---- TRY BILLER QR SCAN ----
    final billerResponse = await getScannedQr(apiBill);

    if (billerResponse == "No Internet") {
      _showInternetError();
      return;
    }

    if (_isValidResponse(billerResponse)) {
      String serviceName = billerResponse["items"][0]["biller_name"];
      String serviceAddress =
          billerResponse["items"][0]["biller_address"] ?? "";
      _handleSuccess(
        args,
        "biller",
        billerResponse,
        serviceName,
        serviceAddress,
      );
      return;
    }

    /// ---- TRY MERCHANT QR SCdfafdasfN ----
    final merchantResponse = await getScannedQr(apiMerchant);

    if (merchantResponse == "No Internet") {
      _showInternetError();
      return;
    }

    if (_isValidResponse(merchantResponse)) {
      String serviceName = merchantResponse["items"][0]["merchant_name"] ?? "";
      String serviceAddress =
          merchantResponse["items"][0]["merchant_address"] ?? "";
      _handleSuccess(
        args,
        "merchant",
        merchantResponse,
        serviceName,
        serviceAddress,
      );
      return;
    }

    /// ---- BOTH FAILED: INVALID QR ----
    Get.back();
    CustomDialogStack.showError(
      Get.context!,
      "Invalid QR Code",
      "This QR code is not registered in the system.",
      () {
        Get.back();
      },
    );
  }

  /// Helper to detect valid API response
  bool _isValidResponse(dynamic res) {
    if (res == null) return false;
    if (res == "Error" || res == "Failed") return false;
    if (res == "" || res == "{}" || res == "[]") return false;

    // If it's a map and contains required fields
    if (res is Map && res.isNotEmpty) return true;
    if (res is List && res.isNotEmpty) return true;

    return false;
  }

  /// Handles success response
  void _handleSuccess(
    String args,
    String type,
    dynamic response,
    serviceName,
    serviceAddress,
  ) async {
    // Navigate or handle according to type
    final paymentHk = await getpaymentHK();
    Get.back();
    if (type == "biller") {
      Get.to(BillerScreen(data: response["items"], paymentHk: paymentHk));
    } else {
      List itemData = [
        {
          "data": response["items"],
          'merchant_key': args,
          "merchant_name": serviceName,
          'merchant_address': serviceAddress,
          "payment_key": paymentHk,
        },
      ];
      Get.to(
        Scaffold(
          backgroundColor: AppColorV2.background,
          appBar: AppBar(
            elevation: 1,
            backgroundColor: AppColorV2.lpBlueBrand,
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarColor: AppColorV2.lpBlueBrand,
              statusBarBrightness: Brightness.dark,
              statusBarIconBrightness: Brightness.light,
            ),
            title: Text("Pay Merchant"),
            centerTitle: true,
            leading: IconButton(
              onPressed: () {
                Get.back();
              },
              icon: Icon(Iconsax.arrow_left, color: Colors.white),
            ),
          ),
          body: PayMerchant(data: itemData),
        ),
      );
    }
  }

  /// Common internet error dialog
  void _showInternetError() {
    Get.back();
    CustomDialogStack.showError(
      Get.context!,
      "Error",
      "Please check your internet connection and try again.",
      () {
        Get.back();
      },
    );
  }

  Future<dynamic> getpaymentHK() async {
    // CustomDialogStack.showLoading(Get.context!);
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
    if (paymentKey["items"].isNotEmpty) {
      print("diri ${paymentKey["items"][0]["payment_hk"]}");
      return paymentKey["items"][0]["payment_hk"].toString();
    } else {
      CustomDialogStack.showServerError(Get.context!, () {
        Get.back();
      });

      return null;
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: controller.pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: _handlePageChange,
            children:
                _screens.map((screen) {
                  return NotificationListener<UserScrollNotification>(
                    onNotification: (n) {
                      _handleScroll(n);
                      return false;
                    },
                    child: screen,
                  );
                }).toList(),
          ),

          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: AnimatedBuilder(
              animation: _bottomBarController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 70 * (1 - _bottomBarController.value)),
                  child: Opacity(
                    opacity: _bottomBarController.value,
                    child: child,
                  ),
                );
              },
              child: Obx(
                () => Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            controller.changePage(0);
                            _handlePageChange(0);
                          },
                          child: Icon(
                            LucideIcons.home,
                            size: 24,
                            color:
                                controller.currentIndex.value == 0
                                    ? AppColorV2.lpBlueBrand
                                    : AppColorV2.bodyTextColor,
                          ),
                        ),
                      ),

                      const SizedBox(width: 60),

                      Expanded(
                        child: InkWell(
                          onTap: () {
                            controller.changePage(2);
                            _handlePageChange(2);
                          },
                          child: Icon(
                            LucideIcons.user,
                            size: 24,
                            color:
                                controller.currentIndex.value == 2
                                    ? AppColorV2.lpBlueBrand
                                    : AppColorV2.bodyTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            left: MediaQuery.of(context).size.width / 2 - 30,
            bottom: 30,
            child: AnimatedBuilder(
              animation: _fabController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _fabController.value,
                  child: Opacity(
                    opacity: _fabController.value,
                    child: FloatingActionButton(
                      onPressed: _onFabPressed,
                      backgroundColor: AppColorV2.lpBlueBrand,
                      elevation: 6,
                      highlightElevation: 12,
                      child: const Icon(
                        Icons.qr_code_scanner_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
