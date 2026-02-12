import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:pointycastle/export.dart' as crypto;

class Encryption_ {
  Future<Uint8List> encryptData(
    Uint8List secretKey,
    Uint8List iv,
    String plainText,
  ) async {
    final cipher = crypto.GCMBlockCipher(crypto.AESEngine());
    final keyParams = crypto.KeyParameter(secretKey);
    final cipherParams = crypto.ParametersWithIV(keyParams, iv);
    cipher.init(true, cipherParams);

    final encodedPlainText = utf8.encode(plainText);
    final cipherText = cipher.process(Uint8List.fromList(encodedPlainText));

    return Uint8List.fromList(cipherText);
  }

  Future<Uint8List> decryptData(
    Uint8List secretKey,
    Uint8List nonce,
    Uint8List cipherText,
  ) async {
    final cipher = crypto.GCMBlockCipher(crypto.AESEngine());
    final keyParams = crypto.KeyParameter(secretKey);
    final cipherParams = crypto.ParametersWithIV(keyParams, nonce);
    cipher.init(false, cipherParams);

    final plainTextBytes = cipher.process(cipherText);

    return Uint8List.fromList(plainTextBytes);
  }

  String arrayBufferToBase64(ByteBuffer buffer) {
    var bytes = Uint8List.view(buffer);
    var base64String = base64.encode(bytes);
    return base64String;
  }

  Uint8List hexStringToArrayBuffer(String hexString) {
    final result = Uint8List(hexString.length ~/ 2);
    for (var i = 0; i < hexString.length; i += 2) {
      result[(i ~/ 2)] = int.parse(hexString.substring(i, i + 2), radix: 16);
    }
    return result;
  }

  ByteBuffer concatBuffers(Uint8List buffer1, Uint8List buffer2) {
    final tmp = Uint8List(buffer1.length + buffer2.length);
    tmp.setAll(0, buffer1);
    tmp.setAll(buffer1.length, buffer2);
    return tmp.buffer;
  }

  Uint8List generateRandomNonce() {
    var random = Random.secure();
    var iv = Uint8List(16);
    for (var i = 0; i < iv.length; i++) {
      iv[i] = random.nextInt(256);
    }
    return iv;
  }

  Future<String> decryptUBUriPage(
    String encryptedDataBase64,
    String secretKeyHex,
  ) async {
    final secretKey = hexStringToArrayBuffer(secretKeyHex);

    final encryptedData = base64Decode(encryptedDataBase64);

    final nonce = encryptedData.sublist(0, 16);
    final cipherText = encryptedData.sublist(16);

    final decryptedData = await decryptData(secretKey, nonce, cipherText);

    return utf8.decode(decryptedData);
  }

  String generateSecretKeyHex(int length) {
    final random = Random.secure();
    final bytes = List<int>.generate(length, (_) => random.nextInt(256));
    return hex.encode(bytes);
  }
}
