// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:luvpay/custom_widgets/alert_dialog.dart';
import 'package:luvpay/custom_widgets/luvpay/custom_scaffold.dart';
import 'package:luvpay/pages/subwallet/utils/floating_create_subwallet_button.dart';

import '../../custom_widgets/app_color_v2.dart';
import '../../custom_widgets/custom_text_v2.dart';
import 'controller.dart';
import 'utils/add_wallet_modal.dart';
import 'utils/subwalllet_card.dart';
import 'utils/wallet_Details.dart';

enum WalletModalMode { create, edit }

enum TransferType { toSubwallet, toMain }

class Wallet {
  final String id,
      userId,
      categoryId,
      name,
      category,
      createdOn,
      updatedOn,
      isActive,
      categoryTitle;
  final double balance;
  final String? iconBase64, imageBase64;
  final Color color;
  final double? targetAmount;

  const Wallet({
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

  static const Object _sentinel = Object();

  Wallet copyWith({
    String? name,
    double? balance,
    Object? targetAmount = _sentinel,
  }) {
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
      targetAmount:
          targetAmount == _sentinel
              ? this.targetAmount
              : targetAmount as double?,
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
    'target_amount': targetAmount,
  };

  static Color getColorFromString(String s) {
    switch (s.toLowerCase()) {
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

  factory Wallet.fromJson(Map<String, dynamic> json) {
    final rawColor = json['color'];
    final Color color =
        rawColor is int
            ? Color(rawColor)
            : rawColor is String
            ? getColorFromString(rawColor)
            : AppColorV2.lpBlueBrand;

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
      targetAmount: (json['target_amount'] as num?)?.toDouble(),
    );
  }
}

Widget buildWalletIcon(Uint8List? bytes) {
  if (bytes == null) return const Icon(Iconsax.wallet, size: 24);
  return Padding(
    padding: const EdgeInsets.all(5),
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
  final String id, description;
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

class _SubWalletScreenState extends State<SubWalletScreen>
    with TickerProviderStateMixin {
  final controller = Get.find<SubWalletController>();

  List<Wallet> wallets = [];
  double totalBalance = 0;
  bool isLoading = true;
  bool categoriesLoaded = false;

  late final AnimationController _pulseCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );

  late final AnimationController _deleteCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  );

  late final Animation<double> _pulseAnim = CurvedAnimation(
    parent: _pulseCtrl,
    curve: Curves.easeOutCubic,
  );
  late final Animation<double> _deleteAnim = CurvedAnimation(
    parent: _deleteCtrl,
    curve: Curves.easeInCubic,
  );

  String? _pulsingWalletId;
  Timer? _pulseTimer;

  String? _deletingWalletId;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _pulseTimer?.cancel();
    _pulseCtrl.dispose();
    _deleteCtrl.dispose();
    super.dispose();
  }

  void _err(String msg) {
    CustomDialogStack.showError(context, "luvpay", msg, () => Get.back());
  }

  void calculateTotalBalance() {
    totalBalance = wallets.fold(0, (sum, w) => sum + w.balance);
  }

  Future<void> _initializeData() async {
    await _waitForCategories();
    if (!mounted) return;
    setState(() => categoriesLoaded = true);
    await _loadWalletsFromController();
  }

  Future<void> _waitForCategories() async {
    if (controller.categoryList.isNotEmpty) return;
    for (var i = 0; i < 50; i++) {
      if (controller.categoryList.isNotEmpty) return;
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  Future<void> _loadWalletsFromController() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      if (controller.userSubWallets.isEmpty)
        await controller.getUserSubWallets();

      wallets =
          controller.userSubWallets.map((w) {
            final id = w['id']?.toString() ?? '';
            return Wallet(
              id: id,
              userId: w['user_id']?.toString() ?? '',
              categoryId: w['category_id']?.toString() ?? '',
              name: w['name']?.toString() ?? 'Unnamed Wallet',
              balance: (w['amount'] as num?)?.toDouble() ?? 0.0,
              category: w['category']?.toString() ?? 'Unknown',
              iconBase64: w['image_base64']?.toString(),
              color: WalletTileTheme.colorFromKey(id),
              createdOn: w['created_on']?.toString() ?? '',
              updatedOn: w['updated_on']?.toString() ?? '',
              isActive: w['is_active']?.toString() ?? 'N',
              categoryTitle: w['category_title']?.toString() ?? 'Unknown',
              imageBase64: w['image_base64']?.toString(),
              targetAmount: null,
            );
          }).toList();

      calculateTotalBalance();
    } catch (_) {
      wallets = [];
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _refreshData() async {
    await Future.wait([
      controller.getUserSubWallets(),
      controller.luvpayBalance(),
    ]);
    await _loadWalletsFromController();
    if (!mounted) return;
    setState(calculateTotalBalance);
  }

  void _pulseWallet(String walletId) {
    _pulseTimer?.cancel();
    setState(() => _pulsingWalletId = walletId);

    _pulseCtrl
      ..stop()
      ..reset()
      ..repeat(reverse: true);

    _pulseTimer = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      _pulseCtrl.stop();
      setState(() => _pulsingWalletId = null);
    });
  }

  Future<void> _animateDelete(String walletId) async {
    if (_deletingWalletId != null) return;
    setState(() => _deletingWalletId = walletId);

    await _deleteCtrl.forward();
    if (!mounted) return;

    setState(() {
      wallets.removeWhere((w) => w.id == walletId);
      calculateTotalBalance();
      _deletingWalletId = null;
    });

    _deleteCtrl.reset();
  }

  Future<bool> transferFunds({
    required Wallet wallet,
    required double amount,
    required TransferType type,
  }) async {
    if (amount <= 0) return false;

    if (type == TransferType.toSubwallet &&
        controller.numericBalance.value < amount)
      return false;
    if (type == TransferType.toMain && wallet.balance < amount) return false;

    try {
      await controller.getUserSubWallets();
      await controller.luvpayBalance();
      await _loadWalletsFromController();
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('Error transferring funds: $e');
      return false;
    }
  }

  Future<void> addMoneyToWallet(Wallet wallet, double amount) async {
    if (controller.numericBalance.value < amount)
      return _err("Insufficient main balance");
    await controller.transferSubWallet(
      subwalletId: int.tryParse(wallet.id),
      amount: amount,
      wttarget: "SUB",
    );
    await _refreshData();
  }

  Future<void> returnMoneyToMain(Wallet wallet, double amount) async {
    if (wallet.balance < amount) return _err("Insufficient wallet balance");
    await controller.transferSubWallet(
      subwalletId: int.tryParse(wallet.id),
      amount: amount,
      wttarget: "MAIN",
    );
    await _refreshData();
  }

  Future<void> addWallet(Wallet wallet) async {
    if (controller.numericBalance.value < wallet.balance) {
      // ignore: avoid_print
      print(
        'Insufficient main balance. Required: ${wallet.balance}, Available: ${controller.numericBalance.value}',
      );
      return _err("Insufficient main balance to create this wallet.");
    }

    try {
      await controller.postSubWallet(
        categoryId: int.tryParse(wallet.categoryId),
        subWalletName: wallet.name,
        amount: wallet.balance,
      );

      await _refreshData();

      if (!mounted) return;
      CustomDialogStack.showSuccess(
        context,
        'Wallet created successfully!',
        "${wallet.balance.toStringAsFixed(2)} deducted from main balance.",
        () => Get.back(),
      );
    } catch (e) {
      // ignore: avoid_print
      print('Error creating wallet: $e');
      if (mounted) _err('Failed to create wallet. Please try again.');
    }
  }

  void _showAddWalletModal(BuildContext context) {
    final beforeIds = wallets.map((w) => w.id).toSet();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColorV2.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder:
          (_) => AddWalletModal(
            existingWallets: wallets,
            onWalletCreated: () async {},
          ),
    ).then((result) async {
      if (result != true) return;

      await _refreshData();

      final created = wallets.cast<Wallet?>().firstWhere(
        (w) => w != null && !beforeIds.contains(w.id),
        orElse: () => null,
      );

      if (created == null || !mounted) return;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _pulseWallet(created.id),
      );
    });
  }

  Widget _buildBalanceHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
      child: _balanceCard(
        title: 'Subwallet Savings',
        amount: totalBalance.toStringAsFixed(2),
        color: AppColorV2.lpTealBrand,
        icon: Iconsax.wallet_money,
      ),
    );
  }

  Widget _balanceCard({
    required String title,
    required String amount,
    required Color color,
    required IconData icon,
  }) {
    final titleColor = WalletTileTheme.darken(color, .28);
    final amtColor = WalletTileTheme.darken(color, .25);

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    WalletTileTheme.lighten(color, .18).withOpacity(.35),
                    WalletTileTheme.lighten(color, .06).withOpacity(.12),
                    AppColorV2.background.withOpacity(.10),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: const SizedBox(),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withOpacity(.20)),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(.18),
                  blurRadius: 22,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(.65),
                        Colors.white.withOpacity(.18),
                      ],
                    ),
                    border: Border.all(color: Colors.white.withOpacity(.30)),
                  ),
                  child: Icon(icon, color: WalletTileTheme.darken(color, .25)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DefaultText(
                        text: title,
                        maxLines: 1,
                        style: AppTextStyle.paragraph2.copyWith(
                          color: titleColor,
                          fontWeight: FontWeight.w700,
                          letterSpacing: .2,
                        ),
                      ),
                      DefaultText(
                        text: "₱ $amount",
                        maxLines: 1,
                        minFontSize: 12,
                        style: AppTextStyle.h3_semibold.copyWith(
                          fontSize: 24,
                          color: amtColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ready = categoriesLoaded && !isLoading;
    final hasWallets = wallets.isNotEmpty;

    return CustomScaffoldV2(
      floatingButton:
          ready && hasWallets
              ? FloatingCreateSubwalletButton(
                onTap: () => _showAddWalletModal(context),
              )
              : null,
      onPressedLeading: () => Get.back(result: true),
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) Get.back(result: true);
      },
      appBarTitle: "Subwallet",
      padding: EdgeInsets.zero,
      backgroundColor: AppColorV2.background,
      scaffoldBody:
          !ready
              ? Center(
                child: CircularProgressIndicator(color: AppColorV2.lpBlueBrand),
              )
              : CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _PinnedHeaderDelegate(
                      minH: 104,
                      maxH: 104,
                      background: AppColorV2.background,
                      child:
                          hasWallets
                              ? _buildBalanceHeader()
                              : const SizedBox.shrink(),
                    ),
                  ),
                  if (hasWallets)
                    const SliverToBoxAdapter(child: SizedBox(height: 6)),
                  if (!hasWallets)
                    SliverToBoxAdapter(child: _emptyState(context))
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverGrid(
                        key: ValueKey(wallets.length),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 1,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 1.35,
                              mainAxisExtent: 120,
                            ),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final w = wallets[index];

                          final iconBytes =
                              (w.imageBase64?.isNotEmpty ?? false)
                                  ? decodeBase64Safe(w.imageBase64!)
                                  : null;

                          final base = w.color;
                          final titleColor = WalletTileTheme.darken(base, .010);
                          final amountColor = WalletTileTheme.darken(
                            base,
                            .020,
                          );
                          final categoryLabel =
                              (w.categoryTitle.trim().isNotEmpty
                                  ? w.categoryTitle
                                  : w.category);

                          return SubWalletCard(
                            wallet: w,
                            onTap: () => _showWalletDetails(context, w),
                            iconBytes: iconBytes,
                            base: base,
                            titleColor: titleColor,
                            amountColor: amountColor,
                            categoryLabel: categoryLabel,
                            isDeleting: w.id == _deletingWalletId,
                            isPulsing: w.id == _pulsingWalletId,
                            deleteAnim: _deleteAnim,
                            pulseAnim: _pulseAnim,
                          );
                        }, childCount: wallets.length),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 30)),
                ],
              ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Center(
        child: Column(
          children: [
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _showAddWalletModal(context),
              borderRadius: BorderRadius.circular(999),
              child: ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColorV2.lpBlueBrand.withOpacity(.38),
                          AppColorV2.lpTealBrand.withOpacity(.22),
                          Colors.white.withOpacity(.10),
                        ],
                      ),
                      border: Border.all(color: Colors.white.withOpacity(.25)),
                      boxShadow: [
                        BoxShadow(
                          color: AppColorV2.lpBlueBrand.withOpacity(.16),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Iconsax.add,
                        size: 26,
                        color: AppColorV2.lpBlueBrand,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            DefaultText(text: 'No wallets yet', style: AppTextStyle.paragraph1),
            DefaultText(
              text: 'Tap + to create your first wallet',
              style: AppTextStyle.paragraph2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletCard(Wallet wallet) {
    final iconBytes =
        (wallet.imageBase64?.isNotEmpty ?? false)
            ? decodeBase64Safe(wallet.imageBase64!)
            : null;

    final base = wallet.color;
    final titleColor = WalletTileTheme.darken(base, .010);
    final amountColor = WalletTileTheme.darken(base, .020);

    final categoryLabel =
        (wallet.categoryTitle.trim().isNotEmpty
            ? wallet.categoryTitle
            : wallet.category);

    final card = GestureDetector(
      onTap: () => _showWalletDetails(context, wallet),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      WalletTileTheme.lighten(base, .1).withOpacity(.40),
                      WalletTileTheme.lighten(base, .06).withOpacity(.20),
                      WalletTileTheme.lighten(base, .09).withOpacity(.10),
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: const SizedBox(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withOpacity(.70),
                                  Colors.white.withOpacity(.18),
                                ],
                              ),
                              border: Border.all(
                                color: Colors.white.withOpacity(.28),
                              ),
                            ),
                            child: Center(
                              child: ClipOval(
                                child: SizedBox(
                                  width: 30,
                                  height: 30,
                                  child: FittedBox(
                                    fit: BoxFit.contain,
                                    child: buildWalletIcon(iconBytes),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: Colors.white.withOpacity(.18),
                              border: Border.all(
                                color: Colors.white.withOpacity(.22),
                              ),
                            ),
                            child: DefaultText(
                              text: categoryLabel,
                              maxLines: 1,
                              color: titleColor,
                              style: AppTextStyle.body1,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: Colors.white.withOpacity(.16),
                          border: Border.all(
                            color: Colors.white.withOpacity(.20),
                          ),
                        ),
                        child: Icon(Iconsax.more, size: 18, color: titleColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: DefaultText(
                      text: wallet.name,
                      maxLines: 1,
                      style: AppTextStyle.h3.copyWith(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                        letterSpacing: .2,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: DefaultText(
                      text: "₱ ${wallet.balance.toStringAsFixed(2)}",
                      maxLines: 1,
                      style: AppTextStyle.h3_semibold.copyWith(
                        fontSize: 18,
                        color: amountColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: -34,
              left: -44,
              child: Transform.rotate(
                angle: -0.45,
                child: Container(
                  width: 190,
                  height: 110,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(60),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(.22),
                        Colors.white.withOpacity(0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    final isDeleting = wallet.id == _deletingWalletId;
    if (isDeleting) {
      return AnimatedBuilder(
        animation: _deleteAnim,
        child: card,
        builder: (_, child) {
          final t = 1.0 - _deleteAnim.value;
          return Opacity(
            opacity: t.clamp(0.0, 1.0),
            child: Transform.scale(scale: t.clamp(0.0, 1.0), child: child),
          );
        },
      );
    }

    final isPulsing = wallet.id == _pulsingWalletId;
    if (!isPulsing) return card;

    return AnimatedBuilder(
      animation: _pulseAnim,
      child: card,
      builder: (_, child) {
        final t = _pulseAnim.value;
        return Transform.scale(
          scale: 1.0 + (0.04 * t),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: base.withOpacity(0.22 * t),
                  blurRadius: 26 * t,
                  spreadRadius: 2 * t,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: child,
          ),
        );
      },
    );
  }

  void _showWalletDetails(BuildContext context, Wallet wallet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColorV2.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder:
          (_) => WalletDetailsModal(
            wallet: wallet,
            allWallets: wallets,
            onAddMoney: (_) async => _refreshData(),
            onReturnMoney: (_) async => _refreshData(),
            onUpdate: (_) async => _refreshData(),
            onDelete: () async => _animateDelete(wallet.id),
          ),
    );
  }
}

class WalletTileTheme {
  static const List<Color> palette = [
    Color(0xFF3B82F6),
    Color(0xFF4F46E5),
    Color(0xFF2563EB),
    Color(0xFF0284C7),
    Color(0xFF38BDF8),
    Color(0xFF14B8A6),
    Color(0xFF22D3EE),
    Color(0xFF34D399),
    Color(0xFF4ADE80),
    Color(0xFF22C55E),
    Color(0xFF2DD4BF),
  ];

  static Color colorFromKey(String key) {
    if (key.isEmpty) return palette.first;
    int hash = 0;
    for (final u in key.codeUnits) {
      hash = (hash * 31 + u) & 0x7fffffff;
    }
    return palette[hash % palette.length];
  }

  static Color lighten(Color c, [double a = .12]) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness + a).clamp(0.0, 1.0)).toColor();
  }

  static Color darken(Color c, [double a = .10]) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness - a).clamp(0.0, 1.0)).toColor();
  }
}

class _PinnedHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minH, maxH;
  final Widget child;
  final Color background;

  _PinnedHeaderDelegate({
    required this.minH,
    required this.maxH,
    required this.child,
    required this.background,
  });

  @override
  double get minExtent => minH;

  @override
  double get maxExtent => maxH;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox(
      height: maxExtent,
      child: Container(
        color: background,
        alignment: Alignment.center,
        child: child,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedHeaderDelegate old) {
    return old.minH != minH ||
        old.maxH != maxH ||
        old.background != background ||
        old.child != child;
  }
}
