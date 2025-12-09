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
                    image: AssetImage("assets/images/onboardluvpay.png"),
                    width: 175,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: 35),
                  Center(
                    child: DefaultText(
                      textAlign: TextAlign.center,
                      text: "Get started with luvpay Parking",
                      style: AppTextStyle.h1,
                      height: 32 / 28,
                    ),
                  ),
                  Container(height: 12),
                  DefaultText(
                    text:
                        "Start your journey to hassle-free parking in just a few taps.",
                    textAlign: TextAlign.center,
                    style: AppTextStyle.paragraph1,
                    height: 20 / 16,
                  ),
                  Container(height: 24),
                  const Image(
                    image: AssetImage("assets/images/create_account.png"),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 34),
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
                                      text: "Agree with",
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
                                                  "https://luvpay.ph/terms-of-use/",
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
                                          text: "luvpay's Terms of use",
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
                  text: "Proceed",

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
