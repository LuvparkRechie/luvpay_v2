// ignore_for_file: prefer_const_constructors, deprecated_member_use, use_build_context_synchronously

import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:luvpay/custom_widgets/luvpay/custom_scaffold.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../../custom_widgets/alert_dialog.dart';
import '../../custom_widgets/app_color_v2.dart';
import '../../custom_widgets/custom_button.dart';
import '../../custom_widgets/custom_separator.dart';
import '../../custom_widgets/custom_text_v2.dart';
import 'package:path_provider/path_provider.dart';
import '../../custom_widgets/variables.dart';

class TransactionDetails extends StatelessWidget {
  final List data;
  final int index;
  final bool isHistory;
  const TransactionDetails({
    super.key,
    required this.data,
    required this.index,
    required this.isHistory,
  });
  Future<void> shareQR(String img) async {
    try {
      String randomNumber = Random().nextInt(10000).toString();
      String fname = "shared_luvpay$randomNumber";
      CustomDialogStack.showLoading(Get.context!);
      final dir = (await getApplicationDocumentsDirectory()).path;
      final path = '$dir/$fname';
      Uint8List bytes = await ScreenshotController().captureFromWidget(
        ticket(Get.context!, img),
      );
      final imgFile = File(path);
      await imgFile.writeAsBytes(bytes.buffer.asUint8List());

      Get.back();

      if (Platform.isAndroid || Platform.isIOS) {
        await Share.shareXFiles([
          XFile(imgFile.path, mimeType: 'image/png'),
        ], text: "luvpay share");
      } else {
        CustomDialogStack.showError(
          Get.context!,
          "Unsupported",
          "Sharing is not supported on this platform.",
          () => Get.back(),
        );
      }
    } catch (e) {
      Get.back();
      CustomDialogStack.showError(
        Get.context!,
        "Error",
        "Something went wrong while sharing the QR code.",
        () => Get.back(),
      );
      debugPrint("Error while sharing QR: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    String trans = data[index]["tran_desc"].toString().toLowerCase();
    String img = "";
    if (trans.contains("share")) {
      img = "wallet_sharetoken";
    } else if (trans.contains("received") || trans.contains("top-up")) {
      img = "wallet_receivetoken";
    } else {
      img = "wallet_payparking";
    }

    return CustomScaffoldV2(
      bodyColor: Color.fromARGB(255, 245, 252, 252),
      enableToolBar: true,
      appBarTitle: "Transaction Details",
      scaffoldBody: Column(
        children: [
          SizedBox(height: 20),
          ticket(context, img),
          SizedBox(height: 10),
          CustomButton(
            text: "Share",
            onPressed: () {
              shareQR(img);
            },
            leading: Icon(LucideIcons.share2, color: AppColorV2.background),
          ),
        ],
      ),
    );
  }

  Widget ticket(BuildContext context, String img) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 20),

              DefaultText(
                textAlign: TextAlign.center,
                text: data[index]["category"],
                style: AppTextStyle.h3_semibold.copyWith(fontSize: 20),
                color: AppColorV2.primaryTextColor,
                maxLines: 1,
              ),

              const SizedBox(height: 6),

              DefaultText(
                textAlign: TextAlign.center,
                text: data[index]["tran_desc"].toString(),
                style: AppTextStyle.body1.copyWith(
                  color: AppColorV2.primaryTextColor.withOpacity(0.75),
                ),
                maxFontSize: 14,
              ),

              const SizedBox(height: 22),
              const MySeparator(color: Color(0xFFE6E6E6)),
              const SizedBox(height: 22),

              rowWidget(
                "Transaction Date",
                Variables.formatDateLocal(data[index]["tran_date"]),
              ),
              const SizedBox(height: 12),
              rowWidget(
                "Amount",
                toCurrencyString(
                  data[index]["amount"].replaceAll('-', '').toString(),
                ),
                isEmphasized: true,
              ),
              const SizedBox(height: 12),
              rowWidget(
                isHistory ? "Balance Before" : "Previous Balance",
                toCurrencyString(data[index]["bal_before"].toString()),
              ),
              const SizedBox(height: 12),
              rowWidget(
                isHistory ? "Balance After" : "Current Balance",
                toCurrencyString(data[index]["bal_after"].toString()),
              ),

              const SizedBox(height: 22),
              const MySeparator(color: Color(0xFFE6E6E6)),
              const SizedBox(height: 18),

              Column(
                children: [
                  DefaultText(
                    text: "Reference Number",
                    style: AppTextStyle.body1.copyWith(
                      color: AppColorV2.primaryTextColor.withOpacity(0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SelectableText(
                    data[index]["ref_no"].toString(),
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                      color: AppColorV2.lpBlueBrand,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        Positioned(
          top: -28,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SvgPicture.asset("assets/images/$img.svg", height: 48),
            ),
          ),
        ),
      ],
    );
  }

  Row rowWidget(String label, String value, {bool isEmphasized = false}) {
    return Row(
      children: [
        Expanded(
          child: DefaultText(
            text: label,
            style: AppTextStyle.body1.copyWith(
              color: AppColorV2.primaryTextColor.withOpacity(0.65),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
          ),
        ),
        DefaultText(
          text: value,
          style: AppTextStyle.body1.copyWith(
            fontWeight: isEmphasized ? FontWeight.w700 : FontWeight.w600,
            color:
                isEmphasized
                    ? AppColorV2.lpBlueBrand
                    : AppColorV2.bodyTextColor,
          ),
          maxLines: 1,
        ),
      ],
    );
  }
}
