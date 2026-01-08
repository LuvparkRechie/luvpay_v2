import 'package:flutter/material.dart';
import 'package:get/get.dart';

class VouchersController extends GetxController
    with GetSingleTickerProviderStateMixin {
  late TabController tabController;
  final List<String> tabTitles = ['Vouchers', 'Used', 'Expired'];

  final RxList<Voucher> availableVouchers =
      <Voucher>[
        Voucher(
          id: '1',
          title: 'Welcome Bonus',
          description: 'Get 20% off on your first purchase',
          code: 'WELCOME20',
          discount: '20%',
          expiryDate: DateTime.now().add(const Duration(days: 30)),
          isUsed: false,
        ),
        Voucher(
          id: '2',
          title: 'Free Shipping',
          description: 'Free shipping on orders above \$50',
          code: 'FREESHIP',
          discount: 'Free Shipping',
          expiryDate: DateTime.now().add(const Duration(days: 15)),
          isUsed: false,
        ),
        Voucher(
          id: '3',
          title: 'Weekend Special',
          description: '15% off on weekend purchases',
          code: 'WEEKEND15',
          discount: '15%',
          expiryDate: DateTime.now().add(const Duration(days: 7)),
          isUsed: false,
        ),
      ].obs;

  final RxList<Voucher> usedVouchers =
      <Voucher>[
        Voucher(
          id: '4',
          title: 'Spring Sale',
          description: '25% off on seasonal items',
          code: 'SPRING25',
          discount: '25%',
          expiryDate: DateTime.now().add(const Duration(days: -10)),
          isUsed: true,
          usedDate: DateTime.now().subtract(const Duration(days: 5)),
        ),
      ].obs;

  final RxList<Voucher> expiredVouchers =
      <Voucher>[
        Voucher(
          id: '5',
          title: 'New Year Sale',
          description: '30% off on all items',
          code: 'NEWYEAR30',
          discount: '30%',
          expiryDate: DateTime.now().subtract(const Duration(days: 30)),
          isUsed: false,
        ),
        Voucher(
          id: '6',
          title: 'Black Friday',
          description: '40% off on selected items',
          code: 'BLACK40',
          discount: '40%',
          expiryDate: DateTime.now().subtract(const Duration(days: 15)),
          isUsed: false,
        ),
      ].obs;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: tabTitles.length, vsync: this);
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }

  void useVoucher(String voucherId) {
    final voucher = availableVouchers.firstWhere((v) => v.id == voucherId);
    voucher.isUsed = true;
    voucher.usedDate = DateTime.now();

    availableVouchers.remove(voucher);
    usedVouchers.insert(0, voucher);
    update();
  }

  void copyToClipboard(String code) {
    // This would typically use clipboard package
    Get.snackbar(
      'Copied!',
      'Voucher code "$code" copied to clipboard',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}

class Voucher {
  final String id;
  final String title;
  final String description;
  final String code;
  final String discount;
  final DateTime expiryDate;
  bool isUsed;
  DateTime? usedDate;

  Voucher({
    required this.id,
    required this.title,
    required this.description,
    required this.code,
    required this.discount,
    required this.expiryDate,
    required this.isUsed,
    this.usedDate,
  });

  bool get isExpired => expiryDate.isBefore(DateTime.now());

  String get formattedExpiryDate {
    final now = DateTime.now();
    final difference = expiryDate.difference(now);

    if (difference.inDays > 30) {
      return 'Expires ${expiryDate.day}/${expiryDate.month}/${expiryDate.year}';
    } else if (difference.inDays > 0) {
      return 'Expires in ${difference.inDays} days';
    } else if (difference.inHours > 0) {
      return 'Expires in ${difference.inHours} hours';
    } else {
      return 'Expired';
    }
  }

  String get formattedUsedDate {
    if (usedDate == null) return '';
    final difference = DateTime.now().difference(usedDate!);

    if (difference.inDays > 0) {
      return 'Used ${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return 'Used ${difference.inHours} hours ago';
    } else {
      return 'Used recently';
    }
  }
}
