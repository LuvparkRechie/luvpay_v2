import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:luvpay/shared/widgets/neumorphism.dart';

import 'luvpay_text.dart';

class ConnectionInterruption extends StatelessWidget {
  final VoidCallback? onPressed;
  final String? msg;
  const ConnectionInterruption({
    super.key,
    this.onPressed,
    this.msg,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(),
          child: Column(
            children: [
              LuvpayText(
                text: msg ?? "Connection lost",
                style: AppTextStyle.h4(context),
                color: Colors.red,
              ),
              LuvpayText(
                text:
                    "We're unable to connect to the server. Please check your internet connection",
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        SizedBox(
          width: MediaQuery.of(context).size.width / 3.5,
          child: LuvNeuPillButton(
              height: 30,
              label: "Retry",
              icon: LucideIcons.refreshCcw,
              filled: false,
              onTap: () {
                onPressed!();
              }),
        )
      ],
    );
  }
}
