// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:luvpay/shared/dialogs/dialogs.dart';
import '../../../shared/widgets/luvpay_text.dart';
import '../../../shared/widgets/neumorphism.dart';

import '../../../features/subwallet/controller.dart';
import '../../../features/subwallet/view.dart';
import '../../../features/subwallet/utils/add_wallet_modal.dart';
import '../../../features/subwallet/utils/transaction_modal.dart';

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

  String get _targetKey {
    final normalizedId = int.tryParse(_wallet.id)?.toString() ?? _wallet.id;
    return 'subwallet_target_$normalizedId';
  }

  @override
  void initState() {
    super.initState();
    _wallet = widget.wallet;
    _txFuture = _loadTx();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLocalTarget();
    });
  }

  Future<void> _loadLocalTarget() async {
    final sp = await SharedPreferences.getInstance();
    final v = sp.getDouble(_targetKey);

    if (!mounted) return;
    setState(() {
      _wallet = _wallet.copyWith(targetAmount: v);
    });
  }

  Future<void> _saveLocalTarget(double? targetAmount) async {
    final sp = await SharedPreferences.getInstance();

    if (targetAmount == null) {
      await sp.remove(_targetKey);
    } else {
      await sp.setDouble(
        _targetKey,
        double.parse(targetAmount.toStringAsFixed(2)),
      );
    }

    if (!mounted) return;
    setState(() {
      _wallet = _wallet.copyWith(targetAmount: targetAmount);
    });
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

    await _loadLocalTarget();
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
        CustomDialogStack.showConnectionLost(ctx, () {
          Get.back();
          Get.back();
        });
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

  Future<void> _openTargetDialog() async {
    _showTargetDialog(
      context,
      title: (_wallet.targetAmount ?? 0) > 0 ? 'Update target' : 'Set target',
      onConfirm: (value) async => _saveLocalTarget(value),
      onRemove: () async => _saveLocalTarget(null),
    );
  }

  Color _border(ColorScheme cs, bool isDark, [double? o]) =>
      cs.outlineVariant.withOpacity(o ?? (isDark ? 0.08 : 0.22));

  Color _tileBg(ColorScheme cs) => cs.surfaceContainerHighest;

  void _showTargetDialog(
    BuildContext context, {
    required String title,
    required Future<void> Function(double amount) onConfirm,
    required Future<void> Function() onRemove,
  }) {
    final amountCtrl = TextEditingController(
      text:
          (_wallet.targetAmount ?? 0) > 0
              ? (_wallet.targetAmount!).toStringAsFixed(2)
              : '',
    );

    String? errorText;
    bool canConfirm = amountCtrl.text.trim().isNotEmpty;

    double _parse() {
      final raw = amountCtrl.text.trim().replaceAll(',', '');
      return double.tryParse(raw) ?? 0.0;
    }

    void _revalidate(StateSetter setState) {
      final v = _parse();

      if (v <= 0) {
        setState(() {
          errorText = null;
          canConfirm = false;
        });
        return;
      }

      if (v < _wallet.balance) {
        setState(() {
          errorText = 'Target must be ≥ current balance';
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
            final theme = Theme.of(context);
            final cs = theme.colorScheme;
            final isDark = theme.brightness == Brightness.dark;

            final hasTarget = (_wallet.targetAmount ?? 0) > 0;

            final dialogBg = cs.surface;
            final surface2 = _tileBg(cs);
            final stroke = _border(cs, isDark);
            final titleColor = cs.onSurface;
            final subColor = cs.onSurface.withOpacity(0.72);

            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 24,
              ),
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                decoration: BoxDecoration(
                  color: dialogBg,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isDark ? Colors.transparent : stroke,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.22 : 0.10),
                      blurRadius: isDark ? 20 : 26,
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
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: titleColor,
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
                              color: cs.onSurface.withOpacity(
                                isDark ? 0.10 : 0.06,
                              ),
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: cs.onSurface.withOpacity(0.75),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                      decoration: BoxDecoration(
                        color: surface2,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color:
                              errorText != null
                                  ? cs.error.withOpacity(0.55)
                                  : stroke,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Target amount",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: subColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: amountCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (_) => _revalidate(setState),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: titleColor,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              hintText: "0.00",
                              hintStyle: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: cs.onSurface.withOpacity(0.35),
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
                                      color: cs.onSurface.withOpacity(0.80),
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
                                  color: cs.error,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    errorText!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: cs.error,
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
                      child: Text(
                        'Current balance: ₱ ${_wallet.balance.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface.withOpacity(0.65),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    Row(
                      children: [
                        if (hasTarget) ...[
                          Expanded(
                            child: LuvNeuPress.rectangle(
                              depth: isDark ? 0.55 : 1.4,
                              pressedDepth: isDark ? -0.25 : -0.75,
                              overlayOpacity: isDark ? 0.0 : 0.02,
                              borderColor: isDark ? Colors.transparent : stroke,
                              radius: BorderRadius.circular(16),
                              onTap: () async {
                                Navigator.of(context).pop();
                                await onRemove();
                                await _loadLocalTarget();
                              },
                              background: cs.error.withOpacity(0.10),

                              child: SizedBox(
                                height: 50,
                                child: Center(
                                  child: Text(
                                    "Remove",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color: cs.error,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: LuvNeuPress.rectangle(
                            depth: isDark ? 0.55 : 1.4,
                            pressedDepth: isDark ? -0.25 : -0.75,
                            overlayOpacity: isDark ? 0.0 : 0.02,
                            borderColor: isDark ? Colors.transparent : stroke,
                            radius: BorderRadius.circular(16),
                            onTap: () => Navigator.of(context).pop(),

                            background: cs.surfaceContainerHighest,

                            child: SizedBox(
                              height: 50,
                              child: Center(
                                child: Text(
                                  "Cancel",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: cs.onSurface.withOpacity(0.75),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: LuvNeuPress.rectangle(
                            depth: isDark ? 0.55 : 1.4,
                            pressedDepth: isDark ? -0.25 : -0.75,
                            overlayOpacity: isDark ? 0.0 : 0.02,
                            borderColor: isDark ? Colors.transparent : stroke,
                            radius: BorderRadius.circular(16),
                            onTap:
                                canConfirm
                                    ? () async {
                                      final v = _parse();
                                      Navigator.of(context).pop();
                                      await onConfirm(v);
                                    }
                                    : null,

                            background:
                                canConfirm
                                    ? cs.primary
                                    : cs.primary.withOpacity(0.45),

                            child: SizedBox(
                              height: 50,
                              child: Center(
                                child: Text(
                                  "Save",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: cs.onPrimary,
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

  Future<void> _showEditWallet(BuildContext context) async {
    final otherWallets =
        widget.allWallets.where((w) => w.id != _wallet.id).toList();

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    CustomDialogStack.showConfirmation(
      context,
      "Delete SubWallet",
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
            deleteResult["message"] ?? "SubWallet deleted successfully!",
            () async {
              Get.back();
              Get.back();

              await Future.delayed(const Duration(milliseconds: 200));
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
      rightTextColor: cs.error,
      rightBtnColor: cs.error.withOpacity(0.10),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final bg = cs.surface;
    final stroke = _border(cs, isDark);

    final iconBytes =
        _wallet.imageBase64 != null && _wallet.imageBase64!.isNotEmpty
            ? decodeBase64Safe(_wallet.imageBase64!)
            : null;

    return SafeArea(
      top: false,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.78,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Container(
              width: 46,
              height: 5,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: cs.onSurface.withOpacity(0.15),
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

            const SizedBox(height: 12),
            // TargetCard(
            //   balance: _wallet.balance,
            //   target: _wallet.targetAmount,
            //   onTapSet: _openTargetDialog,
            // ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: LuvNeuPillButton(
                    label: "Add funds",
                    icon: Iconsax.add_circle,
                    filled: true,
                    onTap: _openAddDialog,
                    filledColor: cs.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: LuvNeuPillButton(
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
                    return Center(
                      child: CircularProgressIndicator(color: cs.primary),
                    );
                  }

                  if (snap.hasError) {
                    return _EmptyState(
                      icon: Iconsax.warning_2,
                      title: "Something went wrong",
                      subtitle: "Failed to load transactions",
                    );
                  }

                  final txns = snap.data ?? <Transaction>[];

                  if (txns.isEmpty) {
                    return _EmptyState(
                      icon: Iconsax.receipt_text,
                      title: "No transactions yet",
                      subtitle: "Add funds to see transactions here",
                    );
                  }

                  final tileBg = _tileBg(cs);

                  return ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(top: 2, bottom: 4),
                    itemCount: txns.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final t = txns[i];
                      final isIn = t.amount >= 0;
                      final sign = isIn ? '+' : '-';

                      final accent = isIn ? cs.tertiary : cs.error;

                      return LuvNeuPress.rectangle(
                        depth: isDark ? 0.55 : 1.4,
                        pressedDepth: isDark ? -0.25 : -0.75,
                        overlayOpacity: isDark ? 0.0 : 0.02,
                        borderColor:
                            isDark
                                ? Colors.transparent
                                : stroke.withOpacity(0.02),
                        radius: BorderRadius.circular(18),
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => TransferDetailsModal(data: t.raw),
                          );
                        },
                        background: tileBg,
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  color: accent.withOpacity(
                                    isDark ? 0.18 : 0.12,
                                  ),
                                ),
                                child: Icon(
                                  isIn
                                      ? Iconsax.arrow_up_1
                                      : Iconsax.arrow_down_1,
                                  color: accent,
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
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: cs.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    LuvpayText(
                                      fontSize: 11,
                                      text: _formatDate(t.date),
                                      color: cs.onSurface.withOpacity(0.65),
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
                                      fontWeight: FontWeight.w900,
                                      color: accent,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Icon(
                                    Iconsax.arrow_right_3,
                                    size: 16,
                                    color: cs.onSurface.withOpacity(0.45),
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
      barrierDismissible: false,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            final theme = Theme.of(context);
            final cs = theme.colorScheme;
            final isDark = theme.brightness == Brightness.dark;

            final bg = cs.surface;
            final surface2 = _tileBg(cs);
            final stroke = _border(cs, isDark);
            final helperColor = cs.onSurface.withOpacity(0.65);

            final isAdd = title.toLowerCase().contains('add');

            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 24,
              ),
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isDark ? Colors.transparent : stroke,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.22 : 0.10),
                      blurRadius: isDark ? 20 : 26,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LuvpayText(
                      text: title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                      decoration: BoxDecoration(
                        color: surface2,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color:
                              errorText != null
                                  ? cs.error.withOpacity(isDark ? 0.45 : 0.55)
                                  : (isDark
                                      ? cs.onSurface.withOpacity(0.08)
                                      : stroke),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LuvpayText(
                            text: "Amount",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: cs.onSurface.withOpacity(0.70),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: amountController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (_) => _revalidate(setState),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: cs.onSurface,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              hintText: "0.00",
                              hintStyle: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: cs.onSurface.withOpacity(0.35),
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
                                      color: cs.onSurface.withOpacity(0.80),
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
                                  color: cs.error,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    errorText!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: cs.error,
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
                        () => LuvpayText(
                          text:
                              'Available main balance: ${mainController.luvpayBal.value}',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: helperColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: LuvNeuPress.rectangle(
                            depth: isDark ? 0.55 : 1.4,
                            pressedDepth: isDark ? -0.25 : -0.75,
                            overlayOpacity: isDark ? 0.0 : 0.02,
                            borderColor: isDark ? Colors.transparent : stroke,
                            radius: BorderRadius.circular(16),
                            onTap: () => Navigator.of(context).pop(),
                            background: cs.surfaceContainerHighest,

                            child: SizedBox(
                              height: 50,
                              child: Center(
                                child: LuvpayText(
                                  text: "Cancel",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: cs.onSurface.withOpacity(0.75),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: LuvNeuPress.rectangle(
                            depth: isDark ? 0.55 : 1.4,
                            pressedDepth: isDark ? -0.25 : -0.75,
                            overlayOpacity: isDark ? 0.0 : 0.02,
                            borderColor: isDark ? Colors.transparent : stroke,
                            radius: BorderRadius.circular(16),
                            onTap:
                                canConfirm
                                    ? () async {
                                      final value = _parseAmount();
                                      Navigator.of(context).pop();
                                      await onConfirm(value);
                                    }
                                    : null,

                            background:
                                canConfirm
                                    ? cs.primary
                                    : cs.primary.withOpacity(0.45),
                            child: SizedBox(
                              height: 50,
                              child: Center(
                                child: LuvpayText(
                                  text: isAdd ? "Add" : "Confirm",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: cs.onPrimary,
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
  Color _border(ColorScheme cs, bool isDark, [double? o]) =>
      cs.outlineVariant.withOpacity(o ?? (isDark ? 0.08 : 0.22));
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final radius = BorderRadius.circular(20);
    final avatarRadius = BorderRadius.circular(18);
    final stroke = _border(cs, isDark);

    final tileBg = cs.surfaceContainerHighest;

    return LuvNeuPress.rectangle(
      depth: isDark ? 0.55 : 1.4,
      pressedDepth: isDark ? -0.25 : -0.75,
      overlayOpacity: isDark ? 0.0 : 0.02,
      borderColor: isDark ? Colors.transparent : stroke,
      radius: radius,
      onTap: null,

      background: tileBg,

      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            LuvNeuPress.rectangle(
              depth: isDark ? 0.55 : 1.4,
              pressedDepth: isDark ? -0.25 : -0.75,
              background: tileBg,
              borderColor: isDark ? Colors.transparent : stroke,
              overlayOpacity: isDark ? 0.0 : 0.02,

              radius: avatarRadius,
              onTap: null,

              child: SizedBox(
                width: 52,
                height: 52,
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
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LuvpayText(
                    text: wallet.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  LuvpayText(
                    text: wallet.categoryTitle,
                    fontSize: 12,
                    color: cs.onSurface.withOpacity(0.65),
                  ),
                ],
              ),
            ),
            LuvNeuIconButton(icon: Iconsax.edit_2, onTap: onEdit),
            const SizedBox(width: 8),
            LuvNeuIconButton(
              icon: Iconsax.trash,
              onTap: onDelete,
              danger: true,
            ),
          ],
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
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final radius = BorderRadius.circular(22);
    final stroke = cs.outlineVariant.withOpacity(isDark ? 0.08 : 0.22);

    return LuvNeuPress.rectangle(
      depth: isDark ? 0.55 : 1.4,
      pressedDepth: isDark ? -0.25 : -0.75,
      overlayOpacity: isDark ? 0.0 : 0.02,
      borderColor: isDark ? Colors.transparent : stroke,
      radius: radius,
      onTap: null,
      child: ClipRRect(
        borderRadius: radius,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cs.primary.withOpacity(0.98),
                cs.primary.withOpacity(0.70),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Subwallet balance",
                style: TextStyle(
                  color: cs.onPrimary.withOpacity(0.86),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                balanceText,
                style: TextStyle(
                  color: cs.onPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.2,
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final radius = BorderRadius.circular(22);
    final stroke = cs.outlineVariant.withOpacity(isDark ? 0.22 : 0.35);

    return Center(
      child: LuvNeuPress.rectangle(
        radius: radius,
        depth: isDark ? 0.55 : 1.4,
        pressedDepth: isDark ? -0.25 : -0.75,
        overlayOpacity: isDark ? 0.0 : 0.02,
        borderColor: isDark ? Colors.transparent : stroke,
        onTap: null,
        background: cs.surfaceContainerHighest,

        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 58, color: cs.onSurface.withOpacity(0.30)),
              const SizedBox(height: 14),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: cs.onSurface.withOpacity(0.82),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withOpacity(0.55),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
