// ignore_for_file: deprecated_member_use

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import '../../custom_widgets/alert_dialog.dart';
import '../../custom_widgets/app_color_v2.dart';
import '../../custom_widgets/brightness_setter.dart';
import '../../custom_widgets/custom_button.dart';
import '../../custom_widgets/custom_scaffold.dart';
import '../../custom_widgets/custom_text_v2.dart';
import '../../custom_widgets/loading.dart';
import 'controller.dart';

class QR extends StatefulWidget {
  const QR({super.key});

  @override
  State<QR> createState() => _QRState();
}

class _QRState extends State<QR> {
  final controller = Get.put(QRController());

  @override
  void initState() {
    super.initState();
    BrightnessSetter.setFullBrightness();
  }

  @override
  void dispose() {
    BrightnessSetter.restoreBrightness();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PayWithQRBody(controller: controller);
  }
}

class PayWithQRBody extends GetView<QRController> {
  const PayWithQRBody({super.key, required this.controller});
  final QRController controller;

  @override
  Widget build(BuildContext context) {
    return CustomScaffoldV2(
      bodyColor: AppColorV2.background,
      enableToolBar: false,
      padding: EdgeInsets.zero,
      appBar: AppBar(toolbarHeight: 0, elevation: 0),
      extendBodyBehindAppbar: true,
      scaffoldBody: Obx(
        () => Stack(
          children: [
            Image.asset("assets/images/receipt_background.png"),
            Align(
              alignment: Alignment.topLeft,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () {
                      Get.back();
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(top: 60.0, left: 19),
                      child: Row(
                        children: [
                          Icon(
                            CupertinoIcons.back,
                            color: AppColorV2.background,
                          ),
                          DefaultText(
                            color: AppColorV2.background,
                            text: "Back",
                            style: AppTextStyle.h3_semibold,
                            height: 20 / 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 60.0),
                    child: DefaultText(
                      text: "Scan to Pay",
                      style: AppTextStyle.h3,
                      color: AppColorV2.background,
                      maxLines: 1,
                    ),
                  ),
                  SizedBox(width: 80),
                ],
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),

                child: FittedBox(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 20,
                        ),
                        width: MediaQuery.of(context).size.width,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            fit: BoxFit.fill,
                            image: AssetImage(
                              "assets/images/receipt_ticket_no_lines.png",
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            controller.isLoading.value
                                ? Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 100,
                                  ),
                                  child: LoadingCard(),
                                )
                                : Container(
                                  margin: const EdgeInsets.fromLTRB(
                                    40,
                                    10,
                                    40,
                                    0,
                                  ),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: PrettyQrView(
                                    decoration: const PrettyQrDecoration(
                                      background: Colors.white,
                                      image: PrettyQrDecorationImage(
                                        image: AssetImage(
                                          "assets/images/logo.png",
                                        ),
                                      ),
                                    ),
                                    qrImage: QrImage(
                                      QrCode.fromData(
                                        data: controller.payKey.value,
                                        errorCorrectLevel:
                                            QrErrorCorrectLevel.H,
                                      ),
                                    ),
                                  ),
                                ),
                            SizedBox(height: 20),
                            DefaultText(
                              text:
                                  "Align the QR code within the frame to proceed with payment.",
                              textAlign: TextAlign.center,
                              style: AppTextStyle.paragraph1,
                            ),
                            SizedBox(height: 40),
                            Obx(() {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 19,
                                ),
                                child: Column(
                                  children: [
                                    CustomButton(
                                      isInactive:
                                          controller.isButtonDisabled.value ||
                                          !controller.isInternetConn.value,

                                      leading: Icon(
                                        color: AppColorV2.lpBlueBrand,
                                        LucideIcons.refreshCw,
                                      ),
                                      bordercolor:
                                          controller.isButtonDisabled.value
                                              ? AppColorV2.inactiveButton
                                              : AppColorV2.lpBlueBrand,
                                      btnColor: AppColorV2.background,
                                      textColor: AppColorV2.lpBlueBrand,
                                      text:
                                          controller.isButtonDisabled.value ||
                                                  ((controller.remainingTime.value %
                                                                  60000) /
                                                              1000)
                                                          .floor() !=
                                                      0
                                              ? "New QR in (${((controller.remainingTime.value % 60000) / 1000).floor()} seconds)"
                                              : "Generate QR",
                                      onPressed:
                                          controller.isButtonDisabled.value ||
                                                  !controller
                                                      .isInternetConn
                                                      .value
                                              ? () {
                                                CustomDialogStack.showConnectionLost(
                                                  context,
                                                  () {
                                                    Get.back();
                                                  },
                                                );
                                              }
                                              : () {
                                                controller.generateQr();
                                              },
                                    ),
                                  ],
                                ),
                              );
                            }),
                            SizedBox(height: 10),

                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 19.0,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: CustomButton(
                                      leading: Icon(
                                        LucideIcons.download,
                                        color: AppColorV2.lpBlueBrand,
                                      ),
                                      bordercolor: AppColorV2.lpBlueBrand,
                                      btnColor: AppColorV2.background,
                                      textColor: AppColorV2.lpBlueBrand,
                                      text: "Download",
                                      onPressed: controller.saveQr,
                                    ),
                                  ),
                                  Container(width: 10),
                                  Expanded(
                                    child: CustomButton(
                                      leading: Icon(
                                        LucideIcons.share,
                                        color: AppColorV2.lpBlueBrand,
                                      ),
                                      bordercolor: AppColorV2.lpBlueBrand,
                                      btnColor: AppColorV2.background,
                                      textColor: AppColorV2.lpBlueBrand,
                                      text: "Share",
                                      onPressed: controller.shareQr,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
