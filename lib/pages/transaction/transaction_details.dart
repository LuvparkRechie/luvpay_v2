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
import '../../custom_widgets/spacing.dart';
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
    return Material(
      color: Colors.transparent,
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            Stack(
              fit: StackFit.loose,
              clipBehavior: Clip.none,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white,
                  ),
                  width: MediaQuery.of(context).size.width,
                  padding: EdgeInsets.symmetric(horizontal: 15, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      spacing(height: 30),
                      DefaultText(
                        textAlign: TextAlign.center,
                        text: data[index]["category"],
                        style: AppTextStyle.h3_semibold,
                        maxLines: 1,
                        color: AppColorV2.primaryTextColor,
                      ),
                      spacing(height: 3),
                      DefaultText(
                        textAlign: TextAlign.center,
                        fontSize: 18,
                        text: "${data[index]["tran_desc"]}",
                        style: AppTextStyle.body1,
                        maxFontSize: 14,
                        color: AppColorV2.primaryTextColor,
                      ),
                      spacing(height: 20),
                      const MySeparator(color: Color(0xFFD9D9D9)),
                      spacing(height: 20),
                      rowWidget(
                        "Transaction Date",
                        Variables.formatDateLocal(data[index]["tran_date"]),
                      ),
                      spacing(height: 5),

                      rowWidget(
                        "Amount",
                        toCurrencyString(
                          data[index]["amount"].replaceAll('-', '').toString(),
                        ),
                      ),
                      spacing(height: 5),
                      rowWidget(
                        isHistory ? "Balance Before" : "Previous Balance",
                        toCurrencyString(data[index]["bal_before"].toString()),
                      ),
                      spacing(height: 5),
                      rowWidget(
                        isHistory ? "Balance After" : "Current Balance",
                        toCurrencyString(data[index]["bal_after"].toString()),
                      ),
                      spacing(height: 20),
                      const MySeparator(color: Color(0xFFD9D9D9)),
                      spacing(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Center(
                            child: DefaultText(
                              maxLines: 1,
                              style: GoogleFonts.manrope(
                                color: AppColorV2.primaryTextColor,
                                fontWeight: FontWeight.w400,
                              ),
                              text: "Reference Number: ",
                            ),
                          ),
                          InkWell(
                            onTapDown: (details) async {
                              await Clipboard.setData(
                                ClipboardData(
                                  text: data[index]["ref_no"].toString(),
                                ),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Text copied to clipboard'),
                                ),
                              );
                            },
                            child: SelectableText(
                              toolbarOptions: ToolbarOptions(copy: true),
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w500,
                              ),
                              data[index]["ref_no"].toString(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: -30,
                  left: 0,
                  right: 0,
                  child: Align(
                    alignment: Alignment.center,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(width: 10, color: Colors.white),
                      ),
                      child: SvgPicture.asset(
                        fit: BoxFit.cover,
                        height: 50,
                        "assets/images/$img.svg",
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
  }

  Row rowWidget(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        DefaultText(
          style: AppTextStyle.body1,
          maxFontSize: 16,
          maxLines: 1,
          color: AppColorV2.primaryTextColor,
          text: label,
        ),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: DefaultText(
              text: value,
              style: AppTextStyle.body1,
              maxFontSize: 16,
              maxLines: 1,
              color: AppColorV2.bodyTextColor,
            ),
          ),
        ),
      ],
    );
  }
}
