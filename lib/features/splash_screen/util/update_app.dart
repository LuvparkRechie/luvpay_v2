import 'package:flutter/material.dart';
import 'package:flutter_exit_app/flutter_exit_app.dart';
import 'package:get/get.dart';
import 'package:luvpay/shared/widgets/colors.dart';
import 'package:luvpay/shared/widgets/neumorphism.dart';

import 'package:luvpay/shared/widgets/custom_scaffold.dart';
import 'package:luvpay/shared/widgets/luvpay_text.dart';
import 'package:luvpay/shared/widgets/spacing.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateApp extends StatelessWidget {
  const UpdateApp({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;

    return CustomScaffoldV2(
      canPop: false,
      scaffoldBody: Column(
        children: [
          Image(image: AssetImage("assets/images/new_update.png")),
          LuvpayText(
            text: 'Update Available!',
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: AppColorV2.lpBlueBrand,
          ),
          spacing(height: 20),
          LuvpayText(
            text:
                "A new version (${args.storeVersion}) of this app is available and required. Please update now to continue using the app and enjoy the latest features and improvements.",
            fontWeight: FontWeight.w600,
            maxLines: 5,
            textAlign: TextAlign.center,
          ),
          spacing(height: 30),
          CustomButton(
            text: "Update now",
            onPressed: () async {
              final Uri url = Uri.parse(args.storeUrl!);
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
                await FlutterExitApp.exitApp(iosForceExit: true);
              } else {
                throw 'Could not launch ${args.storeUrl}';
              }
            },
          ),
        ],
      ),
      enableToolBar: false,
    );
  }
}
