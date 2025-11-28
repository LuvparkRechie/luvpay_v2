// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:lucide_icons/lucide_icons.dart';
// import 'package:luvpay/custom_widgets/scanner.dart';
// import 'package:luvpay/pages/wallet/wallet_screen.dart';

// import '../../custom_widgets/app_color_v2.dart';
// import '../profile/profile_screen.dart';
// import '../qr/qr_return/scanned_qr.dart';
// import '../scanner_screen.dart';
// import '../transaction/transaction_screen.dart';
// import 'controller.dart';

// class DashboardScreen extends StatefulWidget {
//   const DashboardScreen({super.key});

//   @override
//   State<DashboardScreen> createState() => _DashboardScreenState();
// }

// class _DashboardScreenState extends State<DashboardScreen>
//     with SingleTickerProviderStateMixin {
//   final DashboardController controller = Get.put(DashboardController());
//   final List<Widget> _screens = [
//     const WalletScreen(),
//     const TransactionHistory(),
//     const ProfileSettingsScreen(),
//   ];

//   late AnimationController _fabAnimationController;

//   @override
//   void initState() {
//     super.initState();

//     _fabAnimationController = AnimationController(
//       duration: const Duration(milliseconds: 350),
//       vsync: this,
//     );

//     if (controller.currentIndex.value != 1) {
//       _fabAnimationController.forward();
//     }
//   }

//   @override
//   void dispose() {
//     _fabAnimationController.dispose();
//     super.dispose();
//   }

//   void _handlePageChange(int index) {
//     if (index == 1) {
//       _fabAnimationController.reverse();
//     } else {
//       _fabAnimationController.forward();
//     }
//   }

//   void _onFabPressed() {
//     showDialog(
//       context: context,
//       builder: (context) {
//         return ScannerScreen(
//           onchanged: (args) async {
//             if (args != null && args is String) {
//               await Get.to(() => ScannedQR(args: args));
//             }
//           },
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: PageView(
//         controller: controller.pageController,
//         physics: const NeverScrollableScrollPhysics(),
//         onPageChanged: _handlePageChange,
//         children: _screens,
//       ),
//       floatingActionButton: AnimatedBuilder(
//         animation: _fabAnimationController,
//         builder: (context, child) {
//           return Transform.scale(
//             scale: _fabAnimationController.value,
//             child: Opacity(
//               opacity: _fabAnimationController.value,
//               child: FloatingActionButton(
//                 onPressed: _onFabPressed,
//                 backgroundColor: AppColorV2.lpBlueBrand,
//                 elevation: 6,
//                 highlightElevation: 12,
//                 child: const Icon(
//                   Icons.qr_code_scanner_rounded,
//                   color: Colors.white,
//                   size: 24,
//                 ),
//               ),
//             ),
//           );
//         },
//       ),
//       floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
//       bottomNavigationBar: Obx(
//         () => BottomNavigationBar(
//           currentIndex: controller.currentIndex.value,
//           onTap: (index) {
//             controller.changePage(index);
//             _handlePageChange(index);
//           },
//           type: BottomNavigationBarType.fixed,
//           backgroundColor: Colors.white,
//           selectedItemColor: AppColorV2.lpBlueBrand,
//           unselectedItemColor: AppColorV2.bodyTextColor,
//           selectedLabelStyle: const TextStyle(
//             fontWeight: FontWeight.w600,
//             fontSize: 12,
//           ),
//           unselectedLabelStyle: const TextStyle(
//             fontWeight: FontWeight.w500,
//             fontSize: 12,
//           ),
//           items: const [
//             BottomNavigationBarItem(
//               icon: Icon(LucideIcons.home),
//               activeIcon: Icon(LucideIcons.home, size: 24),
//               label: 'Home',
//             ),
//             BottomNavigationBarItem(
//               icon: Icon(LucideIcons.history),
//               activeIcon: Icon(LucideIcons.history, size: 24),
//               label: 'Transaction',
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:luvpay/custom_widgets/scanner.dart';
import 'package:luvpay/pages/wallet/wallet_screen.dart';

import '../../custom_widgets/app_color_v2.dart';
import '../profile/profile_screen.dart';
import '../qr/qr_return/scanned_qr.dart';
import '../scanner_screen.dart';
import '../transaction/transaction_screen.dart';
import 'controller.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  final DashboardController controller = Get.put(DashboardController());
  final List<Widget> _screens = [
    const WalletScreen(),
    const TransactionHistory(),
    const ProfileSettingsScreen(),
  ];

  late AnimationController _fabAnimationController;

  @override
  void initState() {
    super.initState();

    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    if (controller.currentIndex.value != 1) {
      _fabAnimationController.forward();
    }
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _handlePageChange(int index) {
    if (index == 1) {
      _fabAnimationController.reverse();
    } else {
      _fabAnimationController.forward();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: controller.pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: _handlePageChange,
            children: _screens,
          ),

          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
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
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          controller.changePage(0);
                          _handlePageChange(0);
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.home,
                              size: 24,
                              color:
                                  controller.currentIndex.value == 0
                                      ? AppColorV2.lpBlueBrand
                                      : AppColorV2.bodyTextColor,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Home',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color:
                                    controller.currentIndex.value == 0
                                        ? AppColorV2.lpBlueBrand
                                        : AppColorV2.bodyTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 60),

                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          controller.changePage(2);
                          _handlePageChange(2);
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.user,
                              size: 24,
                              color:
                                  controller.currentIndex.value == 2
                                      ? AppColorV2.lpBlueBrand
                                      : AppColorV2.bodyTextColor,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Profile',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color:
                                    controller.currentIndex.value == 2
                                        ? AppColorV2.lpBlueBrand
                                        : AppColorV2.bodyTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            left: MediaQuery.of(context).size.width / 2 - 30,
            bottom: 30,
            child: AnimatedBuilder(
              animation: _fabAnimationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _fabAnimationController.value,
                  child: Opacity(
                    opacity: _fabAnimationController.value,
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
