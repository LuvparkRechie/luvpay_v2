import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../custom_widgets/app_color_v2.dart';
import '../../custom_widgets/custom_button.dart';
import '../../custom_widgets/luvpay/custom_scaffold.dart';
import '../../custom_widgets/custom_text_v2.dart';
import '../../custom_widgets/spacing.dart';

import '../../web_view/webview.dart';
import '../routes/routes.dart';
import 'index.dart';

class LandingScreen extends GetView<LandingController> {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(LandingController());
    return CustomScaffoldV2(
      backgroundColor: AppColorV2.background,
      useNormalBody: true,
      enableToolBar: false,
      scaffoldBody: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 0),
              child: Column(
                children: [
                  SizedBox(height: 50),
                  Image(
                    image: AssetImage("assets/images/luvpay_logo.png"),
                    width: 175,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: 35),

                  Center(
                    child: DefaultText(
                      textAlign: TextAlign.center,
                      text: "Get started with LuvPay Wallet",
                      style: AppTextStyle.h1,
                      height: 32 / 28,
                    ),
                  ),
                  Container(height: 12),
                  DefaultText(
                    text:
                        "Experience a smarter way to pay. Fast, secure, and convenient wallet transactions—all in one app.",
                    textAlign: TextAlign.center,
                    style: AppTextStyle.paragraph1,
                    maxFontSize: 16,
                    maxLines: 3,
                  ),
                  DefaultText(text: "asdadasd"),
                  Container(height: 24),
                ],
              ),
            ),
          ),

          Obx(
            () => Column(
              children: [
                SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: () {
                        controller.onPageChanged(!controller.isAgree.value);
                      },
                      child: Obx(
                        () => Icon(
                          size: 19,
                          controller.isAgree.value
                              ? Icons.check_box_outlined
                              : Icons.check_box_outline_blank,
                          color: AppColorV2.lpBlueBrand,
                        ),
                      ),
                    ),
                    Container(width: 10),
                    Expanded(
                      child: Center(
                        child: RichText(
                          text: TextSpan(
                            children: [
                              WidgetSpan(
                                child: Row(
                                  children: [
                                    DefaultText(
                                      style: AppTextStyle.paragraph2,
                                      text: "Agree to the",
                                      letterSpacing: 0,
                                      height: 18 / 14,
                                    ),
                                    Container(width: 5),
                                    Expanded(
                                      child: InkWell(
                                        onTap: () {
                                          controller.onPageChanged(true);
                                          Get.to(
                                            const WebviewPage(
                                              urlDirect:
                                                  "https://luvpark.ph/terms-of-use/",
                                              label: "Terms of Use",
                                              isBuyToken: false,
                                            ),
                                          );
                                        },
                                        child: DefaultText(
                                          style: AppTextStyle.paragraph2,
                                          color: AppColorV2.lpBlueBrand,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0,
                                          text: "LuvPay Wallet Terms of Use",
                                        ),
                                      ),
                                    ),
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

                spacing(height: 24),

                CustomButton(
                  isInactive: !controller.isAgree.value,
                  text: "Create Account",
                  onPressed:
                      !controller.isAgree.value
                          ? () {}
                          : () {
                            Get.toNamed(
                              Routes.registration,
                              arguments: controller.isAgree.value,
                            );
                          },
                ),
              ],
            ),
          ),

          spacing(height: 50),
        ],
      ),
    );
  }
}
