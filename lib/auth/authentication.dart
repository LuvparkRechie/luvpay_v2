import 'dart:convert';

import 'package:encrypted_shared_preferences/encrypted_shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:luvpay/core/security/encryption.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:luvpay/core/security/decryptor/decryptor.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../shared/widgets/variables.dart';
import '../core/utils/functions/functions.dart';

class Authentication {
  static const String _kEncryptedDataPref = 'encrypt_data';
  static const String _kEncryptedDataSecretKey = 'encrypt_data_secret';
  static const String _kLegacyEncryptionSecret = 'luvpay';

  static EncryptedSharedPreferences encryptedSharedPreferences =
      EncryptedSharedPreferences();
  final LocalAuthentication auth = LocalAuthentication();
  final storage = FlutterSecureStorage();

  Future<void> clearStoredData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    encryptedSharedPreferences.clear();
    prefs.clear();
    await storage.deleteAll();
  }

  Future<bool> checkBiometrics() async {
    late bool checkBiometrics;
    try {
      checkBiometrics = await auth.canCheckBiometrics;

      return checkBiometrics;
    } on PlatformException {
      checkBiometrics = false;

      return checkBiometrics;
    }
  }

  Future<void> setUserData(data) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('userData', data);
  }

  Future<String?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userData');
  }

  Future<dynamic> getUserData2() async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('userData');

    if (data == null) {
      return null;
    }
    return jsonDecode(data);
  }

  //SET LOGIN
  Future<void> setLogin(loginData) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('auth_login', loginData);
  }

  //RETRIEVE LOGIN
  Future<dynamic> getUserLogin() async {
    final prefs = await SharedPreferences.getInstance();

    String? data = prefs.getString('auth_login');

    if (data == null) {
      return null;
    } else {
      return jsonDecode(data);
    }
  }

  //SET BRGY
  Future<void> setBrgy(loginData) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('brgy_data', loginData);
  }

  //SET CITY
  Future<void> setCity(loginData) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('city_data', loginData);
  }

  //SET PROVINCE
  Future<void> setProvince(loginData) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('province_data', loginData);
  }

  //SET LOGIN
  Future<void> setProfilePic(loginData) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('profile_pic', loginData);
  }

  Future<String> getUserProfilePic() async {
    final prefs = await SharedPreferences.getInstance();

    String? data = prefs.getString('profile_pic');

    if (data == null || data.isEmpty) {
      return "";
    }
    return jsonDecode(data);
  }

  //GET USER ID
  Future<int> getUserId() async {
    final item = await Authentication().getUserData2();
    if (item == null) {
      return 0;
    } else {
      int userId = item["user_id"];

      return userId;
    }
  }

  Future<void> setLastBooking(String dataParam) async {
    final prefs = await SharedPreferences.getInstance();

    List<dynamic> data = await getLastBooking();
    var dataString = jsonDecode(dataParam);
    if (dataString is! List) {
      dataString = [dataString];
    }

    if (data.length == 5) {
      data.removeAt(0);
    }
    bool isExist = data
        .where((e) =>
            (e["park_area_id"] == dataString[0]["park_area_id"]) &&
            (e["vehicle_plate_no"] == dataString[0]["vehicle_plate_no"]))
        .toList()
        .isNotEmpty;
    if (isExist) return;
    data.addAll(dataString);
    await prefs.setString("last_booking", json.encode(data));
  }

  Future<dynamic> getLastBooking() async {
    final prefs = await SharedPreferences.getInstance();

    String? data = prefs.getString('last_booking');

    if (data == null || data.isEmpty) {
      return [];
    }
    return jsonDecode(data);
  }

  //SEt logout status
  Future<void> setLogoutStatus(bool status) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('is_logout', status);
  }

  Future<bool?> getLogoutStatus() async {
    final prefs = await SharedPreferences.getInstance();
    bool? isLogout = prefs.getBool("is_logout");

    return isLogout;
  }

  //SEt biometric  status
  Future<void> setBiometricStatus(bool status) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('enable_biometric', status);
  }

  Future<bool?> getBiometricStatus() async {
    final prefs = await SharedPreferences.getInstance();
    bool? isLogout = prefs.getBool("enable_biometric");

    if (isLogout == null) {
      return false;
    } else {
      return isLogout;
    }
  }

  //SEt background process  status
  Future<void> enableTimer(bool status) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('enable_timer', status);
  }

  Future<bool?> getTimerStatus() async {
    final prefs = await SharedPreferences.getInstance();
    bool? isEnabled = prefs.getBool("enable_timer");

    if (isEnabled == null) {
      return false;
    } else {
      return isEnabled;
    }
  }

  Future<void> setAppVersion(int appVers) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('app_version', appVers);
  }

  Future<int> getAppVersion() async {
    final prefs = await SharedPreferences.getInstance();
    int? appVers = prefs.getInt("app_version");

    if (appVers == null) {
      return 0;
    } else {
      return appVers;
    }
  }

  Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove(key);
  }

  //encrypt data
  Future<void> encryptData(String plaintText, [String? secretKey]) async {
    final prefs = await SharedPreferences.getInstance();
    final skey = await _resolveEncryptionSecret(secretKey);

    String inatayaaa = jsonEncode(skey);
    Uint8List aesKey = Functions.generateKey(inatayaaa, 16);
    final nonce = Variables.generateRandomNonce();

    final encrypted =
        await Variables.encryptData(aesKey, nonce, json.encode(plaintText));

    final concatenatedArray = Variables.concatBuffers(nonce, encrypted);
    final output = Variables.arrayBufferToBase64(concatenatedArray);

    await storage.write(key: _kEncryptedDataPref, value: output);
    await prefs.remove(_kEncryptedDataPref);
  }

  Future<dynamic> getEncryptedKeys([String? secretKey]) async {
    final prefs = await SharedPreferences.getInstance();
    final existingSecret = await storage.read(key: _kEncryptedDataSecretKey);
    final secureOutput = await storage.read(key: _kEncryptedDataPref);
    final legacyOutput = prefs.getString(_kEncryptedDataPref);

    final decrypted = await _readEncryptedPayload(
      secureOutput: secureOutput,
      legacyOutput: legacyOutput,
      overrideSecret: secretKey,
      existingSecret: existingSecret,
    );

    if (decrypted == null) {
      return null;
    }

    final data = jsonDecode(decrypted.plainText);
    final decodedData =
        data is String ? jsonDecode(data) : Map<String, dynamic>.from(data);

    if (secretKey == null) {
      await _migrateEncryptedPayloadIfNeeded(
        existingSecret: existingSecret,
        secureOutput: secureOutput,
        legacyOutput: legacyOutput,
        decrypted: decrypted,
        decodedData: decodedData,
      );
    }

    return decodedData;
  }

  Future<String> _resolveEncryptionSecret(String? overrideSecret) async {
    if (overrideSecret != null && overrideSecret.isNotEmpty) {
      return overrideSecret;
    }

    final existingSecret = await storage.read(key: _kEncryptedDataSecretKey);
    if (existingSecret != null && existingSecret.isNotEmpty) {
      return existingSecret;
    }

    final generatedSecret = EncryptionHelper().generateSecretKeyHex(32);
    await storage.write(key: _kEncryptedDataSecretKey, value: generatedSecret);
    return generatedSecret;
  }

  Future<_DecryptedPayload?> _readEncryptedPayload({
    required String? secureOutput,
    required String? legacyOutput,
    required String? overrideSecret,
    required String? existingSecret,
  }) async {
    final candidates = <_EncryptedPayloadSource>[
      if (secureOutput != null)
        _EncryptedPayloadSource(
            output: secureOutput, location: _PayloadLocation.secureStorage),
      if (legacyOutput != null && legacyOutput != secureOutput)
        _EncryptedPayloadSource(
            output: legacyOutput, location: _PayloadLocation.sharedPrefs),
    ];

    final secrets = <String>[
      if (overrideSecret != null && overrideSecret.isNotEmpty) overrideSecret,
      if (existingSecret != null &&
          existingSecret.isNotEmpty &&
          existingSecret != overrideSecret)
        existingSecret,
      if (_kLegacyEncryptionSecret != overrideSecret &&
          _kLegacyEncryptionSecret != existingSecret)
        _kLegacyEncryptionSecret,
    ];

    for (final payload in candidates) {
      for (final secret in secrets) {
        try {
          final plainText = await _decryptStoredPayload(payload.output, secret);
          return _DecryptedPayload(
            plainText: plainText,
            usedSecret: secret,
            location: payload.location,
          );
        } catch (_) {
          continue;
        }
      }
    }

    return null;
  }

  Future<String> _decryptStoredPayload(String output, String secret) async {
    final hash = Uri.encodeComponent(output);
    final encodedSecret = jsonEncode(secret);
    final aesKey = Functions.generateKey(encodedSecret, 16);
    final encryptedData = base64Decode(Uri.decodeComponent(hash));
    final nonces = encryptedData.sublist(0, 16);
    final cipherText = encryptedData.sublist(16);

    final decryptedData =
        await Encryption().decryptData(aesKey, nonces, cipherText);
    return utf8.decode(decryptedData);
  }

  Future<void> _migrateEncryptedPayloadIfNeeded({
    required String? existingSecret,
    required String? secureOutput,
    required String? legacyOutput,
    required _DecryptedPayload decrypted,
    required Map<String, dynamic> decodedData,
  }) async {
    final targetSecret = existingSecret ?? await _resolveEncryptionSecret(null);
    final needsMigration = decrypted.usedSecret != targetSecret ||
        decrypted.location == _PayloadLocation.sharedPrefs ||
        secureOutput == null ||
        legacyOutput != null;

    if (!needsMigration) {
      return;
    }

    await encryptData(jsonEncode(decodedData), targetSecret);
  }

  //SEt Transaction Biometric  status
  Future<void> setTransBioStat(bool status) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('enable_biometric', status);
  }

  Future<bool?> getTransBioStat() async {
    final prefs = await SharedPreferences.getInstance();
    bool? isLogout = prefs.getBool("enable_biometric");

    if (isLogout == null) {
      return false;
    } else {
      return isLogout;
    }
  }

  //Set bio transaction
  Future<void> setBiometricTrans(bool status) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('enable_bio_trans', status);
  }

  Future<bool?> getBiometricTrans() async {
    final prefs = await SharedPreferences.getInstance();
    bool? isLogout = prefs.getBool("enable_bio_trans");

    if (isLogout == null) {
      return false;
    } else {
      return isLogout;
    }
  }

  ///THIS IS FPR IN APP OTP
  Future<void> setInAppOtp(bool value) async {
    final pref = await SharedPreferences.getInstance();
    await pref.setBool("in_app_otp", value);
  }

  Future<bool?> getInAppOtp() async {
    final pref = await SharedPreferences.getInstance();
    return pref.getBool("in_app_otp");
  }
}

enum _PayloadLocation { secureStorage, sharedPrefs }

class _EncryptedPayloadSource {
  final String output;
  final _PayloadLocation location;

  const _EncryptedPayloadSource({
    required this.output,
    required this.location,
  });
}

class _DecryptedPayload {
  final String plainText;
  final String usedSecret;
  final _PayloadLocation location;

  const _DecryptedPayload({
    required this.plainText,
    required this.usedSecret,
    required this.location,
  });
}
