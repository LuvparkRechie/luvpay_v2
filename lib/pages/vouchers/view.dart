import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../custom_widgets/app_color_v2.dart';
import '../../custom_widgets/custom_text_v2.dart';
import '../../custom_widgets/luvpay/custom_scaffold.dart';
import '../../custom_widgets/upper_case_formatter.dart';
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

  Color get _base => AppColorV2.background;

  List<BoxShadow> _softShadow() {
    return [
      BoxShadow(
        color: Colors.black.withOpacity(.06),
        blurRadius: 10,
        offset: const Offset(3, 4),
      ),
    ];
  }

  BoxDecoration _neo({
    double radius = 22,
    Border? border,
    Color? color,
    List<BoxShadow>? shadows,
  }) {
    return BoxDecoration(
      color: color ?? _base,
      borderRadius: BorderRadius.circular(radius),
      border: border,
      boxShadow: shadows ?? _softShadow(),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _claimVoucher() async {
    String code = controller.text.trim();
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
      print("Error claiming voucher: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffoldV2(
      backgroundColor: AppColorV2.lpBlueBrand,
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
                return searchBar(enabled);
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

  Container searchBar(bool enabled) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: _neo(
        radius: 24,
        border: Border.all(
          color: const Color(0xFF0F172A).withOpacity(.06),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              key: _textFieldKey,
              height: 50,
              decoration: _neo(
                radius: 18,
                border: Border.all(
                  color: const Color(0xFF0F172A).withOpacity(.06),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: AppColorV2.inactiveState.withOpacity(.85),
                  ),
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
                        color: AppColorV2.primaryTextColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .25,
                      ),
                      cursorColor: AppColorV2.lpBlueBrand,
                      decoration: InputDecoration(
                        hintText: "Enter voucher code",
                        hintStyle: TextStyle(
                          color: AppColorV2.inactiveState.withOpacity(.85),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        filled: true,
                        fillColor: _base,
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
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
                                color: AppColorV2.inactiveState.withOpacity(.9),
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
              return AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeOut,
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: _neo(
                  radius: 18,
                  border: Border.all(
                    color:
                        enabled
                            ? AppColorV2.lpBlueBrand.withOpacity(.16)
                            : const Color(0xFF0F172A).withOpacity(.06),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: DefaultText(
                    text: "CLAIM",
                    style: AppTextStyle.h3_semibold(context),
                    color:
                        enabled
                            ? AppColorV2.lpBlueBrand
                            : AppColorV2.inactiveState,
                  ),
                ),
              );
            },
          ),
        ],
      ),
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
