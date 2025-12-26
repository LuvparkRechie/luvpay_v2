import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../../custom_widgets/alert_dialog.dart';
import '../../custom_widgets/app_color_v2.dart';
import '../../custom_widgets/custom_text_v2.dart';
import '../../custom_widgets/luvpay/custom_scaffold.dart';
import '../../custom_widgets/spacing.dart';

class InstapayPage extends StatelessWidget {
  final String qr;
  final double amount; // Add amount parameter

  const InstapayPage({
    super.key,
    required this.qr,
    this.amount = 0.0, // Default amount
  });

  @override
  Widget build(BuildContext context) {
    return CustomScaffoldV2(
      enableToolBar: true,
      canPop: true,
      appBar: null,
      scaffoldBody: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const DefaultText(text: "InstaPay"),
              spacing(height: 20),

              // QR Card Container
              qrBodyWidget(context, false),
              spacing(height: 30),

              // Additional Help Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  children: [
                    const DefaultText(
                      text: "How to pay with InstaPay QR:",
                      fontWeight: FontWeight.bold,
                    ),
                    spacing(height: 10),
                    _buildInstructionStep(1, "Open your bank or e-wallet app"),
                    _buildInstructionStep(2, "Select 'Scan QR' or 'InstaPay'"),
                    _buildInstructionStep(3, "Scan this QR code"),
                    _buildInstructionStep(4, "Confirm payment details"),
                    spacing(height: 20),
                  ],
                ),
              ),
              spacing(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget qrBodyWidget(context, isAction) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColorV2.lpBlueBrand,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                spacing(height: 20),

                // Payment Amount
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const DefaultText(text: "Amount:", color: Colors.white70),
                      DefaultText(
                        text: "₱${amount.toStringAsFixed(2)}",
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ],
                  ),
                ),
                spacing(height: 20),

                // QR Code Container
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: PrettyQrView(
                    decoration: const PrettyQrDecoration(
                      image: PrettyQrDecorationImage(
                        image: AssetImage("assets/images/qr_ph.png"),
                      ),
                      background: Colors.white,
                    ),
                    qrImage: QrImage(
                      QrCode.fromData(
                        data: qr,
                        errorCorrectLevel: QrErrorCorrectLevel.H,
                      ),
                    ),
                  ),
                ),
                spacing(height: 20),

                // Instructions
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30),
                  child: DefaultText(
                    text:
                        "Scan this QR code using your bank's mobile app to complete payment",
                    color: Colors.white70,
                    textAlign: TextAlign.center,
                  ),
                ),
                if (!isAction) spacing(height: 20),
                if (!isAction)
                  // Action Buttons Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(
                          icon: LucideIcons.download,
                          label: "Save QR",
                          onTap: () => _saveQr(context),
                        ),
                        Container(),
                        _buildActionButton(
                          icon: LucideIcons.share,
                          label: "Share",
                          onTap: () => _shareQr(context),
                        ),
                      ],
                    ),
                  ),
                spacing(height: 30),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        IconButton(icon: Icon(icon, color: Colors.white), onPressed: onTap),
        DefaultText(text: label, color: Colors.white70, fontSize: 12),
      ],
    );
  }

  Widget _buildInstructionStep(int number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: DefaultText(
                text: number.toString(),
                color: AppColorV2.lpBlueBrand,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(child: DefaultText(text: text)),
        ],
      ),
    );
  }

  void _saveQr(BuildContext context) async {
    // Implement QR saving functionality]\
    CustomDialogStack.showLoading(Get.context!);
    String randomNumber = Random().nextInt(100000).toString();
    String fname = "luvpark$randomNumber.png";
    ScreenshotController()
        .captureFromWidget(
          qrBodyWidget(context, true),
          delay: const Duration(seconds: 2),
        )
        .then((image) async {
          final dir = await getApplicationDocumentsDirectory();
          final imagePath = await File('${dir.path}/$fname').create();
          await imagePath.writeAsBytes(image);
          GallerySaver.saveImage(imagePath.path).then((result) {
            CustomDialogStack.showSuccess(
              Get.context!,
              "Success",
              "QR code has been saved. Please check your gallery.",
              leftText: "Okay",
              () {
                Get.back();
                Get.back();
              },
            );
          });
        });
  }

  void _copyQrData(BuildContext context) {
    Clipboard.setData(ClipboardData(text: qr));
    Get.snackbar(
      "Copied",
      "Payment link copied to clipboard",
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _shareQr(BuildContext context) async {
    // Implement share functionality
    String randomNumber = Random().nextInt(100000).toString();
    String fname = "shared_luvpark$randomNumber.png";

    CustomDialogStack.showLoading(Get.context!);
    final directory = (await getApplicationDocumentsDirectory()).path;
    Uint8List bytes = await ScreenshotController().captureFromWidget(
      qrBodyWidget(context, true),
    );
    Uint8List pngBytes = bytes.buffer.asUint8List();

    final imgFile = File('$directory/$fname');
    imgFile.writeAsBytes(pngBytes);
    Get.back();
    await Share.shareXFiles([XFile(imgFile.path)]);
  }
}
