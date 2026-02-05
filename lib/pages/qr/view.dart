// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:luvpay/custom_widgets/app_color_v2.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

import '../../custom_widgets/alert_dialog.dart';
import '../../custom_widgets/brightness_setter.dart';
import '../../custom_widgets/luvpay/custom_button.dart';
import '../../custom_widgets/custom_text_v2.dart';
import '../../custom_widgets/luvpay/custom_scaffold.dart';
import '../../custom_widgets/luvpay/luvpay_loading.dart';
import 'controller.dart';

class QR extends StatefulWidget {
  final String? qrCode;
  const QR({super.key, this.qrCode});

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

  Color _stroke(ColorScheme cs, bool isDark) =>
      cs.onSurface.withOpacity(isDark ? 0.05 : 0.01);

  @override
  Widget build(BuildContext context) {
    final bool myQR = widget.qrCode != null;

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final stroke = _stroke(cs, isDark);

    return CustomScaffoldV2(
      centerTitle: true,
      appBarTitle: "My QR",
      padding: EdgeInsets.zero,
      scaffoldBody: Obx(
        () => CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 120,
              pinned: true,
              elevation: 0,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                background:
                    myQR
                        ? const SizedBox.shrink()
                        : const Padding(
                          padding: EdgeInsets.only(
                            top: 60.0,
                            left: 19,
                            right: 19,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [SizedBox(width: 40)],
                          ),
                        ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: FittedBox(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 20,
                        ),
                        width: MediaQuery.of(context).size.width,
                        decoration: const BoxDecoration(
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
                                ? const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 100),
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
                                    color: cs.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: stroke,
                                      width: 0.01,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(
                                          isDark ? 0.28 : 0.10,
                                        ),
                                        blurRadius: 18,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: PrettyQrView(
                                    decoration: const PrettyQrDecoration(
                                      background: AppColorV2.background,
                                      image: PrettyQrDecorationImage(
                                        image: AssetImage(
                                          "assets/images/logo.png",
                                        ),
                                      ),
                                    ),
                                    qrImage: QrImage(
                                      QrCode.fromData(
                                        data:
                                            myQR
                                                ? widget.qrCode!
                                                : controller.payKey.value,
                                        errorCorrectLevel:
                                            QrErrorCorrectLevel.H,
                                      ),
                                    ),
                                  ),
                                ),

                            const SizedBox(height: 20),
                            DefaultText(
                              text:
                                  "Align the QR code within the frame to proceed.",
                              textAlign: TextAlign.center,
                              style: AppTextStyle.paragraph1(context),
                            ),

                            const SizedBox(height: 40),

                            if (!myQR)
                              Obx(
                                () => Padding(
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
                                          LucideIcons.refreshCw,
                                          color: cs.primary,
                                        ),
                                        bordercolor:
                                            controller.isButtonDisabled.value
                                                ? cs.onSurface.withOpacity(0.20)
                                                : cs.primary.withOpacity(0.75),
                                        btnColor: cs.surface,
                                        textColor: cs.primary,
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
                                                    () => Get.back(),
                                                  );
                                                }
                                                : () => controller.generateQr(),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            const SizedBox(height: 10),

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
                                        color: cs.primary,
                                      ),
                                      bordercolor: cs.primary.withOpacity(0.75),
                                      btnColor: cs.surface,
                                      textColor: cs.primary,
                                      text: "Download",
                                      onPressed:
                                          () =>
                                              controller.saveQr(widget.qrCode),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: CustomButton(
                                      leading: Icon(
                                        LucideIcons.share,
                                        color: cs.primary,
                                      ),
                                      bordercolor: cs.primary.withOpacity(0.75),
                                      btnColor: cs.surface,
                                      textColor: cs.primary,
                                      text: "Share",
                                      onPressed:
                                          () =>
                                              controller.shareQr(widget.qrCode),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 30),
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
