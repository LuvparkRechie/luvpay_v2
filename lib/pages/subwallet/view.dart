// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:async';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:luvpay/custom_widgets/alert_dialog.dart';
import 'package:luvpay/custom_widgets/luvpay/custom_scaffold.dart';
import '../../custom_widgets/app_color_v2.dart';
import '../../custom_widgets/custom_text_v2.dart';
import 'controller.dart';
import 'utils/add_wallet_modal.dart';
import 'utils/wallet_Details.dart';

enum WalletModalMode { create, edit }

enum TransferType { toSubwallet, toMain }

class Wallet {
  final String id;
  final String userId;
  final String categoryId;
  final String name;
  final double balance;
  final String category;
  final String? iconBase64;
  final Color color;
  final String createdOn;
  final String updatedOn;
  final String isActive;
  final String categoryTitle;
  final String? imageBase64;
  final double? targetAmount;

  Wallet({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.name,
    required this.balance,
    required this.category,
    required this.iconBase64,
    required this.color,
    required this.createdOn,
    required this.updatedOn,
    required this.isActive,
    required this.categoryTitle,
    required this.imageBase64,
    this.targetAmount,
  });

  Wallet copyWith({String? name, double? balance, double? targetAmount}) {
    return Wallet(
      id: id,
      userId: userId,
      categoryId: categoryId,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      category: category,
      iconBase64: iconBase64,
      color: color,
      createdOn: createdOn,
      updatedOn: updatedOn,
      isActive: isActive,
      categoryTitle: categoryTitle,
      imageBase64: imageBase64,
      targetAmount: targetAmount ?? this.targetAmount,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'category_id': categoryId,
    'name': name,
    'balance': balance,
    'category': category,
    'icon_base64': iconBase64,
    'color': color.value,
    'created_on': createdOn,
    'updated_on': updatedOn,
    'is_active': isActive,
    'category_title': categoryTitle,
    'image_base64': imageBase64,
    'targetAmount': targetAmount,
  };
  static Color getColorFromString(String colorString) {
    switch (colorString.toLowerCase()) {
      case 'blue':
      case 'lpbluebrand':
        return AppColorV2.lpBlueBrand;
      case 'secondary':
        return AppColorV2.secondary;
      case 'accent':
        return AppColorV2.accent;
      case 'teal':
      case 'lptealbrand':
        return AppColorV2.lpTealBrand;
      case 'success':
        return AppColorV2.success;
      case 'warning':
        return AppColorV2.warning;
      case 'correct':
      case 'correctstate':
        return AppColorV2.correctState;
      case 'mint':
      case 'darkmintaccent':
        return AppColorV2.darkMintAccent;
      default:
        return AppColorV2.lpBlueBrand;
    }
  }

  Color onColor(Color bg) =>
      ThemeData.estimateBrightnessForColor(bg) == Brightness.dark
          ? Colors.white
          : Colors.black;

  Color tint(Color c, [double opacity = 0.10]) => c.withOpacity(opacity);

  Color stroke(Color c, [double opacity = 0.25]) => c.withOpacity(opacity);

  LinearGradient softGradient(Color c) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [c.withOpacity(0.18), c.withOpacity(0.06)],
  );

  factory Wallet.fromJson(Map<String, dynamic> json) {
    final categoryData = json;

    Color color;
    if (categoryData['color'] is int) {
      color = Color(categoryData['color']);
    } else if (categoryData['color'] is String) {
      color = Wallet.getColorFromString(categoryData['color']);
    } else {
      color = AppColorV2.lpBlueBrand;
    }

    return Wallet(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      categoryId: json['category_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unnamed Wallet',
      balance: (json['amount'] as num?)?.toDouble() ?? 0.0,
      category: json['category']?.toString() ?? 'Unknown',
      iconBase64: json['image_base64']?.toString(),
      color: color,
      createdOn: json['created_on']?.toString() ?? '',
      updatedOn: json['updated_on']?.toString() ?? '',
      isActive: json['is_active']?.toString() ?? 'N',
      categoryTitle: json['category_title']?.toString() ?? 'Unknown',
      imageBase64: json['image_base64']?.toString(),
      targetAmount: (json['targetAmount'] as num?)?.toDouble(),
    );
  }
}

Widget buildWalletIcon(Uint8List? bytes) {
  if (bytes == null) return const Icon(Iconsax.wallet, size: 24);
  return Padding(
    padding: const EdgeInsets.all(5.0),
    child: Image(
      image: MemoryImage(bytes),
      width: 30,
      height: 30,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      filterQuality: FilterQuality.high,
    ),
  );
}

Uint8List? decodeBase64Safe(String base64Str) {
  try {
    final clean = base64Str.replaceAll(RegExp(r'\s'), '');
    return Uint8List.fromList(base64.decode(clean));
  } catch (_) {
    return null;
  }
}

class Transaction {
  final Map<String, dynamic> raw;
  final String id;
  final String description;
  final double amount;
  final DateTime date;
  final bool isIncome;

  Transaction({
    required this.raw,
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.isIncome,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'description': description,
    'amount': amount,
    'date': date.toIso8601String(),
    'isIncome': isIncome,
  };
}

class SubWalletScreen extends StatefulWidget {
  const SubWalletScreen({super.key});

  @override
  State<SubWalletScreen> createState() => _SubWalletScreenState();
}

class _SubWalletScreenState extends State<SubWalletScreen> {
  List<Wallet> wallets = [];
  double totalBalance = 0;
  bool isLoading = true;
  bool categoriesLoaded = false;

  final controller = Get.find<SubWalletController>();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _waitForCategories();
    if (!mounted) return;

    setState(() => categoriesLoaded = true);
    await _loadWalletsFromController();
  }

  Future<void> _loadWalletsFromController() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      if (controller.userSubWallets.isEmpty) {
        await controller.getUserSubWallets();
      }

      wallets =
          controller.userSubWallets.map((walletData) {
            final id = walletData['id']?.toString() ?? '';

            return Wallet(
              id: id,
              userId: walletData['user_id']?.toString() ?? '',
              categoryId: walletData['category_id']?.toString() ?? '',
              name: walletData['name']?.toString() ?? 'Unnamed Wallet',
              balance: (walletData['amount'] as num?)?.toDouble() ?? 0.0,
              category: walletData['category']?.toString() ?? 'Unknown',
              iconBase64: walletData['image_base64']?.toString(),
              color: _getWalletColor(walletData),
              createdOn: walletData['created_on']?.toString() ?? '',
              updatedOn: walletData['updated_on']?.toString() ?? '',
              isActive: walletData['is_active']?.toString() ?? 'N',
              categoryTitle:
                  walletData['category_title']?.toString() ?? 'Unknown',
              imageBase64: walletData['image_base64']?.toString(),
              targetAmount: null,
            );
          }).toList();

      calculateTotalBalance();
    } catch (e) {
      wallets = [];
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Color _getWalletColor(Map<String, dynamic> walletData) {
    final categoryId = walletData['category_id']?.toString();
    final category = controller.categoryList.firstWhere(
      (cat) => cat['category_id']?.toString() == categoryId,
      orElse: () => {},
    );

    if (category['color'] is int) return Color(category['color']);
    if (category['color'] is String)
      return Wallet.getColorFromString(category['color']);
    return AppColorV2.lpBlueBrand;
  }

  Future<bool> transferFunds({
    required Wallet wallet,
    required double amount,
    required TransferType type,
  }) async {
    if (amount <= 0) return false;

    if (type == TransferType.toSubwallet &&
        controller.numericBalance.value < amount) {
      return false;
    }

    if (type == TransferType.toMain && wallet.balance < amount) {
      return false;
    }

    try {
      await controller.getUserSubWallets();
      await controller.luvpayBalance();

      await _loadWalletsFromController();

      return true;
    } catch (e) {
      print('Error transferring funds: $e');
      return false;
    }
  }

  Future<void> _waitForCategories() async {
    if (controller.categoryList.isNotEmpty) return;

    final completer = Completer<void>();
    int attempts = 0;
    const maxAttempts = 50;

    Future.doWhile(() async {
      attempts++;
      if (controller.categoryList.isNotEmpty || attempts >= maxAttempts) {
        if (!completer.isCompleted) completer.complete();
        return false;
      }
      await Future.delayed(const Duration(milliseconds: 100));
      return true;
    });

    await completer.future;
  }

  void calculateTotalBalance() {
    totalBalance = wallets.fold(0, (sum, wallet) => sum + wallet.balance);
  }

  Widget _buildBalanceHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Obx(
              () => _balanceCard(
                title: 'Main Balance',
                amount: controller.luvpayBal.value,
                color: AppColorV2.lpBlueBrand,
                icon: Iconsax.wallet_2,
              ),
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: _balanceCard(
              title: 'Subwallet Balance',
              amount: totalBalance.toStringAsFixed(2),
              color: AppColorV2.correctState,
              icon: Iconsax.wallet_money,
            ),
          ),
        ],
      ),
    );
  }

  Widget _balanceCard({
    required String title,
    required String amount,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            child: Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 6),
                DefaultText(
                  minFontSize: 5,
                  text: title,
                  style: AppTextStyle.paragraph2.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          DefaultText(
            text: amount,
            style: AppTextStyle.h3_f22.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  Future<void> addMoneyToWallet(Wallet wallet, double amount) async {
    if (controller.numericBalance.value < amount) {
      CustomDialogStack.showError(
        context,
        "luvpay",
        "Insufficient main balance",
        () {
          Get.back();
        },
      );
      return;
    }

    await controller.transferSubWallet(
      subwalletId: int.tryParse(wallet.id),
      amount: amount,
      wttarget: "SUB",
    );

    await _refreshData();
  }

  Future<void> returnMoneyToMain(Wallet wallet, double amount) async {
    if (wallet.balance < amount) {
      CustomDialogStack.showError(
        context,
        "luvpay",
        'Insufficient wallet balance',
        () {
          Get.back();
        },
      );

      return;
    }

    await controller.transferSubWallet(
      subwalletId: int.tryParse(wallet.id),
      amount: amount,
      wttarget: "MAIN",
    );

    await _refreshData();
  }

  Future<void> addWallet(Wallet wallet) async {
    if (controller.numericBalance.value >= wallet.balance) {
      try {
        await controller.postSubWallet(
          categoryId: int.tryParse(wallet.categoryId),
          subWalletName: wallet.name,
          amount: wallet.balance,
        );

        await _refreshData();

        if (mounted) {
          CustomDialogStack.showSuccess(
            context,
            'Wallet created successfully!',
            "${wallet.balance.toStringAsFixed(2)} deducted from main balance.",
            () {
              Get.back();
            },
          );
        }
      } catch (e) {
        print('Error creating wallet: $e');
        if (mounted) {
          CustomDialogStack.showError(
            context,
            "luvpay",
            'Failed to create wallet. Please try again.',
            () {
              Get.back();
            },
          );
        }
      }
    } else {
      if (mounted) {
        CustomDialogStack.showError(
          context,
          "luvpay",
          'Insufficient main balance to create this wallet.',
          () {
            Get.back();
          },
        );
      }
      print(
        'Insufficient main balance. Required: ${wallet.balance}, Available: ${controller.numericBalance.value}',
      );
    }
  }

  void _showAddWalletModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColorV2.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return AddWalletModal(
          existingWallets: wallets,
          onWalletCreated: () async {
            await _refreshData();
          },
        );
      },
    ).then((result) async {
      if (result == true) {
        await _refreshData();
      }
    });
  }

  Future<void> _refreshData() async {
    await controller.getUserSubWallets();
    await controller.luvpayBalance();
    await _loadWalletsFromController();
    if (!mounted) return;
    setState(() => calculateTotalBalance());
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffoldV2(
      onPressedLeading: () {
        Get.back(result: true);
      },
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          Get.back(result: true);
        }
      },
      appBarTitle: "Subwallet",
      padding: EdgeInsets.zero,
      backgroundColor: AppColorV2.background,
      scaffoldBody:
          !categoriesLoaded || isLoading
              ? Center(
                child: CircularProgressIndicator(color: AppColorV2.lpBlueBrand),
              )
              : Obx(() {
                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: _buildBalanceHeader()),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                DefaultText(
                                  text: 'My Wallets',
                                  style: AppTextStyle.h3_f22,
                                ),
                                InkWell(
                                  onTap: () => _showAddWalletModal(context),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color:
                                          wallets.length >=
                                                  controller.categoryList.length
                                              ? AppColorV2.boxStroke
                                              : AppColorV2.pastelBlueAccent,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Icon(
                                        Iconsax.add,
                                        color:
                                            wallets.length >=
                                                    controller
                                                        .categoryList
                                                        .length
                                                ? AppColorV2.bodyTextColor
                                                : AppColorV2.lpBlueBrand,
                                        size: 30,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            wallets.isEmpty
                                ? Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 40,
                                  ),
                                  child: Center(
                                    child: Column(
                                      children: [
                                        Icon(
                                          Iconsax.wallet,
                                          size: 60,
                                          color: AppColorV2.boxStroke,
                                        ),
                                        const SizedBox(height: 16),
                                        DefaultText(
                                          text: 'No wallets yet',
                                          style: AppTextStyle.paragraph1,
                                        ),
                                        DefaultText(
                                          text:
                                              'Tap + to create your first wallet',
                                          style: AppTextStyle.paragraph2,
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                : const SizedBox(),
                          ],
                        ),
                      ),
                    ),

                    if (wallets.isNotEmpty)
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverGrid(
                          key: ValueKey(wallets.length),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: 1.5,
                              ),
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final wallet = wallets[index];
                            return _buildWalletCard(wallet);
                          }, childCount: wallets.length),
                        ),
                      ),
                  ],
                );
              }),
    );
  }

  Widget _buildWalletCard(Wallet wallet) {
    final iconBytes =
        wallet.imageBase64 != null && wallet.imageBase64!.isNotEmpty
            ? decodeBase64Safe(wallet.imageBase64!)
            : null;

    return Container(
      decoration: BoxDecoration(
        color: wallet.color.withAlpha(20),
        border: Border.all(color: wallet.color.withAlpha(40)),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(10),
      child: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RepaintBoundary(
                  child: ClipOval(child: buildWalletIcon(iconBytes)),
                ),

                SizedBox(width: 4),
                GestureDetector(
                  onTap: () => _showWalletDetails(context, wallet),
                  child: Icon(Iconsax.more, color: AppColorV2.lpBlueBrand),
                ),
              ],
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DefaultText(
                  text: wallet.name,
                  style: AppTextStyle.h3.copyWith(
                    color: wallet.color,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                ),
                const SizedBox(height: 4),
                DefaultText(
                  text: "₱ ${wallet.balance.toStringAsFixed(2)}",
                  style: AppTextStyle.h3_semibold,
                  color: wallet.color,
                ),
                if (wallet.isActive != 'Y')
                  Container(
                    margin: EdgeInsets.only(top: 4),
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: DefaultText(
                      text: 'Inactive',
                      style: AppTextStyle.paragraph2.copyWith(
                        color: Colors.red,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showWalletDetails(BuildContext context, Wallet wallet) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColorV2.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (_) {
        return WalletDetailsModal(
          wallet: wallet,
          allWallets: wallets,
          onAddMoney: (amount) async => await _refreshData(),
          onReturnMoney: (amount) async => await _refreshData(),
          onUpdate: (updatedWallet) async => await _refreshData(),
          onDelete: () async => await _refreshData(),
        );
      },
    );
  }
}
