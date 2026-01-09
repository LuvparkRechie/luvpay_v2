// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:async';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:iconsax/iconsax.dart';
import 'package:luvpay/custom_widgets/luvpay/custom_scaffold.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../custom_widgets/app_color_v2.dart';
import '../../custom_widgets/custom_text_v2.dart';
import '../my_account/utils/view.dart';
import 'controller.dart';

enum WalletModalMode { create, edit }

enum TransferType { toSubwallet, toMain }

class Wallet {
  final String id;
  final String name;
  final double balance;
  final String category;
  final Uint8List? iconBytes;
  final Color color;
  final List<Transaction> transactions;
  final double? targetAmount;

  Wallet({
    required this.id,
    required this.name,
    required this.balance,
    required this.category,
    required this.iconBytes,
    required this.color,
    required this.transactions,
    this.targetAmount,
  });
  Wallet copyWith({
    String? name,
    double? balance,
    List<Transaction>? transactions,
    double? targetAmount,
  }) {
    return Wallet(
      id: id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      category: category,
      iconBytes: iconBytes,
      color: color,
      transactions: transactions ?? this.transactions,
      targetAmount: targetAmount ?? this.targetAmount,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'balance': balance,
    'category': category,
    'icon_base64': iconBytes != null ? base64.encode(iconBytes!) : null,
    'color': color.value,
    'transactions': transactions.map((e) => e.toJson()).toList(),
    'targetAmount': targetAmount,
  };

  static const String _walletsKey = 'wallets';

  factory Wallet.fromJson(
    Map<String, dynamic> json,
    List<Map<String, dynamic>> categoryList,
  ) {
    final categoryData = categoryList.firstWhere(
      (cat) => cat['category_title'] == json['category'],
      orElse: () => {},
    );

    final base64Str = categoryData['image_base64']?.toString() ?? '';

    Color color;
    if (categoryData['color'] is int) {
      color = Color(categoryData['color']);
    } else if (categoryData['color'] is String) {
      color = _getColorFromString(categoryData['color']);
    } else {
      color = AppColorV2.lpBlueBrand;
    }

    return Wallet(
      id: json['id'],
      name: json['name'],
      balance: (json['balance'] as num).toDouble(),
      category: json['category'],
      iconBytes: base64Str.isNotEmpty ? decodeBase64Safe(base64Str) : null,
      color: color,
      transactions:
          (json['transactions'] as List)
              .map((e) => Transaction.fromJson(e))
              .toList(),
      targetAmount: (json['targetAmount'] as num?)?.toDouble(),
    );
  }
}

Widget buildWalletIcon(Uint8List? bytes) {
  if (bytes == null) {
    return const Icon(Iconsax.wallet, size: 24);
  }

  return Image(
    image: MemoryImage(bytes),
    width: 30,
    height: 30,
    fit: BoxFit.contain,
    gaplessPlayback: true,
    filterQuality: FilterQuality.high,
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

Color _getColorFromString(String colorString) {
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

class Transaction {
  final String id;
  final String description;
  final double amount;
  final DateTime date;
  final bool isIncome;

  Transaction({
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

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      description: json['description'],
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date']),
      isIncome: json['isIncome'],
    );
  }
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

  final String _walletsKey = 'user_wallets';
  final controller = Get.find<SubWalletController>();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _waitForCategories();
    setState(() {
      categoriesLoaded = true;
    });

    await _loadWallets();
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
    setState(() {
      final index = wallets.indexWhere((w) => w.id == wallet.id);
      if (index == -1) return;

      wallets[index] = wallet.copyWith(
        balance:
            type == TransferType.toSubwallet
                ? wallet.balance + amount
                : wallet.balance - amount,
        transactions: [
          ...wallet.transactions,
          Transaction(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            description:
                type == TransferType.toSubwallet
                    ? 'Added from Main Wallet'
                    : 'Returned to Main Wallet',
            amount: amount,
            date: DateTime.now(),
            isIncome: type == TransferType.toSubwallet,
          ),
        ],
      );

      calculateTotalBalance();
    });

    if (type == TransferType.toSubwallet) {
      controller.updateMainBalance(amount);
    } else {
      controller.returnToMainBalance(amount);
    }

    _saveWallets();
    return true;
  }

  Future<void> _loadWallets() async {
    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final walletsJson = prefs.getString(_walletsKey);

      if (walletsJson != null) {
        final List<dynamic> walletsList = json.decode(walletsJson);

        wallets =
            walletsList.map((w) {
              return Wallet.fromJson(w, controller.categoryList);
            }).toList();

        print('Loaded ${wallets.length} wallets from storage');
      } else {
        wallets = [];
        print('No wallets found in storage');
      }

      calculateTotalBalance();
    } catch (e) {
      print('Error loading wallets: $e');
      wallets = [];
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _waitForCategories() async {
    if (controller.categoryList.isNotEmpty) return;

    Completer<void> completer = Completer();
    int attempts = 0;
    const int maxAttempts = 50;

    Future.doWhile(() async {
      attempts++;
      if (controller.categoryList.isNotEmpty) {
        completer.complete();
        return false;
      }
      if (attempts >= maxAttempts) {
        completer.complete();
        return false;
      }
      await Future.delayed(const Duration(milliseconds: 100));
      return true;
    });

    await completer.future;
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

  void addMoneyToWallet(Wallet wallet, double amount) {
    if (controller.numericBalance.value < amount) {
      return;
    }
    setState(() {
      final index = wallets.indexWhere((w) => w.id == wallet.id);
      if (index == -1) return;

      wallets[index] = wallet.copyWith(
        balance: wallet.balance + amount,
        transactions: [
          ...wallet.transactions,
          Transaction(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            description: 'Added from Main Wallet',
            amount: amount,
            date: DateTime.now(),
            isIncome: true,
          ),
        ],
      );

      calculateTotalBalance();
    });

    controller.updateMainBalance(amount);
    _saveWallets();
  }

  void returnMoneyToMain(Wallet wallet, double amount) {
    if (wallet.balance < amount) {
      return;
    }

    setState(() {
      final index = wallets.indexWhere((w) => w.id == wallet.id);
      if (index == -1) return;

      wallets[index] = wallet.copyWith(
        balance: wallet.balance - amount,
        transactions: [
          ...wallet.transactions,
          Transaction(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            description: 'Returned to Main Wallet',
            amount: amount,
            date: DateTime.now(),
            isIncome: false,
          ),
        ],
      );

      calculateTotalBalance();
    });

    controller.returnToMainBalance(amount);
    _saveWallets();
  }

  Future<void> _saveWallets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final walletsJson = json.encode(wallets.map((w) => w.toJson()).toList());
      await prefs.setString(_walletsKey, walletsJson);
      print('Saved ${wallets.length} wallets to storage');
    } catch (e) {
      print('Error saving wallets: $e');
    }
  }

  void calculateTotalBalance() {
    totalBalance = wallets.fold(0, (sum, wallet) => sum + wallet.balance);
    print('Total balance calculated: $totalBalance');
  }

  void addWallet(Wallet wallet) {
    print('Adding wallet: ${wallet.name} with balance: ${wallet.balance}');

    if (controller.numericBalance.value >= wallet.balance) {
      setState(() {
        wallets.add(wallet);
        calculateTotalBalance();
      });

      controller.updateMainBalance(wallet.balance);

      _saveWallets();
      print('Wallet added successfully. Total wallets: ${wallets.length}');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DefaultText(
                text: 'Wallet created successfully!',
                color: AppColorV2.background,
              ),
              Visibility(
                visible: wallet.balance > 0,
                child: DefaultText(
                  text:
                      "${wallet.balance.toStringAsFixed(2)} deducted from main balance.",
                  color: AppColorV2.background,
                ),
              ),
            ],
          ),
          backgroundColor: AppColorV2.correctState,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: DefaultText(
            text: 'Insufficient main balance to create this wallet.',
          ),
          backgroundColor: AppColorV2.incorrectState,
        ),
      );
      print(
        'Insufficient main balance. Required: ${wallet.balance}, Available: ${controller.numericBalance.value}',
      );
    }
  }

  void deleteWallet(String walletId) {
    final wallet = wallets.firstWhere((wallet) => wallet.id == walletId);
    final double walletBalance = wallet.balance;

    setState(() {
      wallets.removeWhere((wallet) => wallet.id == walletId);
      calculateTotalBalance();
    });

    controller.returnToMainBalance(walletBalance);

    _saveWallets();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DefaultText(
              text: 'Wallet deleted successfully!',
              color: AppColorV2.background,
            ),
            Visibility(
              visible: walletBalance > 0,
              child: DefaultText(
                text:
                    '${walletBalance.toStringAsFixed(2)} returned to main balance.',
                color: AppColorV2.background,
              ),
            ),
          ],
        ),
        backgroundColor: AppColorV2.correctState,
      ),
    );
  }

  void _showAddWalletModal(BuildContext context) {
    showModalBottomSheet<Wallet>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColorV2.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return AddWalletModal();
      },
    ).then((result) {
      print('Modal result: $result');

      if (result != null && mounted) {
        print('Received wallet from modal: ${result.name}');

        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            addWallet(result);
          }
        });
      } else {
        print('Modal returned null or widget is disposed');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffoldV2(
      appBarTitle: "Subwallet",
      padding: EdgeInsets.zero,
      backgroundColor: AppColorV2.background,
      scaffoldBody:
          !categoriesLoaded || isLoading
              ? Center(
                child: CircularProgressIndicator(color: AppColorV2.lpBlueBrand),
              )
              : CustomScrollView(
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
                                    color: AppColorV2.pastelBlueAccent,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Icon(
                                      Iconsax.add,
                                      color: AppColorV2.lpBlueBrand,
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
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final wallet = wallets[index];
                          return _buildWalletCard(wallet);
                        }, childCount: wallets.length),
                      ),
                    ),
                ],
              ),
    );
  }

  Widget _buildWalletCard(Wallet wallet) {
    return GestureDetector(
      onTap: () => _showWalletDetails(context, wallet),
      child: Container(
        decoration: BoxDecoration(
          color: AppColorV2.lpBlueBrand.withAlpha(20),
          border: Border.all(color: AppColorV2.lpBlueBrand.withAlpha(40)),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RepaintBoundary(
                    child: ClipOval(child: buildWalletIcon(wallet.iconBytes)),
                  ),

                  SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColorV2.lpBlueBrand.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DefaultText(
                        text: wallet.category,
                        style: AppTextStyle.body1,
                        color: AppColorV2.lpBlueBrand,
                        minFontSize: 8,
                        maxLines: 1,
                      ),
                    ),
                  ),
                ],
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DefaultText(
                    text: wallet.name,
                    style: AppTextStyle.h3.copyWith(
                      color: AppColorV2.lpBlueBrand,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                  ),
                  const SizedBox(height: 4),
                  DefaultText(
                    text: wallet.balance.toStringAsFixed(2),
                    style: AppTextStyle.h2.copyWith(
                      color: AppColorV2.lpBlueBrand,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
      builder: (_) {
        return WalletDetailsModal(
          wallet: wallet,
          onAddMoney: (amount) {
            addMoneyToWallet(wallet, amount);
          },
          onReturnMoney: (amount) {
            returnMoneyToMain(wallet, amount);
          },

          onUpdate: (updatedWallet) {
            setState(() {
              final index = wallets.indexWhere((w) => w.id == updatedWallet.id);
              if (index != -1) {
                wallets[index] = updatedWallet;
                calculateTotalBalance();
              }
            });
            _saveWallets();
          },

          onDelete: () {
            deleteWallet(wallet.id);
            Navigator.pop(context);
          },
        );
      },
    );
  }
}

class AddWalletModal extends StatefulWidget {
  final WalletModalMode mode;
  final Wallet? wallet;

  const AddWalletModal({
    super.key,
    this.mode = WalletModalMode.create,
    this.wallet,
  });

  @override
  _AddWalletModalState createState() => _AddWalletModalState();
}

class _AddWalletModalState extends State<AddWalletModal> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _balanceController = TextEditingController();
  String? _selectedCategory;
  Color? _selectedColor;

  String? _nameError;
  String? _balanceError;
  final FocusNode _balanceFocusNode = FocusNode();

  final SubWalletController controller = Get.find<SubWalletController>();

  @override
  void initState() {
    super.initState();

    if (widget.mode == WalletModalMode.edit && widget.wallet != null) {
      final w = widget.wallet!;
      _nameController.text = w.name;
      _selectedCategory = w.category;
      _selectedColor = w.color;
      _selectedIconBytes = w.iconBytes;
    }

    _balanceFocusNode.addListener(_validateBalanceOnBlur);
  }

  @override
  void dispose() {
    _balanceFocusNode.removeListener(_validateBalanceOnBlur);
    _balanceFocusNode.dispose();
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  void _validateBalanceOnBlur() {
    if (!_balanceFocusNode.hasFocus) {
      setState(() {
        _balanceError = _validateBalance(_balanceController.text);
      });
    }
  }

  String? _validateName(String value) {
    if (value.isEmpty) {
      return 'Wallet name is required';
    }
    if (value.length > 15) {
      return 'Wallet name must be 15 characters or less';
    }
    return null;
  }

  void _validateNameOnChange(String value) {
    setState(() {
      _nameError = _validateName(value);
    });
  }

  String? _validateBalance(String value) {
    if (value.isEmpty) {
      return 'Balance is required';
    }

    final balanceStr = value;
    final beforeDecimal = balanceStr.split('.')[0];

    if (beforeDecimal.length > 9) {
      return 'Balance cannot exceed 9 digits';
    }

    try {
      final balance = double.parse(balanceStr);

      if (balance > 999999999.99) {
        return 'Balance cannot exceed 999,999,999.99';
      }

      if (balance <= 0) {
        return 'Balance must be greater than 0';
      }

      if (balance > controller.numericBalance.value) {
        return 'Insufficient main balance';
      }

      return null;
    } catch (e) {
      return 'Please enter a valid balance';
    }
  }

  void _validateBalanceOnChange(String value) {
    setState(() {
      _balanceError = _validateBalance(value);
    });
  }

  bool _validateAll() {
    final nameError = _validateName(_nameController.text);

    if (widget.mode == WalletModalMode.edit) {
      setState(() => _nameError = nameError);
      return nameError == null;
    }

    final balanceError = _validateBalance(_balanceController.text);

    setState(() {
      _nameError = nameError;
      _balanceError = balanceError;
    });

    return nameError == null && balanceError == null;
  }

  Uint8List? _selectedIconBytes;
  final Map<String, Uint8List> _iconCache = {};

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      height: MediaQuery.of(context).size.height * 0.8,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 60,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColorV2.boxStroke,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            DefaultText(
              text:
                  widget.mode == WalletModalMode.create
                      ? 'Create New Wallet'
                      : 'Edit Wallet',
              style: AppTextStyle.popup,
            ),
            const SizedBox(height: 10),

            Obx(
              () => Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColorV2.pastelBlueAccent.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColorV2.boxStroke),
                ),
                child: Row(
                  children: [
                    Icon(
                      Iconsax.wallet_money,
                      color: AppColorV2.lpBlueBrand,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DefaultText(
                        text:
                            'Available Main Balance: ${controller.luvpayBal.value}',
                        style: AppTextStyle.paragraph1.copyWith(
                          color: AppColorV2.lpBlueBrand,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),
            DefaultText(
              text: 'Select Category',
              style: AppTextStyle.h3.copyWith(
                color: AppColorV2.primaryTextColor,
              ),
            ),
            const SizedBox(height: 10),
            Obx(() {
              if (controller.categoryList.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: CircularProgressIndicator(
                      color: AppColorV2.lpBlueBrand,
                    ),
                  ),
                );
              }

              return SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: controller.categoryList.length,
                  itemBuilder: (context, index) {
                    final category = controller.categoryList[index];
                    final categoryName =
                        category['category_title']?.toString() ?? 'Unknown';
                    final isSelected = _selectedCategory == categoryName;

                    final imageBase64 =
                        category['image_base64']?.toString() ?? '';
                    Color color;

                    if (category['color'] is int) {
                      color = Color(category['color']);
                    } else if (category['color'] is String) {
                      color = _getColorFromString(category['color']);
                    } else {
                      color = AppColorV2.lpBlueBrand;
                    }

                    Widget iconWidget;
                    if (imageBase64.isNotEmpty) {
                      try {
                        final cleanBase64 = imageBase64.replaceAll(
                          RegExp(r'\s'),
                          '',
                        );
                        Uint8List? bytes;

                        if (_iconCache.containsKey(categoryName)) {
                          bytes = _iconCache[categoryName];
                        } else {
                          try {
                            bytes = base64.decode(cleanBase64);
                            _iconCache[categoryName] = bytes;
                          } catch (_) {
                            bytes = null;
                          }
                        }

                        iconWidget =
                            bytes != null
                                ? Image.memory(
                                  bytes,
                                  width: 30,
                                  height: 30,
                                  fit: BoxFit.contain,
                                  gaplessPlayback: true,
                                )
                                : const Icon(Iconsax.wallet, size: 30);
                      } catch (e) {
                        print(
                          'Error decoding base64 image for category $categoryName: $e',
                        );
                        iconWidget = Icon(Iconsax.wallet, size: 30);
                      }
                    } else {
                      iconWidget = Icon(Iconsax.wallet, size: 30);
                    }
                    if (_selectedCategory == null && index == 0) {
                      _selectedCategory = categoryName;
                      _selectedColor = color;
                      _selectedIconBytes = _iconCache[categoryName];
                    }

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategory = categoryName;
                          _selectedColor = color;
                          _selectedIconBytes = _iconCache[categoryName];
                        });
                      },

                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isSelected ? color : AppColorV2.pastelBlueAccent,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: isSelected ? color : AppColorV2.boxStroke,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            ClipOval(child: iconWidget),
                            const SizedBox(width: 8),
                            DefaultText(
                              text: categoryName,
                              style: AppTextStyle.h3.copyWith(
                                color:
                                    isSelected
                                        ? Colors.white
                                        : AppColorV2.primaryTextColor,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
            const SizedBox(height: 30),
            TextField(
              controller: _nameController,
              onChanged: _validateNameOnChange,
              style: AppTextStyle.h3.copyWith(
                color: AppColorV2.primaryTextColor,
              ),
              maxLength: 15,
              inputFormatters: [UpperCaseTextFormatter()],
              decoration: InputDecoration(
                labelText: 'Subwallet Name',
                labelStyle: AppTextStyle.paragraph2,
                filled: true,
                fillColor: AppColorV2.pastelBlueAccent,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: AppColorV2.boxStroke),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: AppColorV2.boxStroke),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: AppColorV2.lpBlueBrand),
                ),
                prefixIcon: Icon(Iconsax.wallet, color: AppColorV2.lpBlueBrand),
                counterText: '',
                hintText: 'Max 15 characters',
                hintStyle: AppTextStyle.paragraph2.copyWith(fontSize: 12),
                errorText: _nameError,
                errorStyle: TextStyle(
                  color: AppColorV2.incorrectState,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 20),

            if (widget.mode == WalletModalMode.create) ...[
              TextField(
                controller: _balanceController,
                focusNode: _balanceFocusNode,
                onChanged: _validateBalanceOnChange,
                style: AppTextStyle.h3.copyWith(
                  color: AppColorV2.primaryTextColor,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                maxLength: 12,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d{0,9}(\.\d{0,2})?$'),
                  ),
                ],
                decoration: InputDecoration(
                  labelText: 'Amount',
                  labelStyle: AppTextStyle.paragraph2,
                  filled: true,
                  fillColor: AppColorV2.pastelBlueAccent,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: AppColorV2.boxStroke),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: AppColorV2.boxStroke),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: AppColorV2.lpBlueBrand),
                  ),
                  prefixIcon: Icon(
                    Iconsax.money_3,
                    color: AppColorV2.lpBlueBrand,
                  ),
                  counterText: '',
                  hintText: 'Max 9 digits (e.g., 999999999.99)',
                  hintStyle: AppTextStyle.paragraph2.copyWith(fontSize: 12),
                  errorText: _balanceError,
                  errorStyle: TextStyle(
                    color: AppColorV2.incorrectState,
                    fontSize: 12,
                  ),
                  suffixIcon:
                      _balanceError != null &&
                              _balanceError!.contains(
                                'Insufficient main balance',
                              )
                          ? Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Icon(
                              Iconsax.warning_2,
                              color: AppColorV2.incorrectState,
                              size: 20,
                            ),
                          )
                          : null,
                ),
              ),
            ],
            if (_balanceError != null &&
                _balanceError!.contains('Insufficient main balance'))
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                child: Row(
                  children: [
                    Icon(
                      Iconsax.info_circle,
                      color: AppColorV2.incorrectState,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: DefaultText(
                        text: 'Available: ${controller.luvpayBal.value}',
                        style: AppTextStyle.paragraph2.copyWith(
                          color: AppColorV2.incorrectState,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  if (widget.mode == WalletModalMode.create && !_validateAll())
                    return;

                  final wallet = Wallet(
                    id:
                        widget.mode == WalletModalMode.edit
                            ? widget.wallet!.id
                            : DateTime.now().millisecondsSinceEpoch.toString(),
                    name: _nameController.text.trim(),
                    balance:
                        widget.mode == WalletModalMode.edit
                            ? widget.wallet!.balance
                            : double.tryParse(_balanceController.text) ?? 0,
                    category: _selectedCategory ?? 'Uncategorized',
                    iconBytes: _selectedIconBytes,
                    color: _selectedColor ?? AppColorV2.lpBlueBrand,
                    transactions:
                        widget.mode == WalletModalMode.edit
                            ? widget.wallet!.transactions
                            : [],
                  );

                  Navigator.pop(context, wallet);
                },
                child: Text(
                  widget.mode == WalletModalMode.create
                      ? 'Create Wallet'
                      : 'Save Changes',
                ),
              ),
            ),

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColorV2.pastelBlueAccent.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Iconsax.info_circle,
                    color: AppColorV2.lpBlueBrand,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DefaultText(
                      text:
                          'Funds will be deducted from your main LuvPay balance',
                      style: AppTextStyle.paragraph2.copyWith(
                        color: AppColorV2.bodyTextColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WalletDetailsModal extends StatefulWidget {
  final Wallet wallet;
  final VoidCallback? onDelete;
  final Function(Wallet updatedWallet)? onUpdate;
  final Function(double amount)? onAddMoney;
  final Function(double amount)? onReturnMoney;

  const WalletDetailsModal({
    super.key,
    required this.wallet,
    this.onDelete,
    this.onUpdate,
    this.onAddMoney,
    this.onReturnMoney,
  });

  @override
  State<WalletDetailsModal> createState() => _WalletDetailsModalState();
}

class _WalletDetailsModalState extends State<WalletDetailsModal> {
  late Wallet _wallet;

  @override
  void initState() {
    super.initState();
    _wallet = widget.wallet;
  }

  void _handleAddMoney(double amount) {
    final updatedWallet = _wallet.copyWith(
      balance: _wallet.balance + amount,
      transactions: [
        ..._wallet.transactions,
        Transaction(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          description: 'Added from Main Wallet',
          amount: amount,
          date: DateTime.now(),
          isIncome: true,
        ),
      ],
    );

    setState(() => _wallet = updatedWallet);
    widget.onAddMoney?.call(amount);
    widget.onUpdate?.call(updatedWallet);
  }

  void _handleReturnMoney(double amount) {
    if (_wallet.balance < amount) return;

    final updatedWallet = _wallet.copyWith(
      balance: _wallet.balance - amount,
      transactions: [
        ..._wallet.transactions,
        Transaction(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          description: 'Returned to Main Wallet',
          amount: amount,
          date: DateTime.now(),
          isIncome: false,
        ),
      ],
    );

    setState(() => _wallet = updatedWallet);
    widget.onReturnMoney?.call(amount);
    widget.onUpdate?.call(updatedWallet);
  }

  void _showEditWallet(BuildContext context) {
    showModalBottomSheet<Wallet>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColorV2.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder:
          (_) => AddWalletModal(mode: WalletModalMode.edit, wallet: _wallet),
    ).then((updatedWallet) {
      if (updatedWallet != null) {
        setState(() => _wallet = updatedWallet);
        widget.onUpdate?.call(updatedWallet);
      }
    });
  }

  Future<void> _deleteWallet(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Delete Wallet'),
            content: Text('Delete ${_wallet.name}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (result == true) {
      widget.onDelete?.call();
    }
  }

  Widget _buildTargetSection() {
    if (_wallet.targetAmount == null) {
      return _buildSetTargetButton();
    }

    final target = _wallet.targetAmount!;
    final progress = (_wallet.balance / target).clamp(0.0, 1.0);
    final remaining = (target - _wallet.balance).clamp(0, target);

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: _wallet.color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _wallet.color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Iconsax.flag, size: 18),
              const SizedBox(width: 6),
              DefaultText(text: 'Target Goal', style: AppTextStyle.paragraph2),
              const Spacer(),
              GestureDetector(
                onTap: _showSetTargetDialog,
                child: const Icon(Iconsax.edit, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.grey.shade300,
            color: _wallet.color,
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(height: 8),
          DefaultText(
            text:
                remaining <= 0
                    ? '🎉 Target reached!'
                    : '₱${remaining.toStringAsFixed(2)} left to reach ₱${target.toStringAsFixed(2)}',
            style: AppTextStyle.paragraph2,
          ),
        ],
      ),
    );
  }

  void _showSetTargetDialog() {
    final controller = TextEditingController(
      text: _wallet.targetAmount?.toStringAsFixed(0),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder:
          (_) => Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DefaultText(
                  text: 'Set Target Amount',
                  style: AppTextStyle.h3_f22,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    prefixText: '₱ ',
                    hintText: 'Enter target amount',
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    final value = double.tryParse(controller.text);
                    if (value == null || value <= 0) return;

                    final updated = _wallet.copyWith(targetAmount: value);
                    setState(() => _wallet = updated);
                    widget.onUpdate?.call(updated);

                    Navigator.pop(context);
                  },
                  child: const Text('Save Target'),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildSetTargetButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: OutlinedButton.icon(
        icon: const Icon(Iconsax.flag),
        label: const Text('Set a Target'),
        onPressed: _showSetTargetDialog,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        children: [
          Row(
            children: [
              RepaintBoundary(
                child: ClipOval(child: buildWalletIcon(_wallet.iconBytes)),
              ),

              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _wallet.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(_wallet.category),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _showEditWallet(context),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteWallet(context),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Text(
            _wallet.balance.toStringAsFixed(2),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 20),

          _buildTargetSection(),

          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _action(
                'Add funds',
                Icons.add,
                () => _showAmountDialog(
                  context,
                  title: 'Add Funds',
                  onConfirm: _handleAddMoney,
                ),
              ),
              _action(
                'Return funds',
                Icons.arrow_downward,
                () => _showAmountDialog(
                  context,
                  title: 'Return Funds',
                  onConfirm: _handleReturnMoney,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: _wallet.transactions.length,
              itemBuilder: (_, i) {
                final t = _wallet.transactions[i];
                return ListTile(
                  title: Text(t.description),
                  subtitle: Text(t.date.toString()),
                  trailing: Text(
                    '${t.isIncome ? '+' : '-'}${t.amount}',
                    style: TextStyle(
                      color: t.isIncome ? Colors.green : Colors.red,
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

  Widget _action(String label, IconData icon, VoidCallback onTap) {
    return Column(
      children: [IconButton(icon: Icon(icon), onPressed: onTap), Text(label)],
    );
  }

  void _showAmountDialog(
    BuildContext context, {
    required String title,
    required Function(double amount) onConfirm,
  }) {
    final amountController = TextEditingController();
    String? errorText;

    final SubWalletController mainController = Get.find<SubWalletController>();

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter amount',
                      errorText: errorText,
                    ),
                  ),

                  if (title == 'Add Funds')
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Available main balance: ${mainController.luvpayBal.value}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final value = double.tryParse(amountController.text.trim());

                    if (value == null || value <= 0) {
                      setState(() {
                        errorText = 'Enter a valid amount';
                      });
                      return;
                    }

                    if (title == 'Add Funds' &&
                        value > mainController.numericBalance.value) {
                      setState(() {
                        errorText = 'Insufficient main balance';
                      });
                      return;
                    }

                    if (title == 'Return Funds' && value > _wallet.balance) {
                      setState(() {
                        errorText = 'Amount exceeds subwallet balance';
                      });
                      return;
                    }

                    onConfirm(value);
                    Navigator.pop(context);
                  },
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
