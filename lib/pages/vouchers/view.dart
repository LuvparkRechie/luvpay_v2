import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luvpay/custom_widgets/app_color_v2.dart';
import 'package:luvpay/custom_widgets/custom_text_v2.dart';
import 'package:luvpay/custom_widgets/luvpay/custom_scaffold.dart';
import 'controller.dart';

class Vouchers extends StatefulWidget {
  const Vouchers({super.key});

  @override
  State<Vouchers> createState() => _VouchersState();
}

class _VouchersState extends State<Vouchers> {
  final VouchersController controller = Get.put(VouchersController());

  @override
  Widget build(BuildContext context) {
    return CustomScaffoldV2(
      padding: EdgeInsets.zero,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TabBar(
            physics: BouncingScrollPhysics(),
            controller: controller.tabController,
            indicatorColor: AppColorV2.background,
            labelColor: AppColorV2.background,
            unselectedLabelColor: AppColorV2.inactiveButton,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            tabs:
                controller.tabTitles.map((title) => Tab(text: title)).toList(),
          ),
        ),
      ),
      appBarTitle: 'My Vouchers',
      scaffoldBody: TabBarView(
        physics: BouncingScrollPhysics(),
        controller: controller.tabController,
        children: [
          _buildVouchersList(controller.availableVouchers),
          _buildVouchersList(controller.usedVouchers),
          _buildVouchersList(controller.expiredVouchers),
        ],
      ),
    );
  }

  Widget _buildVouchersList(RxList<Voucher> vouchers) {
    return Obx(() {
      if (vouchers.isEmpty) {
        return Center(
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.confirmation_num_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                DefaultText(
                  text: 'No vouchers available',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        );
      }

      return ListView.builder(
        physics: BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: vouchers.length,
        itemBuilder: (context, index) {
          return _buildVoucherCard(vouchers[index]);
        },
      );
    });
  }

  Widget _buildVoucherCard(Voucher voucher) {
    final isAvailable = !voucher.isUsed && !voucher.isExpired;
    final isUsed = voucher.isUsed;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Voucher header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  isAvailable
                      ? Theme.of(context).primaryColor.withOpacity(0.1)
                      : Colors.grey[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                // Discount badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isAvailable
                            ? Theme.of(context).primaryColor
                            : Colors.grey,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: DefaultText(
                    text: voucher.discount,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const Spacer(),
                // Status indicator
                if (isUsed)
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green[400],
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      DefaultText(
                        text: 'Used',
                        style: TextStyle(
                          color: Colors.green[400],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  )
                else if (voucher.isExpired)
                  Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red[400],
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      DefaultText(
                        text: 'Expired',
                        style: TextStyle(
                          color: Colors.red[400],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: Theme.of(context).primaryColor,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      DefaultText(
                        text: voucher.formattedExpiryDate,
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Voucher content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DefaultText(
                  text: voucher.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                DefaultText(
                  text: voucher.description,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      DefaultText(
                        text: voucher.code,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const Spacer(),
                      if (isAvailable)
                        GestureDetector(
                          onTap: () => controller.copyToClipboard(voucher.code),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const DefaultText(
                              text: 'COPY',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                if (isUsed && voucher.usedDate != null)
                  DefaultText(
                    text: voucher.formattedUsedDate,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),

                if (!isUsed && !voucher.isExpired)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => controller.useVoucher(voucher.id),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).primaryColor,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          DefaultText(text: 'Use Now'),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward, size: 16),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
