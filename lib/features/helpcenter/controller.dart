import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'utils/email_support_screen.dart';

class HelpCenterController extends GetxController {
  static const String emailKey = "email_support";

  Future<void> sendEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@luvpay.ph',
      query: Uri.encodeFull(
        'subject=LuvPay Support'
        '&body='
        'Name:%0D%0A'
        'Mobile:%0D%0A'
        'User ID:%0D%0A'
        'Concern:%0D%0A',
      ),
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      Get.to(() => const EmailSupportScreen());
    }
  }
}
