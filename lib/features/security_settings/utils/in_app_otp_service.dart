import 'dart:convert';
import 'package:crypto/crypto.dart';

class InAppOtpService {
  static final InAppOtpService _instance = InAppOtpService._internal();
  factory InAppOtpService() => _instance;

  InAppOtpService._internal();

  final String _secret = "luvpay_secret_key_123";

  ///change s a datyabase value later on

  int _generateTOTP() {
    final time = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final timeStep = time ~/ 30;

    final key = utf8.encode(_secret);
    final message = utf8.encode(timeStep.toString());

    final hmac = Hmac(sha1, key);
    final digest = hmac.convert(message).bytes;

    final offset = digest.last & 0x0f;
    final binary = ((digest[offset] & 0x7f) << 24) |
        ((digest[offset + 1] & 0xff) << 16) |
        ((digest[offset + 2] & 0xff) << 8) |
        (digest[offset + 3] & 0xff);

    final otp = binary % 1000000;

    return otp;
  }

  int getOtp() {
    return _generateTOTP();
  }

  Duration getRemainingTime() {
    final seconds = DateTime.now().second;
    final remaining = 30 - (seconds % 30);
    return Duration(seconds: remaining);
  }

  int generateOtp() {
    return _generateTOTP();
  }
}
