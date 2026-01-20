import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../custom_widgets/app_color_v2.dart';
import '../../custom_widgets/custom_text_v2.dart';
import '../../custom_widgets/custom_textfield.dart';
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

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
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
            padding: const EdgeInsets.fromLTRB(19, 19, 19, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (context, value, child) {
                    return CustomTextField(
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(30),
                        UpperCaseTextFormatter(),
                      ],
                      key: _textFieldKey,
                      isFilled: true,
                      hintText: "Enter Voucher Code",
                      controller: controller,
                      filledColor: AppColorV2.background,
                      suffixBgC:
                          controller.text.isEmpty
                              ? AppColorV2.inactiveButton
                              : AppColorV2.lpBlueBrand,
                      suffixWidget: GestureDetector(
                        onTap:
                            controller.text.isNotEmpty ? _claimVoucher : null,
                        child: Center(
                          child: DefaultText(
                            text: "CLAIM",
                            style: AppTextStyle.h4,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
              ],
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
}
