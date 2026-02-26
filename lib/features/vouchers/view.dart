// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../shared/widgets/luvpay_text.dart';
import '../../shared/widgets/custom_scaffold.dart';
import '../../shared/widgets/upper_case_formatter.dart';
import 'controller.dart';
import 'voucher_body/voucher_body.dart';

class Vouchers extends StatefulWidget {
  const Vouchers({super.key});

  @override
  State<Vouchers> createState() => _VouchersState();
}

class _VouchersState extends State<Vouchers> {
  final TextEditingController controller = TextEditingController();
  String title = "Vouchers";
  final VouchersController voucherController = Get.put(VouchersController());
  final GlobalKey<VouchersBodyState> vouchersBodyKey =
      GlobalKey<VouchersBodyState>();

  final GlobalKey _textFieldKey = GlobalKey();

  Color _border(ColorScheme cs, bool isDark, [double? o]) =>
      cs.outlineVariant.withOpacity(o ?? (isDark ? 0.05 : 0.01));

  List<BoxShadow> _softShadow(ColorScheme cs, bool isDark) {
    return [
      BoxShadow(
        color: (isDark ? Colors.black : cs.shadow).withOpacity(
          isDark ? 0.35 : .10,
        ),
        blurRadius: isDark ? 18 : 14,
        offset: const Offset(0, 10),
      ),
    ];
  }

  BoxDecoration _neo(
    BuildContext context, {
    double radius = 22,
    Border? border,
    Color? color,
    List<BoxShadow>? shadows,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final base = color ?? cs.surface;
    return BoxDecoration(
      color: base,
      borderRadius: BorderRadius.circular(radius),
      border: border,
      boxShadow: shadows ?? _softShadow(cs, isDark),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _claimVoucher() async {
    final code = controller.text.trim();
    if (code.isEmpty) return;

    try {
      await voucherController.putVoucher(
        code,
        context,
        _textFieldKey,
        fromBooking: false,
      );
      controller.clear();
      vouchersBodyKey.currentState?.refresh();
      setState(() {});
    } catch (error) {
      // ignore: avoid_print
      print("Error claiming voucher: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return CustomScaffoldV2(
      backgroundColor: cs.primary,
      appBarTitle: title,
      padding: EdgeInsets.zero,
      canPop: true,
      enableToolBar: true,
      extendBodyBehindAppbar: true,
      scaffoldBody: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(19, 16, 19, 10),
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, child) {
                final enabled = controller.text.trim().isNotEmpty;
                return _searchBar(context, enabled, cs, isDark);
              },
            ),
          ),
          Expanded(
            child: VouchersBody(
              key: vouchersBodyKey,
              queryParam: {
                "isFromBooking": (Get.arguments == true).toString(),
                "search": "",
              },
              callBack: (data) {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBar(
    BuildContext context,
    bool enabled,
    ColorScheme cs,
    bool isDark,
  ) {
    final stroke = _border(cs, isDark);
    final hint = cs.onSurface.withOpacity(isDark ? 0.55 : 0.45);
    final textColor = cs.onSurface.withOpacity(0.90);

    return Row(
      children: [
        Expanded(
          child: Container(
            key: _textFieldKey,
            height: 50,
            decoration: _neo(
              context,
              radius: 18,
              color: cs.surface,
              border: Border.all(color: stroke, width: 1),
              shadows: [
                BoxShadow(
                  color: (isDark ? Colors.black : cs.shadow).withOpacity(
                    isDark ? 0.12 : 0.04,
                  ),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                Icon(Icons.search_rounded, size: 20, color: hint),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: controller,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(30),
                      UpperCaseTextFormatter(),
                    ],
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .25,
                    ),
                    cursorColor: cs.primary,
                    decoration: InputDecoration(
                      hintText: "Enter voucher code",
                      hintStyle: TextStyle(
                        color: hint,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      filled: true,
                      fillColor: cs.surface,
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onFieldSubmitted: (_) {
                      if (enabled) _claimVoucher();
                    },
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
                  child:
                      controller.text.isEmpty
                          ? const SizedBox(width: 10)
                          : IconButton(
                            key: const ValueKey("clear"),
                            onPressed: () {
                              controller.clear();
                              setState(() {});
                            },
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            icon: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: cs.onSurface.withOpacity(0.55),
                            ),
                          ),
                ),
                const SizedBox(width: 6),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        _NeoPressable(
          enabled: enabled,
          onTap: enabled ? _claimVoucher : null,
          builder: (pressed) {
            final btnStroke =
                enabled ? cs.primary.withOpacity(isDark ? 0.22 : 0.18) : stroke;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOut,
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: _neo(
                context,
                radius: 18,
                border: Border.all(color: btnStroke, width: 1),
                shadows:
                    pressed
                        ? [
                          BoxShadow(
                            color: (isDark ? Colors.black : cs.shadow)
                                .withOpacity(isDark ? 0.10 : 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                        : [
                          BoxShadow(
                            color: (isDark ? Colors.black : cs.shadow)
                                .withOpacity(isDark ? 0.18 : 0.08),
                            blurRadius: 14,
                            offset: const Offset(0, 8),
                          ),
                        ],
              ),
              child: Center(
                child: LuvpayText(
                  text: "CLAIM",
                  style: AppTextStyle.h3_semibold(context),
                  maxFontSize: 12,
                  color: enabled ? cs.primary : cs.onSurface.withOpacity(0.45),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _NeoPressable extends StatefulWidget {
  final bool enabled;
  final VoidCallback? onTap;
  final Widget Function(bool pressed) builder;

  const _NeoPressable({
    required this.enabled,
    required this.onTap,
    required this.builder,
  });

  @override
  State<_NeoPressable> createState() => _NeoPressableState();
}

class _NeoPressableState extends State<_NeoPressable> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (!widget.enabled) return;
    if (_pressed == v) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.builder(_pressed);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.enabled ? widget.onTap : null,
      onTapDown: widget.enabled ? (_) => _setPressed(true) : null,
      onTapCancel: widget.enabled ? () => _setPressed(false) : null,
      onTapUp: widget.enabled ? (_) => _setPressed(false) : null,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        scale: _pressed ? .96 : 1,
        child: Opacity(opacity: widget.enabled ? 1 : .75, child: child),
      ),
    );
  }
}
