import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:luvpay/custom_widgets/scanner.dart';
import 'package:luvpay/pages/wallet/wallet_screen.dart';

import '../profile/profile_screen.dart';
import '../qr/qr_return/scanned_qr.dart';
import '../transaction/transaction_screen.dart';
import 'controller.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardController controller = Get.put(DashboardController());

  final List<Widget> _screens = [
    const WalletScreen(),
    const TransactionHistory(),
    ScannerScreen(
      onchanged: (args) async {
        if (args != null && args is String) {
          await Get.to(() => ScannedQR(args: args));
        }
      },
    ),
    const ProfileSettingsScreen(),
  ];

  @override
  void dispose() {
    controller.pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: controller.pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: _screens,
        onPageChanged: (index) {
          controller.currentIndex.value = index;
        },
      ),
      bottomNavigationBar: Obx(
        () => BottomNavigationBar(
          currentIndex: controller.currentIndex.value,
          onTap: (index) {
            controller.changePage(index);
          },
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(LucideIcons.home), label: ''),
            BottomNavigationBarItem(icon: Icon(LucideIcons.history), label: ''),
            BottomNavigationBarItem(icon: Icon(LucideIcons.qrCode), label: ''),
            BottomNavigationBarItem(icon: Icon(LucideIcons.user), label: ''),
          ],
        ),
      ),
    );
  }
}
