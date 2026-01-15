// ignore_for_file: use_build_context_synchronously

import 'dart:typed_data';

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
    CustomDialogStack.showConfirmation(
      context,
      "Delete Wallet",
      'Are you sure you want to delete "${_wallet.name}"?'
          '${_wallet.balance > 0 ? '\n\nBalance of ${_wallet.balance.toStringAsFixed(2)} will be returned to main wallet.' : ''}',
      () => Get.back(),
      () async {
        Get.back();

        final deleteResult = await mainController.deleteSubWallet(_wallet.id);

        if (deleteResult["success"] == true) {
          if (mounted) Navigator.of(context).pop();

          final overlayCtx = Get.overlayContext ?? context;
          CustomDialogStack.showSuccess(
            overlayCtx,
            "Success",
            deleteResult["message"] ?? "Wallet deleted successfully!",
            () async {
              Get.back();
              Get.back();

              await Future.delayed(const Duration(milliseconds: 800));
              widget.onDelete?.call();
            },
          );
        } else {
          final overlayCtx = Get.overlayContext ?? context;
          CustomDialogStack.showError(
            overlayCtx,
            "luvpay",
            deleteResult["error"] ?? "Failed to delete wallet",
            () => Get.back(),
          );
        }
      },
      leftText: "Cancel",
      rightText: "Delete",
      isAllBlueColor: false,
      rightTextColor: AppColorV2.incorrectState,
      rightBtnColor: AppColorV2.incorrectState.withAlpha(20),
    );
  }

  @override
  Widget build(BuildContext context) {
    final iconBytes =
        _wallet.imageBase64 != null && _wallet.imageBase64!.isNotEmpty
            ? decodeBase64Safe(_wallet.imageBase64!)
            : null;

    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.78,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        decoration: BoxDecoration(
          color: AppColorV2.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Container(
              width: 46,
              height: 5,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(25),
                borderRadius: BorderRadius.circular(99),
              ),
            ),

            _HeaderCard(
              wallet: _wallet,
              iconBytes: iconBytes,
              onEdit: () => _showEditWallet(context),
              onDelete: () => _deleteWallet(context),
            ),

            const SizedBox(height: 14),

            _BalanceCard(
              balanceText: "₱ ${_wallet.balance.toStringAsFixed(2)}",
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: _ActionPill(
                    label: "Add funds",
                    icon: Iconsax.add_circle,
                    filled: true,
                    onTap: _openAddDialog,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionPill(
                    label: "Move back",
                    icon: Iconsax.arrow_down_2,
                    filled: false,
                    onTap: _openMoveDialog,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Expanded(
              child: FutureBuilder<List<Transaction>>(
                future: _txFuture,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snap.hasError) {
                    return const _EmptyState(
                      icon: Iconsax.warning_2,
                      title: "Something went wrong",
                      subtitle: "Failed to load transactions",
                    );
                  }

                  final txns = snap.data ?? <Transaction>[];

                  if (txns.isEmpty) {
                    return const _EmptyState(
                      icon: Iconsax.receipt_text,
                      title: "No transactions yet",
                      subtitle: "Add or return funds to see transactions here",
                    );
                  }

                  return ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(top: 2, bottom: 4),
                    itemCount: txns.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final t = txns[i];
                      final isIn = t.amount >= 0;
                      final sign = isIn ? '+' : '-';

                      return InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => TransferDetailsModal(data: t.raw),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.black.withAlpha(14),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(10),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  color: (isIn ? Colors.green : Colors.red)
                                      .withAlpha(18),
                                ),
                                child: Icon(
                                  isIn
                                      ? Iconsax.arrow_up_1
                                      : Iconsax.arrow_down_1,
                                  color: isIn ? Colors.green : Colors.red,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t.description,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    DefaultText(
                                      fontSize: 11,
                                      text: _formatDate(t.date),
                                      color: Colors.black.withAlpha(130),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '$sign₱ ${t.amount.abs().toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: isIn ? Colors.green : Colors.red,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Icon(
                                    Iconsax.arrow_right_3,
                                    size: 16,
                                    color: Colors.black.withAlpha(90),
                                  ),
                                ],
                              ),
                            ],
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
      barrierDismissible: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            final isAdd = title.toLowerCase().contains('add');
            final helperColor = Colors.black.withAlpha(120);

            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 24,
              ),
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                decoration: BoxDecoration(
                  color: AppColorV2.background,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.black.withAlpha(16)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(18),
                      blurRadius: 26,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => Navigator.of(context).pop(),
                          child: Ink(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.black.withAlpha(10),
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: Colors.black.withAlpha(130),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(140),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color:
                              errorText != null
                                  ? AppColorV2.incorrectState.withAlpha(140)
                                  : Colors.black.withAlpha(16),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Amount",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.black.withAlpha(150),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: amountController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (_) => _revalidate(setState),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              hintText: "0.00",
                              hintStyle: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.black.withAlpha(60),
                              ),
                              prefixIcon: Padding(
                                padding: const EdgeInsets.only(
                                  left: 2,
                                  right: 6,
                                ),
                                child: Center(
                                  widthFactor: 0,
                                  child: Text(
                                    "₱",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black.withAlpha(160),
                                    ),
                                  ),
                                ),
                              ),
                              prefixIconConstraints: const BoxConstraints(
                                minWidth: 22,
                              ),
                            ),
                          ),

                          if (errorText != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Iconsax.info_circle,
                                  size: 16,
                                  color: AppColorV2.incorrectState,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    errorText!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColorV2.incorrectState,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Obx(
                        () => Text(
                          'Available main balance: ${mainController.luvpayBal.value}',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: helperColor,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => Navigator.of(context).pop(),
                              child: Ink(
                                height: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: Colors.black.withAlpha(10),
                                  border: Border.all(
                                    color: Colors.black.withAlpha(16),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    "Cancel",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: Colors.black.withAlpha(160),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap:
                                  canConfirm
                                      ? () async {
                                        final value = _parseAmount();
                                        Navigator.of(context).pop();
                                        await onConfirm(value);
                                      }
                                      : null,
                              child: Ink(
                                height: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color:
                                      canConfirm
                                          ? AppColorV2.lpBlueBrand
                                          : AppColorV2.lpBlueBrand.withAlpha(
                                            90,
                                          ),
                                  boxShadow:
                                      canConfirm
                                          ? [
                                            BoxShadow(
                                              color: AppColorV2.lpBlueBrand
                                                  .withAlpha(30),
                                              blurRadius: 18,
                                              offset: const Offset(0, 10),
                                            ),
                                          ]
                                          : [],
                                ),
                                child: Center(
                                  child: Text(
                                    isAdd ? "Add" : "Confirm",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color: AppColorV2.background,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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

class _HeaderCard extends StatelessWidget {
  final Wallet wallet;
  final Uint8List? iconBytes;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _HeaderCard({
    required this.wallet,
    required this.iconBytes,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withAlpha(14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: AppColorV2.lpBlueBrand.withAlpha(14),
            ),
            child: Center(
              child: ClipOval(
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: buildWalletIcon(iconBytes),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DefaultText(
                  text: wallet.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                DefaultText(
                  text: wallet.categoryTitle,
                  fontSize: 12,
                  color: Colors.black.withAlpha(140),
                ),
              ],
            ),
          ),
          _IconAction(icon: Iconsax.edit_2, onTap: onEdit),
          const SizedBox(width: 8),
          _IconAction(icon: Iconsax.trash, onTap: onDelete, danger: true),
        ],
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool danger;

  const _IconAction({
    required this.icon,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColorV2.incorrectState : AppColorV2.lpBlueBrand;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Ink(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: color.withAlpha(14),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final String balanceText;

  const _BalanceCard({required this.balanceText});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColorV2.lpBlueBrand.withAlpha(245),
            AppColorV2.lpBlueBrand.withAlpha(170),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColorV2.lpBlueBrand.withAlpha(30),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Subwallet balance",
            style: TextStyle(
              color: Colors.white.withAlpha(210),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            balanceText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  const _ActionPill({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = filled ? AppColorV2.lpBlueBrand : Colors.transparent;
    final fg = filled ? AppColorV2.background : AppColorV2.lpBlueBrand;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          height: 52,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  filled
                      ? Colors.transparent
                      : AppColorV2.lpBlueBrand.withAlpha(90),
            ),
            boxShadow:
                filled
                    ? [
                      BoxShadow(
                        color: AppColorV2.lpBlueBrand.withAlpha(30),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ]
                    : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: fg, size: 20),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.black.withAlpha(14)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 58, color: Colors.grey.shade400),
            const SizedBox(height: 14),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}
