// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:iconsax/iconsax.dart';
import 'package:luvpay/shared/dialogs/dialogs.dart';
import 'package:luvpay/shared/widgets/custom_scaffold.dart';
import 'package:luvpay/shared/widgets/neumorphism.dart';
import 'package:luvpay/shared/widgets/luvpay_text.dart';

import '../../../shared/widgets/tap_guard.dart';
import '../../../shared/widgets/tap_guard_keys.dart';
import '../controller.dart';

class CallUsScreen extends StatefulWidget {
  const CallUsScreen({super.key});

  @override
  State<CallUsScreen> createState() => _CallUsScreenState();
}

class _CallUsScreenState extends State<CallUsScreen>
    with WidgetsBindingObserver {
  static const String _callKey = TapGuardKeys.callSupport;
  late final HelpCenterController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<HelpCenterController>()
        ? Get.find<HelpCenterController>()
        : Get.put(HelpCenterController());
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

  Future<bool> _callNumber(String number) async {
    final Uri uri = Uri(scheme: 'tel', path: number);

    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("Unable to launch support call for $number: $e");
      return false;
    }
  }

  Future<void> _handleCall(String number) async {
    await TapGuard.run(
        key: _callKey,
        action: () async {
          setState(() {});
          final launched = await _callNumber(number);

          if (!launched && mounted) {
            CustomDialogStack.showSnackBar(context,
                "No phone app available to make this call.", Colors.red, null);
          }
        });

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isLocked = TapGuard.isLocked(_callKey);
    final primaryContact = controller.primarySupportContact;

    return CustomScaffoldV2(
        appBarTitle: "Call Us",
        scaffoldBody: Column(children: [
          const SizedBox(height: 10),
          LuvNeuPress.circle(
              onTap: isLocked
                  ? null
                  : () => _handleCall(primaryContact.phoneNumber),
              child: SizedBox(
                  width: 70,
                  height: 70,
                  child: Icon(Iconsax.call_calling,
                      color:
                          isLocked ? cs.onSurface.withOpacity(0.4) : cs.primary,
                      size: 30))),
          const SizedBox(height: 20),
          LuvpayText(
              text: "Talk to our Support",
              style: AppTextStyle.h3_semibold(context)),
          const SizedBox(height: 8),
          LuvpayText(
              textAlign: TextAlign.center,
              text:
                  "Our support team is ready to assist you. You may call any of the numbers below."),
          const SizedBox(height: 25),
          ...HelpCenterController.supportContacts.map((contact) {
            return InfoRowTile(
                icon: contact.icon,
                title: contact.label,
                subtitle: _formatPhoneNumber(contact.phoneNumber),
                onTap: () => _handleCall(contact.phoneNumber));
          }),
          const Spacer(),
          CustomButton(
              text: isLocked ? "Calling..." : "Call Now",
              leading: const Icon(Iconsax.call),
              isInactive: isLocked,
              onPressed: () => _handleCall(primaryContact.phoneNumber)),
          const SizedBox(height: 10),
          LuvpayText(
              text: HelpCenterController.supportAvailability,
              fontSize: 12,
              textAlign: TextAlign.center,
              color: cs.onSurfaceVariant),
        ]));
  }

  String _formatPhoneNumber(String number) {
    if (number.length == 11 && number.startsWith("09")) {
      return "${number.substring(0, 4)} ${number.substring(4, 7)} ${number.substring(7)}";
    }

    if (number.length == 10 && number.startsWith("032")) {
      return "(${number.substring(0, 3)}) ${number.substring(3, 6)} ${number.substring(6)}";
    }

    return number;
  }
}
