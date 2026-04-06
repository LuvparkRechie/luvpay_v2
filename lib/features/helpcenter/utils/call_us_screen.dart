// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:iconsax/iconsax.dart';
import 'package:luvpay/shared/widgets/custom_scaffold.dart';
import 'package:luvpay/shared/widgets/neumorphism.dart';
import 'package:luvpay/shared/widgets/luvpay_text.dart';

import '../../../shared/widgets/tap_guard.dart';

class CallUsScreen extends StatefulWidget {
  const CallUsScreen({super.key});

  @override
  State<CallUsScreen> createState() => _CallUsScreenState();
}

class _CallUsScreenState extends State<CallUsScreen>
    with WidgetsBindingObserver {
  static const String _callKey = "call_support";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      TapGuard.unlock(_callKey);
      setState(() {});
    }
  }

  Future<void> _callNumber(String number) async {
    final Uri uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _handleCall(String number) {
    TapGuard.run(
      key: _callKey,
      action: () async {
        setState(() {});
        await _callNumber(number);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isLocked = TapGuard.isLocked(_callKey);

    return CustomScaffoldV2(
      appBarTitle: "Call Us",
      scaffoldBody: Column(
        children: [
          const SizedBox(height: 10),
          LuvNeuPress.circle(
            onTap: isLocked ? null : () => _handleCall("09853919305"),
            child: SizedBox(
              width: 70,
              height: 70,
              child: Icon(
                Iconsax.call_calling,
                color: isLocked ? cs.onSurface.withOpacity(0.4) : cs.primary,
                size: 30,
              ),
            ),
          ),
          const SizedBox(height: 20),
          LuvpayText(
            text: "Talk to our Support",
            style: AppTextStyle.h3_semibold(context),
          ),
          const SizedBox(height: 8),
          LuvpayText(
            textAlign: TextAlign.center,
            text:
                "Our support team is ready to assist you. You may call any of the numbers below.",
          ),
          const SizedBox(height: 25),
          InfoRowTile(
            icon: Iconsax.call,
            title: "Globe",
            subtitle: "0917 123 4567",
            onTap: () => _handleCall("09853919305"),
          ),
          InfoRowTile(
            icon: Iconsax.call,
            title: "Smart",
            subtitle: "0908 123 4567",
            onTap: () => _handleCall("09853919305"),
          ),
          InfoRowTile(
            icon: Iconsax.call,
            title: "Landline",
            subtitle: "(032) 123 4567",
            onTap: () => _handleCall("09853919305"),
          ),
          const Spacer(),
          CustomButton(
            text: isLocked ? "Calling..." : "Call Now",
            leading: const Icon(Iconsax.call),
            isInactive: isLocked,
            onPressed: () => _handleCall("09853919305"),
          ),
          const SizedBox(height: 10),
          LuvpayText(
            text: "Available: Monday - Sunday, 8:00 AM - 5:00 PM",
            fontSize: 12,
            textAlign: TextAlign.center,
            color: cs.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
