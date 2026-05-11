import '../../../auth/authentication.dart';

enum OtpDeliveryMethod { sms, inApp }

class OtpDeliveryPolicy {
  static const String smsFlag = "Y";
  static const String inAppFlag = "N";
  static const String smsMethod = "SMS";
  static const String inAppMethod = "IN_APP";

  Future<OtpDeliveryMethod> resolve({bool allowInAppOtp = true}) async {
    if (!allowInAppOtp) {
      return OtpDeliveryMethod.sms;
    }

    final isInAppOtpEnabled = await Authentication().getInAppOtp() ?? false;
    return isInAppOtpEnabled ? OtpDeliveryMethod.inApp : OtpDeliveryMethod.sms;
  }

  Future<String> resolveUseSmsFlag({bool allowInAppOtp = true}) async {
    return flagForMethod(await resolve(allowInAppOtp: allowInAppOtp));
  }

  static String flagForMethod(OtpDeliveryMethod method) {
    return method == OtpDeliveryMethod.inApp ? inAppFlag : smsFlag;
  }

  static String verifyMethodForFlag(String? useSmsFlag) {
    return isInAppFlag(useSmsFlag) ? inAppMethod : smsMethod;
  }

  static bool isSmsFlag(String? value) {
    return value?.trim().toUpperCase() == smsFlag;
  }

  static bool isInAppFlag(String? value) {
    return value?.trim().toUpperCase() == inAppFlag;
  }
}
