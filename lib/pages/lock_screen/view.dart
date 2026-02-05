import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../custom_widgets/luvpay/custom_scaffold.dart';
import '../../custom_widgets/custom_text_v2.dart';
import '../../custom_widgets/no_internet.dart';
import '../../custom_widgets/spacing.dart';
import '../lock_screen/controller.dart';

import '../../custom_widgets/luvpay/custom_button.dart';

class LockScreen extends GetView<LockScreenController> {
  const LockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScaffoldV2(
      enableToolBar: false,
      canPop: false,
      scaffoldBody: Obx(
        () =>
            !controller.hasNet.value
                ? NoInternetConnected(onTap: controller.unlockAccount)
                : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      "assets/images/account_locked.svg",
                      width: MediaQuery.of(context).size.width / 2,
                      height: MediaQuery.of(context).size.width / 2,
                    ),
                    spacing(height: 30),
                    DefaultText(
                      text: "Account Locked",
                      color: Color(0xFF0078FF),
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                    spacing(height: 10),
                    DefaultText(
                      textAlign: TextAlign.center,
                      text: controller.formattedTime.value,
                    ),
                    spacing(height: MediaQuery.of(context).size.height * .15),
                    CustomButton(
                      text: "Switch Account",
                      onPressed: controller.switchAccount,
                    ),
                  ],
                ),
      ),
    );
  }
}
