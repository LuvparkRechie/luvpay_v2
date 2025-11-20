import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:luvpay/custom_widgets/app_color_v2.dart';
import '../cars/cards_screen.dart';
import '../profile/profile_screen.dart';
import '../transaction/transaction_screen.dart';
import '../wallet/wallet_screen.dart';
import 'controller.dart';

class DashboardScreen extends GetView<DashboardController> {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(DashboardController());
    return Scaffold(
      backgroundColor: AppColorV2.background,

      body: PageView(
        controller: controller.pageController,
        onPageChanged: null,
        physics: NeverScrollableScrollPhysics(),
        children: const [
          WalletScreen(),
          TransactionScreen(),
          CardScreen(),
          ProfileSettingsScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.account_balance_wallet, 'Home', 0),
              _buildNavItem(Icons.analytics_outlined, 'Transaction', 1),

              _buildNavItem(Icons.credit_card, 'Card', 2),
              _buildNavItem(Icons.person_outline, 'Profile', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    return Obx(
      () => InkWell(
        onTap: () => controller.onPageChanged(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color:
                  index == controller.pageIndex.value
                      ? AppColorV2.primary
                      : AppColorV2.onSurfaceVariant,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight:
                    index == controller.pageIndex.value
                        ? FontWeight.w600
                        : FontWeight.w400,
                color:
                    index == controller.pageIndex.value
                        ? AppColorV2.primary
                        : AppColorV2.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
