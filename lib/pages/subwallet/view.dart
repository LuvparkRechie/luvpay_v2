// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:luvpay/custom_widgets/luvpay/custom_scaffold.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../custom_widgets/app_color_v2.dart';
import '../../custom_widgets/custom_text_v2.dart';
import 'controller.dart';

class Wallet {
  final String id;
  final String name;
  final double balance;
  final String category;
  final String icon;
  final Color color;
  final List<Transaction> transactions;

  Wallet({
    required this.id,
    required this.name,
    required this.balance,
    required this.category,
    required this.icon,
    required this.color,
    this.transactions = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'balance': balance,
      'category': category,
      'icon': icon,
      'color': color.value,
      'transactions': transactions.map((t) => t.toJson()).toList(),
    };
  }

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id'],
      name: json['name'],
      balance: json['balance'],
      category: json['category'],
      icon: json['icon'],
      color: Color(json['color']),
      transactions:
          (json['transactions'] as List)
              .map((t) => Transaction.fromJson(t))
              .toList(),
    );
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'date': date.toIso8601String(),
      'isIncome': isIncome,
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      description: json['description'],
      amount: json['amount'],
      date: DateTime.parse(json['date']),
      isIncome: json['isIncome'],
    );
  }
}

final List<Map<String, dynamic>> categories = [
  {'name': 'Food', 'icon': Iconsax.coffee, 'color': AppColorV2.lpBlueBrand},
  {'name': 'Shopping', 'icon': Iconsax.bag_2, 'color': AppColorV2.secondary},
  {'name': 'Transport', 'icon': Iconsax.car, 'color': AppColorV2.accent},
  {
    'name': 'Entertainment',
    'icon': Iconsax.video,
    'color': AppColorV2.lpTealBrand,
  },
  {'name': 'Bills', 'icon': Iconsax.receipt, 'color': AppColorV2.success},
  {'name': 'Healthcare', 'icon': Iconsax.health, 'color': AppColorV2.warning},
  {'name': 'Education', 'icon': Iconsax.book, 'color': AppColorV2.error},
  {
    'name': 'Income',
    'icon': Iconsax.wallet_add,
    'color': AppColorV2.correctState,
  },
];

class SubWalletScreen extends StatefulWidget {
  const SubWalletScreen({super.key});

  @override
  State<SubWalletScreen> createState() => _SubWalletScreenState();
}

class _SubWalletScreenState extends State<SubWalletScreen> {
  List<Wallet> wallets = [];
  double totalBalance = 0;
  bool isLoading = true;

  final String _walletsKey = 'user_wallets';

  @override
  void initState() {
    super.initState();
    _loadWallets();
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
        wallets = walletsList.map((w) => Wallet.fromJson(w)).toList();
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

    setState(() {
      wallets.add(wallet);
      calculateTotalBalance();
    });

    _saveWallets();
    print('Wallet added successfully. Total wallets: ${wallets.length}');
  }

  void deleteWallet(String walletId) {
    setState(() {
      wallets.removeWhere((wallet) => wallet.id == walletId);
      calculateTotalBalance();
    });
    _saveWallets();
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
          isLoading
              ? Center(
                child: CircularProgressIndicator(color: AppColorV2.lpBlueBrand),
              )
              : CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DefaultText(
                            text: 'Total Subwallet Balance',
                            color: AppColorV2.lpBlueBrand,
                          ),
                          const SizedBox(height: 8),
                          DefaultText(
                            text: totalBalance.toStringAsFixed(2),
                            style: AppTextStyle.h2,
                            color: AppColorV2.lpBlueBrand,
                          ),
                        ],
                      ),
                    ),
                  ),
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

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DefaultText(
                            text: 'Categories',
                            style: AppTextStyle.h3_f22,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 100,
                            child: ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              scrollDirection: Axis.horizontal,
                              itemCount: categories.length,
                              itemBuilder: (context, index) {
                                final category = categories[index];
                                return Padding(
                                  padding: const EdgeInsets.only(right: 16),
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: category['color'] as Color,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: (category['color']
                                                      as Color)
                                                  .withOpacity(0.3),
                                              blurRadius: 8,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          category['icon'] as IconData,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      DefaultText(text: category['name']),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
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
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              wallet.color.withOpacity(0.9),
              wallet.color.withOpacity(0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: wallet.color.withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 1,
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(wallet.icon, style: const TextStyle(fontSize: 24)),
                  Expanded(
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DefaultText(
                        text: wallet.category,
                        style: AppTextStyle.body1,
                        color: AppColorV2.background,
                        minFontSize: 8,
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
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                  ),
                  const SizedBox(height: 4),
                  DefaultText(
                    text: wallet.balance.toStringAsFixed(2),
                    style: AppTextStyle.h2.copyWith(
                      color: Colors.white,
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
      builder: (context) {
        return WalletDetailsModal(
          wallet: wallet,
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
  const AddWalletModal({super.key});

  @override
  State<AddWalletModal> createState() => _AddWalletModalState();
}

class _AddWalletModalState extends State<AddWalletModal> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _balanceController = TextEditingController();
  String _selectedCategory = 'Food';
  Color _selectedColor = AppColorV2.lpBlueBrand;
  String _selectedIcon = '🍔';

  final List<Map<String, dynamic>> _icons = [
    {'emoji': '🍔', 'label': 'Food'},
    {'emoji': '🛍️', 'label': 'Shopping'},
    {'emoji': '🚗', 'label': 'Transport'},
    {'emoji': '🎬', 'label': 'Entertainment'},
    {'emoji': '💼', 'label': 'Work'},
    {'emoji': '🏠', 'label': 'Home'},
    {'emoji': '💊', 'label': 'Health'},
    {'emoji': '📚', 'label': 'Education'},
  ];

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
            DefaultText(text: 'Create New Wallet', style: AppTextStyle.popup),
            const SizedBox(height: 30),
            TextField(
              controller: _nameController,
              style: AppTextStyle.h3.copyWith(
                color: AppColorV2.primaryTextColor,
              ),
              maxLength: 15,
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
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _balanceController,
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
                labelText: 'Initial Balance',
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
              ),
            ),
            const SizedBox(height: 20),
            DefaultText(
              text: 'Select Category',
              style: AppTextStyle.h3.copyWith(
                color: AppColorV2.primaryTextColor,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isSelected = _selectedCategory == category['name'];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = category['name'];
                        _selectedColor = category['color'] as Color;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? category['color'] as Color
                                : AppColorV2.pastelBlueAccent,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color:
                              isSelected
                                  ? category['color'] as Color
                                  : AppColorV2.boxStroke,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            category['icon'] as IconData,
                            color:
                                isSelected
                                    ? Colors.white
                                    : category['color'] as Color,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          DefaultText(
                            text: category['name'],
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
            ),
            const SizedBox(height: 20),
            DefaultText(
              text: 'Select Icon',
              style: AppTextStyle.h3.copyWith(
                color: AppColorV2.primaryTextColor,
              ),
            ),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _icons.length,
              itemBuilder: (context, index) {
                final icon = _icons[index];
                final isSelected = _selectedIcon == icon['emoji'];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedIcon = icon['emoji'];
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? _selectedColor
                              : AppColorV2.pastelBlueAccent,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color:
                            isSelected ? _selectedColor : AppColorV2.boxStroke,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        icon['emoji'],
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  if (_nameController.text.isNotEmpty &&
                      _balanceController.text.isNotEmpty) {
                    if (_nameController.text.length > 15) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: DefaultText(
                            text: 'Wallet name must be 15 characters or less',
                          ),
                        ),
                      );
                      return;
                    }

                    final balanceStr = _balanceController.text;
                    final beforeDecimal = balanceStr.split('.')[0];
                    if (beforeDecimal.length > 9) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: DefaultText(
                            text: 'Balance cannot exceed 9 digits',
                          ),
                        ),
                      );
                      return;
                    }

                    try {
                      final balance = double.parse(balanceStr);
                      if (balance > 999999999.99) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: DefaultText(
                              text: 'Balance cannot exceed 999,999,999.99',
                            ),
                          ),
                        );
                        return;
                      }

                      final newWallet = Wallet(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: _nameController.text,
                        balance: balance,
                        category: _selectedCategory,
                        icon: _selectedIcon,
                        color: _selectedColor,
                        transactions: [],
                      );

                      _nameController.clear();
                      _balanceController.clear();

                      Navigator.of(context).pop(newWallet);
                    } catch (e) {
                      print('Error parsing balance: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: DefaultText(
                            text: 'Please enter a valid balance',
                          ),
                        ),
                      );
                    }
                  } else {
                    print('Fields are empty');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: DefaultText(text: 'Please fill all fields'),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 2,
                ),
                child: DefaultText(
                  text: 'Create Wallet',
                  style: AppTextStyle.textButton,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WalletDetailsModal extends StatelessWidget {
  final Wallet wallet;
  final VoidCallback? onDelete;

  const WalletDetailsModal({super.key, required this.wallet, this.onDelete});

  Future<void> _deleteWallet(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: DefaultText(
              text: 'Delete Wallet',
              style: AppTextStyle.h3_f22,
            ),
            content: DefaultText(
              text: 'Are you sure you want to delete ${wallet.name}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: DefaultText(
                  text: 'Cancel',
                  style: AppTextStyle.paragraph1.copyWith(
                    color: AppColorV2.lpBlueBrand,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColorV2.incorrectState,
                ),
                child: DefaultText(
                  text: 'Delete',
                  style: AppTextStyle.textButton,
                ),
              ),
            ],
          ),
    );

    if (result == true && onDelete != null) {
      onDelete!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
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
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: wallet.color,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: Text(
                    wallet.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DefaultText(text: wallet.name, style: AppTextStyle.h3_f22),
                    DefaultText(
                      text: wallet.category,
                      style: AppTextStyle.paragraph2,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _deleteWallet(context),
                icon: Icon(Iconsax.trash, color: AppColorV2.incorrectState),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColorV2.pastelBlueAccent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColorV2.boxStroke),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(Iconsax.add, 'Add Money', wallet.color),
                _buildActionButton(
                  Iconsax.arrow_up,
                  'Send',
                  AppColorV2.lpBlueBrand,
                ),
                _buildActionButton(
                  Iconsax.chart_2,
                  'Stats',
                  AppColorV2.success,
                ),
                _buildActionButton(
                  Iconsax.setting,
                  'Settings',
                  AppColorV2.bodyTextColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    DefaultText(
                      text: 'Recent Transactions',
                      style: AppTextStyle.h3_f22,
                    ),
                    DefaultText(
                      text: wallet.balance.toStringAsFixed(2),
                      style: AppTextStyle.h3.copyWith(
                        color: AppColorV2.lpBlueBrand,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child:
                      wallet.transactions.isEmpty
                          ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Iconsax.receipt,
                                  size: 60,
                                  color: AppColorV2.boxStroke,
                                ),
                                const SizedBox(height: 16),
                                DefaultText(
                                  text: 'No transactions yet',
                                  style: AppTextStyle.paragraph1,
                                ),
                                DefaultText(
                                  text: 'Add money or make transactions',
                                  style: AppTextStyle.paragraph2,
                                ),
                              ],
                            ),
                          )
                          : ListView.builder(
                            itemCount: wallet.transactions.length,
                            itemBuilder: (context, index) {
                              final transaction = wallet.transactions[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColorV2.background,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColorV2.boxStroke,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color:
                                            transaction.isIncome
                                                ? AppColorV2.correctState
                                                    .withOpacity(0.1)
                                                : AppColorV2.incorrectState
                                                    .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        transaction.isIncome
                                            ? Iconsax.arrow_down
                                            : Iconsax.arrow_up,
                                        color:
                                            transaction.isIncome
                                                ? AppColorV2.correctState
                                                : AppColorV2.incorrectState,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          DefaultText(
                                            text: transaction.description,
                                            style: AppTextStyle.h3,
                                          ),
                                          const SizedBox(height: 4),
                                          DefaultText(
                                            text:
                                                '${transaction.date.day}/${transaction.date.month}/${transaction.date.year}',
                                            style: AppTextStyle.paragraph2,
                                          ),
                                        ],
                                      ),
                                    ),
                                    DefaultText(
                                      text:
                                          '${transaction.isIncome ? '+' : '-'}${transaction.amount.toStringAsFixed(2)}',
                                      style: AppTextStyle.h3.copyWith(
                                        color:
                                            transaction.isIncome
                                                ? AppColorV2.correctState
                                                : AppColorV2.incorrectState,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label,
    Color color, {
    VoidCallback? onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color),
          ),
        ),
        const SizedBox(height: 8),
        DefaultText(
          text: label,
          style: AppTextStyle.paragraph2.copyWith(fontSize: 12),
        ),
      ],
    );
  }
}
