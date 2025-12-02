import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:luvpay/custom_widgets/scanner.dart';
import 'package:luvpay/pages/wallet/wallet_screen.dart';

import '../../custom_widgets/app_color_v2.dart';
import '../profile/profile_screen.dart';
import '../qr/qr_return/scanned_qr.dart';
import '../transaction/transaction_screen.dart';
import 'controller.dart';

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
    showDialog(
      context: context,
      builder: (context) {
        return ScannerScreen(
          onchanged: (args) async {
            if (args != null && args is String) {
              await Get.to(() => ScannedQR(args: args));
            }
          },
        );
      },
    );
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
