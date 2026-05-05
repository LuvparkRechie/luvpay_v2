import 'package:otp/otp.dart';

import '../../../auth/authentication.dart';

class InAppOtpService {
  static final InAppOtpService _instance = InAppOtpService._internal();
  factory InAppOtpService() => _instance;

  InAppOtpService._internal();

  static const int _otpLength = 6;
  static const int _intervalSeconds = 30;

  Future<String> getOtp({String? secret}) async {
    final resolvedSecret =
        (secret ?? await Authentication().getInAppOtpSecret())?.trim();

    if (resolvedSecret == null || resolvedSecret.isEmpty) {
      throw StateError("In-app OTP secret is not available.");
    }

    return _generateTOTP(resolvedSecret);
  }

  String _generateTOTP(String secret) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    try {
      return OTP.generateTOTPCodeString(secret, timestamp,
          interval: _intervalSeconds,
          length: _otpLength,
          algorithm: Algorithm.SHA1,
          isGoogle: true);
    } on FormatException {
      return OTP.generateTOTPCodeString(secret, timestamp,
          interval: _intervalSeconds,
          length: _otpLength,
          algorithm: Algorithm.SHA1);
    }
  }

  Duration getRemainingTime() {
    final seconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final elapsed = seconds % _intervalSeconds;
    final remaining =
        elapsed == 0 ? _intervalSeconds : _intervalSeconds - elapsed;
    return Duration(seconds: remaining);
  }
}
