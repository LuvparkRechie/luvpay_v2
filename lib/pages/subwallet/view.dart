// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import 'package:luvpay/custom_widgets/alert_dialog.dart';
import 'package:luvpay/custom_widgets/luvpay/luvpay_loading.dart';
import 'package:luvpay/custom_widgets/no_data_found.dart';
import 'package:luvpay/custom_widgets/no_internet.dart';

import '../../custom_widgets/app_color_v2.dart';
import '../../custom_widgets/custom_text_v2.dart';
import '../../custom_widgets/luvpay/neumorphism.dart';
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
      width: 50,
      height: 50,
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
    duration: const Duration(milliseconds: 520),
  );

  late final AnimationController _deleteCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );

  late final Animation<double> _pulseAnim = CurvedAnimation(
    parent: _pulseCtrl,
    curve: Curves.elasticOut,
  );
  late final Animation<double> _deleteAnim = CurvedAnimation(
    parent: _deleteCtrl,
    curve: Curves.linear,
  );

  String? _pulsingWalletId;
  Timer? _pulseTimer;

  String? _deletingWalletId;
  bool isRefreshing = false;
  final ScrollController _scrollCtrl = ScrollController();
  bool _pinHeader = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
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
      if (controller.userSubWallets.isEmpty) {
        await controller.getUserSubWallets();
      }

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
              color: AppColorV2.lpBlueBrand,
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
    if (isRefreshing) return;

    if (mounted) setState(() => isRefreshing = true);

    try {
      await Future.wait([
        controller.getSubWalletCategories(),
        controller.getUserSubWallets(),
        controller.luvpayBalance(),
      ]);

      await _loadWalletsFromController();
      if (!mounted) return;
      setState(calculateTotalBalance);
    } finally {
      if (mounted) setState(() => isRefreshing = false);
    }
  }

  Future<void> _pulseWallet(String walletId) async {
    _pulseTimer?.cancel();
    setState(() => _pulsingWalletId = walletId);

    await _pulseCtrl.forward(from: 0);
    if (!mounted) return;

    _pulseCtrl.reset();
    setState(() => _pulsingWalletId = null);
  }

  Future<void> _animateDelete(String walletId) async {
    if (_deletingWalletId != null) return;
    setState(() => _deletingWalletId = walletId);

    await _deleteCtrl.forward(from: 0);
    if (!mounted) return;

    setState(() {
      wallets.removeWhere((w) => w.id == walletId);
      calculateTotalBalance();
      _deletingWalletId = null;
    });

    _deleteCtrl.reset();
  }

  Future<void> addMoneyToWallet(Wallet wallet, double amount) async {
    if (controller.numericBalance.value < amount) {
      return _err("Insufficient main balance");
    }
    await controller.transferSubWallet(
      subwalletId: int.tryParse(wallet.id),
      amount: amount,
      wttarget: "SUB",
    );
    await _refreshData();
  }

  Future<void> returnMoneyToMain(Wallet wallet, double amount) async {
    if (wallet.balance < amount) return _err("Insufficient subwallet balance");
    await controller.transferSubWallet(
      subwalletId: int.tryParse(wallet.id),
      amount: amount,
      wttarget: "MAIN",
    );
    await _refreshData();
  }

  Future<void> addWallet(Wallet wallet) async {
    if (controller.numericBalance.value < wallet.balance) {
      return _err("Insufficient main balance to create this subwallet.");
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
        'SubWallet created successfully!',
        "${wallet.balance.toStringAsFixed(2)} deducted from main balance.",
        () => Get.back(),
      );
    } catch (e) {
      // ignore: avoid_print
      print('Error creating subwallet: $e');
      if (mounted) _err('Failed to create subwallet. Please try again.');
    }
  }

  void _showAddWalletModal(BuildContext context) {
    final beforeIds = wallets.map((w) => w.id).toSet();

    final cs = Theme.of(context).colorScheme;
    final sheetBg = cs.surface;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: sheetBg,
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
    final cs = Theme.of(context).colorScheme;

    final masked = isRefreshing;
    final walletCountText = masked ? "******" : "${wallets.length} wallets";
    final totalText =
        masked ? "₱ *******" : "₱ ${totalBalance.toStringAsFixed(2)}";

    final headerBg = cs.primary;
    final headerFg = cs.onPrimary;

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(24),
        bottomRight: Radius.circular(24),
      ),
      child: Container(
        width: double.infinity,
        color: headerBg,
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: DefaultText(
                    text: "Subwallet Savings",
                    maxLines: 1,
                    style: AppTextStyle.paragraph2(context).copyWith(
                      fontWeight: FontWeight.w800,
                      color: headerFg.withOpacity(0.95),
                    ),
                  ),
                ),
                DefaultText(
                  text: walletCountText,
                  maxLines: 1,
                  style: AppTextStyle.paragraph2(context).copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: headerFg.withOpacity(0.95),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                DefaultText(
                  text: totalText,
                  maxLines: 1,
                  style: AppTextStyle.h3(context).copyWith(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: headerFg,
                    letterSpacing: .2,
                  ),
                ),
                const SizedBox(width: 2),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: DefaultText(
                    text: "total",
                    maxLines: 1,
                    style: AppTextStyle.paragraph2(context).copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: headerFg.withOpacity(0.95),
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = cs.surface;
    final sheetBg = cs.surface;

    final accent = cs.primary;
    final glow = cs.secondary;

    final ready = categoriesLoaded && !isLoading;
    final hasWallets = wallets.isNotEmpty;
    final headerH = hasWallets && _pinHeader ? 104.0 : 0.0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) Get.back(result: true);
      },
      child: Scaffold(
        backgroundColor: bg,

        appBar: AppBar(
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: cs.primary,
            statusBarIconBrightness:
                isDark ? Brightness.light : Brightness.light,
            statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
          ),
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: cs.primary,
          centerTitle: true,
          leadingWidth: 100,
          title: DefaultText(
            text: "SubWallets",
            color: cs.onPrimary.withOpacity(.95),
            style: AppTextStyle.h3(
              context,
            ).copyWith(fontWeight: FontWeight.w900, letterSpacing: .2),
          ),
        ),

        body: SafeArea(
          top: false,
          bottom: true,
          child:
              !ready
                  ? LoadingCard()
                  : !controller.hasNet.value
                  ? NoInternetConnected(onTap: _refreshData)
                  : isRefreshing
                  ? LoadingCard(text: "Refreshing, please wait...")
                  : Stack(
                    children: [
                      RefreshIndicator.noSpinner(
                        elevation: 0,
                        onRefresh: _refreshData,
                        child: CustomScrollView(
                          controller: _scrollCtrl,
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          slivers: [
                            SliverToBoxAdapter(
                              child: SizedBox(height: hasWallets ? 104 : 10),
                            ),

                            SliverPadding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              sliver:
                                  wallets.isEmpty
                                      ? SliverFillRemaining(
                                        hasScrollBody: false,
                                        child: GestureDetector(
                                          onTap:
                                              () =>
                                                  _showAddWalletModal(context),
                                          child: NoDataFound(
                                            text: "No SubWallets found",
                                            subtext: "Add your first subwallet",
                                            buttonText: "Add SubWallet",
                                            buttonIcon: Iconsax.add,
                                            onTap:
                                                () => _showAddWalletModal(
                                                  context,
                                                ),
                                          ),
                                        ),
                                      )
                                      : SliverGrid(
                                        gridDelegate:
                                            const SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: 2,
                                              crossAxisSpacing: 15,
                                              mainAxisSpacing: 20,
                                              childAspectRatio: 1.35,
                                              mainAxisExtent: 120,
                                            ),
                                        delegate: SliverChildBuilderDelegate((
                                          context,
                                          index,
                                        ) {
                                          final isCreateTile =
                                              index == wallets.length;

                                          if (isCreateTile) {
                                            return CreateSubwalletTile(
                                              onTap:
                                                  () => _showAddWalletModal(
                                                    context,
                                                  ),
                                            );
                                          }

                                          final w = wallets[index];
                                          final iconBytes =
                                              (w.imageBase64?.isNotEmpty ??
                                                      false)
                                                  ? decodeBase64Safe(
                                                    w.imageBase64!,
                                                  )
                                                  : null;

                                          final categoryLabel =
                                              (w.categoryTitle.trim().isNotEmpty
                                                  ? w.categoryTitle
                                                  : w.category);

                                          return SubWalletCard(
                                            wallet: w,
                                            onTap:
                                                () => _showWalletDetails(
                                                  context,
                                                  w,
                                                  sheetBg,
                                                ),
                                            iconBytes: iconBytes,
                                            base: w.color,

                                            titleColor: cs.onSurface,
                                            amountColor: cs.onSurface
                                                .withOpacity(0.72),

                                            categoryLabel: categoryLabel,
                                            isDeleting:
                                                w.id == _deletingWalletId,
                                            isPulsing: w.id == _pulsingWalletId,
                                            deleteAnim: _deleteAnim,
                                            pulseAnim: _pulseAnim,
                                          );
                                        }, childCount: wallets.length + 1),
                                      ),
                            ),

                            const SliverToBoxAdapter(
                              child: SizedBox(height: 30),
                            ),
                          ],
                        ),
                      ),

                      if (hasWallets && _pinHeader)
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: _buildBalanceHeader(),
                        ),
                    ],
                  ),
        ),
      ),
    );
  }

  void _showWalletDetails(BuildContext context, Wallet wallet, Color sheetBg) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: sheetBg,
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

class CreateSubwalletTile extends StatelessWidget {
  final VoidCallback onTap;
  const CreateSubwalletTile({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final base = cs.surface;
    final brand = cs.primary;
    final titleColor = cs.onSurface.withOpacity(0.70);

    final radius = BorderRadius.circular(24);

    return LuvNeuPress.rectangle(
      radius: radius,
      background: base,
      borderColor: cs.outlineVariant.withOpacity(0.25),
      onTap: onTap,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LuvNeuPress.circle(
                onTap: onTap,
                background: brand.withOpacity(0.10),
                borderColor: brand.withOpacity(0.18),
                child: SizedBox(
                  width: 58,
                  height: 58,
                  child: Center(
                    child: Icon(Iconsax.add, size: 30, color: brand),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Add new SubWallet",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 0),
              IgnorePointer(
                ignoring: true,
                child: SizedBox(
                  width: 0,
                  height: 0,
                  child: DecoratedBox(decoration: BoxDecoration(color: base)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
