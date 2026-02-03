// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:luvpay/custom_widgets/alert_dialog.dart';
import 'package:luvpay/custom_widgets/custom_text_v2.dart';
import 'package:luvpay/custom_widgets/upper_case_formatter.dart';

import '../../../custom_widgets/app_color_v2.dart';
import '../../../custom_widgets/luvpay/neumorphism.dart';
import '../controller.dart';
import '../view.dart';

class AddWalletModal extends StatefulWidget {
  final WalletModalMode mode;
  final Wallet? wallet;
  final List<Wallet>? existingWallets;
  final VoidCallback? onWalletCreated;

  const AddWalletModal({
    super.key,
    this.mode = WalletModalMode.create,
    this.wallet,
    this.existingWallets,
    this.onWalletCreated,
  });

  @override
  AddWalletModalState createState() => AddWalletModalState();
}

class AddWalletModalState extends State<AddWalletModal> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _balanceController = TextEditingController();

  String? _selectedCategoryId;
  String? _selectedCategoryName;
  Color? _selectedColor;

  String? _nameError;
  String? _balanceError;
  String? _categoryError;

  final FocusNode _balanceFocusNode = FocusNode();

  final SubWalletController controller = Get.find<SubWalletController>();

  List<Wallet> existingWallets = [];
  List<Map<String, dynamic>> _availableCategories = [];

  Uint8List? _selectedIconBytes;
  final Map<String, Uint8List> _iconCache = {};

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    if (widget.existingWallets != null) {
      existingWallets = widget.existingWallets!;
    }

    if (widget.mode == WalletModalMode.edit && widget.wallet != null) {
      final w = widget.wallet!;
      _nameController.text = w.name;
      _selectedCategoryId = null;
      _selectedCategoryName = null;
      _selectedColor = null;
      _selectedIconBytes = null;
    }

    _balanceFocusNode.addListener(_validateBalanceOnBlur);

    if (widget.mode == WalletModalMode.create) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(_loadCategories);
      });
    }
  }

  void _loadCategories() {
    _availableCategories = List<Map<String, dynamic>>.from(
      controller.categoryList,
    );
    if (_availableCategories.isEmpty) return;

    if (_selectedCategoryId == null) {
      final first = _availableCategories.first;
      final categoryId = first['category_id']?.toString() ?? '';
      final categoryName = first['category_title']?.toString() ?? 'Unknown';

      _selectedCategoryId = categoryId;
      _selectedCategoryName = categoryName;

      if (first['color'] is int) {
        _selectedColor = Color(first['color']);
      } else if (first['color'] is String) {
        _selectedColor = _getColorFromString(first['color']);
      } else {
        _selectedColor = AppColorV2.lpBlueBrand;
      }

      final imageBase64 = first['image_base64']?.toString() ?? '';
      if (imageBase64.isNotEmpty) {
        try {
          final clean = imageBase64.replaceAll(RegExp(r'\s'), '');
          _selectedIconBytes = base64.decode(clean);
          _iconCache[categoryId] = _selectedIconBytes!;
        } catch (_) {
          _selectedIconBytes = null;
        }
      }
    }
  }

  @override
  void dispose() {
    _balanceFocusNode.removeListener(_validateBalanceOnBlur);
    _balanceFocusNode.dispose();
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  String? _validateCategory(String? categoryId) {
    if (categoryId == null || categoryId.isEmpty) return 'Category is required';
    return null;
  }

  void _validateBalanceOnBlur() {
    if (!_balanceFocusNode.hasFocus) {
      setState(() => _balanceError = _validateBalance(_balanceController.text));
    }
  }

  String? _validateName(String value) {
    final raw = value.trim();
    if (raw.isEmpty) return 'SubWallet name is required';
    if (raw.length < 3) return 'SubWallet name must be at least 3 characters';
    if (raw.length > 15) return 'SubWallet name must be 15 characters or less';

    final input = _normalizeName(raw);

    if (widget.mode == WalletModalMode.create) {
      final hasDuplicate = existingWallets.any(
        (w) => _normalizeName(w.name) == input,
      );
      if (hasDuplicate) return 'A subwallet with this name already exists';
    }

    if (widget.mode == WalletModalMode.edit && widget.wallet != null) {
      final currentId = widget.wallet!.id;
      final hasDuplicate = existingWallets.any(
        (w) => w.id != currentId && _normalizeName(w.name) == input,
      );
      if (hasDuplicate) return 'A subwallet with this name already exists';
    }

    return null;
  }

  String _normalizeName(String s) =>
      s.trim().replaceAll(RegExp(r'\s+'), ' ').toUpperCase();

  void _validateCategoryOnChange(String categoryId) {
    setState(() => _categoryError = _validateCategory(categoryId));
  }

  void _validateNameOnChange(String value) {
    setState(() => _nameError = _validateName(value));
  }

  String? _validateBalance(String value) {
    if (value.trim().isEmpty) return null;

    final balanceStr = value.trim();
    if (balanceStr.startsWith('0') && !balanceStr.startsWith('0.')) {
      return 'Amount cannot start with 0';
    }

    final beforeDecimal = balanceStr.split('.')[0];
    if (beforeDecimal.length > 9) return 'Balance cannot exceed 9 digits';

    try {
      final balance = double.parse(balanceStr);

      if (balance < 0) return 'Balance cannot be negative';
      if (balance > 999999999.99) return 'Balance cannot exceed 999,999,999.99';
      if (balance > controller.numericBalance.value)
        return 'Insufficient main balance';
      return null;
    } catch (_) {
      return 'Please enter a valid balance';
    }
  }

  void _validateBalanceOnChange(String value) {
    setState(() => _balanceError = _validateBalance(value));
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

  Widget _softCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(12),
    BorderRadius radius = const BorderRadius.all(Radius.circular(14)),
  }) {
    return Neumorphic(
      style: LuvNeu.card(
        radius: radius,
        depth: 1.6,
        pressedDepth: -0.8,
        color: AppColorV2.background,
        borderColor: Colors.black.withAlpha(14),
        borderWidth: 1,
      ),
      child: Padding(padding: padding, child: child),
    );
  }

  Widget _categoryChip({
    required bool isSelected,
    required Color color,
    required Widget iconWidget,
    required String label,
    required VoidCallback onTap,
  }) {
    final radius = BorderRadius.circular(15);

    return LuvNeuPress(
      onTap: onTap,
      radius: radius,
      depth: 1.2,
      pressedDepth: -0.6,
      background: isSelected ? color.withOpacity(.12) : AppColorV2.background,
      overlayOpacity: 0.03,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipOval(child: iconWidget),
            const SizedBox(width: 8),
            DefaultText(
              text: label,
              style: AppTextStyle.h3.copyWith(
                color: AppColorV2.primaryTextColor,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _primaryButton({
    required bool enabled,
    required bool loading,
    required String text,
    required VoidCallback onTap,
  }) {
    final radius = BorderRadius.circular(16);

    if (loading) {
      return LuvNeuPress(
        onTap: enabled ? onTap : null,
        radius: radius,
        depth: 1.2,
        pressedDepth: -0.7,
        background: AppColorV2.lpBlueBrand,
        overlayOpacity: 0.02,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
        ),
      );
    }

    if (!enabled) {
      return Opacity(
        opacity: 0.55,
        child: LuvNeuPillButton(
          label: text,
          icon: Iconsax.tick_circle,
          filled: false,
          onTap: () {},
          height: 56,
        ),
      );
    }

    return LuvNeuPillButton(
      label: text,
      icon: Iconsax.tick_circle,
      filled: true,
      onTap: onTap,
      height: 56,
    );
  }

  Future<void> _submitForm() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    final ctx = Get.overlayContext ?? context;
    CustomDialogStack.showLoading(ctx);

    try {
      final walletName = _nameController.text.trim();

      final double walletAmount =
          widget.mode == WalletModalMode.edit
              ? (widget.wallet?.balance ?? 0.0)
              : (_balanceController.text.trim().isEmpty
                  ? 0.0
                  : double.parse(_balanceController.text.trim()));

      if (widget.mode == WalletModalMode.create &&
          _selectedCategoryId == null) {
        if (Get.isDialogOpen == true) Get.back();
        CustomDialogStack.showError(
          ctx,
          "luvpay",
          "Please select a category",
          () => Get.back(),
        );
        return;
      }

      final Map<String, dynamic> result =
          widget.mode == WalletModalMode.create
              ? await controller.postSubWallet(
                categoryId: int.tryParse(_selectedCategoryId!),
                subWalletName: walletName,
                amount: walletAmount,
              )
              : await controller.editSubwallet(
                subwalletId: int.tryParse(widget.wallet!.id),
                subWalletName: walletName,
              );

      if (result["success"] == true) {
        await controller.getUserSubWallets();
        await controller.luvpayBalance();
        widget.onWalletCreated?.call();
      }

      if (Get.isDialogOpen == true) Get.back();

      final isOk = result["success"] == true;
      final msg =
          (isOk ? result["message"] : result["error"])?.toString() ??
          (isOk ? "Success" : "Failed");

      if (isOk) {
        CustomDialogStack.showSuccess(ctx, "Success", msg, () {
          Get.back();
          Get.back();
          Navigator.of(context).pop(true);
        });
      } else {
        CustomDialogStack.showError(ctx, "luvpay", msg, () {
          Get.back();
          Get.back();
        });
      }
    } catch (_) {
      if (Get.isDialogOpen == true) Get.back();
      CustomDialogStack.showError(
        ctx,
        "luvpay",
        "Something went wrong. Please try again.",
        () => Get.back(),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nameOk = _validateName(_nameController.text) == null;

    final canSubmit =
        !_isSubmitting &&
        nameOk &&
        (widget.mode == WalletModalMode.edit
            ? true
            : _validateBalance(_balanceController.text) == null &&
                _validateCategory(_selectedCategoryId) == null);

    return Container(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        reverse: true,
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
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
                      ? 'Create New SubWallet'
                      : 'Edit Wallet Name',
              style: AppTextStyle.popup,
            ),
            const SizedBox(height: 10),

            if (widget.mode == WalletModalMode.create) ...[
              Obx(
                () => _softCard(
                  radius: BorderRadius.circular(14),
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
              const SizedBox(height: 12),

              DefaultText(
                text: 'Select Category',
                style: AppTextStyle.h3.copyWith(
                  color: AppColorV2.primaryTextColor,
                ),
              ),
              const SizedBox(height: 10),

              if (_availableCategories.isNotEmpty)
                SizedBox(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _availableCategories.length,
                    itemBuilder: (context, index) {
                      final category = _availableCategories[index];
                      final categoryId =
                          category['category_id']?.toString() ?? '';
                      final categoryName =
                          category['category_title']?.toString() ?? 'Unknown';
                      final isSelected = _selectedCategoryId == categoryId;

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
                        final clean = imageBase64.replaceAll(RegExp(r'\s'), '');
                        Uint8List? bytes;
                        if (_iconCache.containsKey(categoryId)) {
                          bytes = _iconCache[categoryId];
                        } else {
                          try {
                            bytes = base64.decode(clean);
                            _iconCache[categoryId] = bytes;
                          } catch (_) {
                            bytes = null;
                          }
                        }

                        iconWidget =
                            bytes != null
                                ? Padding(
                                  padding: const EdgeInsets.all(5),
                                  child: Image.memory(
                                    bytes,
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.contain,
                                    gaplessPlayback: true,
                                  ),
                                )
                                : const Icon(Iconsax.wallet, size: 30);
                      } else {
                        iconWidget = const Icon(Iconsax.wallet, size: 30);
                      }

                      return Padding(
                        padding: const EdgeInsets.all(3),
                        child: _categoryChip(
                          isSelected: isSelected,
                          color: color,
                          iconWidget: iconWidget,
                          label: categoryName,
                          onTap: () {
                            setState(() {
                              _selectedCategoryId = categoryId;
                              _selectedCategoryName = categoryName;
                              _selectedColor = color;
                              _selectedIconBytes = _iconCache[categoryId];
                            });
                            _validateCategoryOnChange(categoryId);
                          },
                        ),
                      );
                    },
                  ),
                )
              else
                GestureDetector(
                  onTap: () {
                    controller.refreshAllData();
                  },
                  child: DefaultText(
                    text: 'No categories available',
                    style: AppTextStyle.paragraph2.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),

              if (_categoryError != null) ...[
                const SizedBox(height: 8),
                DefaultText(
                  text: _categoryError!,
                  style: AppTextStyle.paragraph2.copyWith(
                    color: AppColorV2.incorrectState,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],

              const SizedBox(height: 18),
            ],

            if (widget.mode == WalletModalMode.edit &&
                widget.wallet != null) ...[
              _softCard(
                radius: BorderRadius.circular(16),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    LuvNeuPress(
                      radius: BorderRadius.circular(16),
                      depth: 1.2,
                      pressedDepth: -0.6,
                      onTap: null,
                      background: widget.wallet!.color.withOpacity(0.10),
                      overlayOpacity: 0.02,
                      child: SizedBox(
                        width: 52,
                        height: 52,
                        child: Center(
                          child: ClipOval(
                            child: SizedBox(
                              width: 44,
                              height: 44,
                              child: buildWalletIcon(
                                widget.wallet!.imageBase64 != null &&
                                        widget.wallet!.imageBase64!.isNotEmpty
                                    ? decodeBase64Safe(
                                      widget.wallet!.imageBase64!,
                                    )
                                    : null,
                              ),
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
                          DefaultText(
                            text: 'Current Category',
                            style: AppTextStyle.paragraph2.copyWith(
                              color: AppColorV2.bodyTextColor.withOpacity(.65),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          DefaultText(
                            text: widget.wallet!.categoryTitle,
                            style: AppTextStyle.h3.copyWith(
                              color: AppColorV2.primaryTextColor,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],

            TextField(
              controller: _nameController,
              onChanged: _validateNameOnChange,
              style: AppTextStyle.h3.copyWith(
                color: AppColorV2.primaryTextColor,
              ),
              maxLength: 15,
              inputFormatters: [UpperCaseTextFormatter()],
              decoration: InputDecoration(
                labelText: 'SubWallet Name',
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
            const SizedBox(height: 16),

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
                    RegExp(r'^[1-9]\d{0,8}(\.\d{0,2})?$'),
                  ),
                ],
                decoration: InputDecoration(
                  prefixText: '₱ ',
                  prefixStyle: AppTextStyle.h3_semibold,
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
                  hintText: 'Optional (defaults to 0)',
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

              if (_balanceError != null &&
                  _balanceError!.contains('Insufficient main balance')) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Iconsax.info_circle,
                      color: AppColorV2.incorrectState,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
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
              ],

              const SizedBox(height: 18),
            ],

            SizedBox(
              width: double.infinity,
              height: 56,
              child: _primaryButton(
                enabled: canSubmit,
                loading: _isSubmitting,
                text:
                    widget.mode == WalletModalMode.create
                        ? 'Create SubWallet'
                        : 'Save Changes',
                onTap: _submitForm,
              ),
            ),

            if (widget.mode == WalletModalMode.create) ...[
              const SizedBox(height: 14),
              _softCard(
                radius: BorderRadius.circular(14),
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
          ],
        ),
      ),
    );
  }
}
