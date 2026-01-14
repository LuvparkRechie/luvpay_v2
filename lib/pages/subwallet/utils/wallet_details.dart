// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:luvpay/custom_widgets/alert_dialog.dart';
import 'package:luvpay/custom_widgets/app_color_v2.dart';
import '../../../custom_widgets/custom_text_v2.dart';
import '../controller.dart';
import '../view.dart';
import 'add_wallet_modal.dart';
import 'transaction_modal.dart';

class WalletDetailsModal extends StatefulWidget {
  final Wallet wallet;
  final List<Wallet> allWallets;
  final VoidCallback? onDelete;
  final Function(Wallet updatedWallet)? onUpdate;
  final Function(double amount)? onAddMoney;
  final Function(double amount)? onReturnMoney;

  const WalletDetailsModal({
    super.key,
    required this.wallet,
    this.onDelete,
    this.allWallets = const [],
    this.onUpdate,
    this.onAddMoney,
    this.onReturnMoney,
  });

  @override
  State<WalletDetailsModal> createState() => _WalletDetailsModalState();
}

class _WalletDetailsModalState extends State<WalletDetailsModal> {
  late Wallet _wallet;
  final SubWalletController mainController = Get.find<SubWalletController>();
  late Future<List<Transaction>> _txFuture;

  @override
  void initState() {
    super.initState();
    _wallet = widget.wallet;
    _txFuture = _loadTx();
  }

  Future<List<Transaction>> _loadTx() {
    return mainController.fetchWalletTransactions(
      subWalletId: int.parse(_wallet.id),
    );
  }

  Future<void> _refreshWalletAndTx() async {
    await mainController.getUserSubWallets();
    await mainController.luvpayBalance();

    final updated = mainController.getSubWalletById(_wallet.id);
    if (!mounted) return;

    setState(() {
      if (updated != null) _wallet = Wallet.fromJson(updated);
      _txFuture = _loadTx();
    });
  }

  Future<void> _handleAddMoney(double amount) async {
    amount = double.parse(amount.toStringAsFixed(2));
    if (amount <= 0) return _showSnack('Enter a valid amount');

    await mainController.luvpayBalance();
    final mainBal = mainController.numericBalance.value;
    if (amount > mainBal) return _showSnack('Insufficient main balance');

    final ok = await _runTransfer(target: "SUB", amount: amount);
    if (ok) widget.onAddMoney?.call(amount);
  }

  Future<void> _handleReturnMoney(double amount) async {
    amount = double.parse(amount.toStringAsFixed(2));
    if (amount <= 0) return _showSnack('Enter a valid amount');

    await mainController.getUserSubWallets();
    final latest = mainController.getSubWalletById(_wallet.id);

    if (latest != null && mounted) {
      setState(() => _wallet = Wallet.fromJson(latest));
    }

    if (amount > _wallet.balance) {
      return _showSnack('Amount exceeds subwallet balance');
    }

    final ok = await _runTransfer(target: "MAIN", amount: amount);
    if (ok) widget.onReturnMoney?.call(amount);
  }

  Future<bool> _runTransfer({
    required String target,
    required double amount,
  }) async {
    final ctx = Get.overlayContext ?? context;

    CustomDialogStack.showLoading(ctx);

    Map<String, dynamic> result = {};
    try {
      result = await mainController.transferSubWallet(
        subwalletId: int.tryParse(_wallet.id),
        amount: amount,
        wttarget: target,
      );
    } finally {
      if (Get.isDialogOpen == true) {
        Navigator.of(ctx, rootNavigator: true).pop();
      }
    }
    if (result["success"] == true) {
      await _refreshWalletAndTx();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        CustomDialogStack.showSuccess(
          ctx,
          "Success",
          result["message"]?.toString() ?? "Success",
          () {
            Get.back();
            Get.back();
          },
        );
      });

      return true;
    }

    final code = result["code"]?.toString();
    final err = result["error"]?.toString() ?? "Failed";

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (code == "NO_INTERNET") {
        CustomDialogStack.showConnectionLost(ctx, () => Get.back());
      } else {
        CustomDialogStack.showError(ctx, "luvpay", err, () => Get.back());
      }
    });

    return false;
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    CustomDialogStack.showInfo(context, "luvpay", msg, () => Get.back());
  }

  Future<void> _openAddDialog() async {
    _showAmountDialog(context, title: 'Add Funds', onConfirm: _handleAddMoney);
  }

  Future<void> _openMoveDialog() async {
    _showAmountDialog(
      context,
      title: 'Move funds back to main wallet',
      onConfirm: _handleReturnMoney,
    );
  }

  Future<void> _showEditWallet(BuildContext context) async {
    final otherWallets =
        widget.allWallets.where((w) => w.id != _wallet.id).toList();

    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColorV2.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder:
          (_) => AddWalletModal(
            mode: WalletModalMode.edit,
            wallet: _wallet,
            existingWallets: otherWallets,
          ),
    );

    if (result != true) return;

    await _refreshWalletAndTx();
    widget.onUpdate?.call(_wallet);
  }

  Future<void> _deleteWallet(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog.adaptive(
            title: DefaultText(text: 'Delete Wallet', style: AppTextStyle.h3),
            content: DefaultText(
              style: AppTextStyle.h3_semibold,
              text:
                  'Are you sure you want to delete "${_wallet.name}"? ${_wallet.balance > 0 ? '\n\nBalance of ${_wallet.balance.toStringAsFixed(2)} will be returned to main wallet.' : ''}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const DefaultText(text: 'Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: DefaultText(
                  text: 'Delete',
                  color: AppColorV2.incorrectState,
                ),
              ),
            ],
          ),
    );

    if (result != true) return;

    final deleteResult = await mainController.deleteSubWallet(_wallet.id);

    if (deleteResult["success"] == true) {
      if (mounted) Navigator.of(context).pop();
      widget.onDelete?.call();

      final overlayCtx = Get.overlayContext ?? context;
      CustomDialogStack.showSuccess(
        overlayCtx,
        "Success",
        deleteResult["message"] ?? 'Wallet deleted successfully!',
        () {
          Get.back();
          Get.back();
        },
      );
    } else {
      final overlayCtx = Get.overlayContext ?? context;
      CustomDialogStack.showError(
        overlayCtx,
        "luvpay",
        deleteResult["error"] ?? 'Failed to delete wallet',
        () => Get.back(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconBytes =
        _wallet.imageBase64 != null && _wallet.imageBase64!.isNotEmpty
            ? decodeBase64Safe(_wallet.imageBase64!)
            : null;

    return Container(
      padding: const EdgeInsets.all(20),
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        children: [
          Row(
            children: [
              RepaintBoundary(
                child: ClipOval(child: buildWalletIcon(iconBytes)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DefaultText(
                      text: _wallet.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    DefaultText(text: _wallet.categoryTitle),
                    if (_wallet.createdOn.isNotEmpty)
                      DefaultText(
                        text: 'Created: ${_formatDate(_wallet.createdOn)}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
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
          DefaultText(
            text: "₱ ${_wallet.balance.toStringAsFixed(2)}",
            style: AppTextStyle.h2_f26,
            color: AppColorV2.lpBlueBrand,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _action('Add funds', Icons.add, _openAddDialog),
              _action('Move funds', Icons.arrow_downward, _openMoveDialog),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: FutureBuilder<List<Transaction>>(
              future: _txFuture,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snap.hasError) {
                  return Center(
                    child: DefaultText(
                      text: 'Failed to load transactions',
                      style: AppTextStyle.paragraph1,
                    ),
                  );
                }

                final txns = snap.data ?? <Transaction>[];

                if (txns.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Iconsax.receipt_text,
                          size: 60,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No transactions yet',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add or return funds to see transactions',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: txns.length,
                  itemBuilder: (context, i) {
                    final t = txns[i];
                    final sign = t.amount >= 0 ? '+' : '-';
                    return ListTile(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => TransferDetailsModal(data: t.raw),
                        );
                      },
                      title: Text(t.description),
                      subtitle: DefaultText(
                        fontSize: 10,
                        text: _formatDate(t.date),
                      ),
                      trailing: DefaultText(
                        text: '$sign₱ ${t.amount.abs().toStringAsFixed(2)}',
                        style: TextStyle(
                          color: t.amount >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    );
                  },
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
      children: [
        IconButton(icon: Icon(icon, size: 28), onPressed: onTap),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  void _showAmountDialog(
    BuildContext context, {
    required String title,
    required Future<void> Function(double amount) onConfirm,
  }) {
    final amountController = TextEditingController();
    String? errorText;
    bool canConfirm = false;

    double _parseAmount() {
      final raw = amountController.text.trim().replaceAll(',', '');
      return double.tryParse(raw) ?? 0.0;
    }

    void _revalidate(StateSetter setState) {
      final value = _parseAmount();

      if (value <= 0) {
        setState(() {
          errorText = null;
          canConfirm = false;
        });
        return;
      }

      final isAdd = title.toLowerCase().contains('add');
      final isMove = title.toLowerCase().contains('move');

      if (isAdd && value > mainController.numericBalance.value) {
        setState(() {
          errorText = 'Insufficient main balance';
          canConfirm = false;
        });
        return;
      }

      if (isMove && value > _wallet.balance) {
        setState(() {
          errorText = 'Amount exceeds subwallet balance';
          canConfirm = false;
        });
        return;
      }

      setState(() {
        errorText = null;
        canConfirm = true;
      });
    }

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog.adaptive(
              title: Text(title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => _revalidate(setState),
                    decoration: InputDecoration(
                      prefixText: '₱ ',
                      prefixStyle: AppTextStyle.h3_semibold,
                      hintText: 'Enter amount',
                      errorText: errorText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Obx(
                      () => Text(
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
                  onPressed: () => Navigator.of(context).pop(),
                  child: const DefaultText(text: 'Cancel'),
                ),
                ElevatedButton(
                  onPressed:
                      canConfirm
                          ? () async {
                            final value = _parseAmount();
                            Navigator.of(context).pop();
                            await onConfirm(value);
                          }
                          : null,
                  child: DefaultText(
                    text: 'Confirm',
                    color: AppColorV2.background,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatDate(dynamic dateInput) {
    try {
      DateTime date;
      if (dateInput is String) {
        date = DateTime.parse(dateInput);
      } else if (dateInput is DateTime) {
        date = dateInput;
      } else {
        return dateInput.toString();
      }

      const monthNames = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];
      return '${monthNames[date.month - 1]} ${date.day}, ${date.year}';
    } catch (_) {
      return dateInput.toString();
    }
  }
}
