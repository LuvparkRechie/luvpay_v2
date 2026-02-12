import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:luvpay/core/security/encryption.dart';

class AgentX_ {
  Future<String> agentBuffer(String json) async {
    final secretKey = Encryption_().hexStringToArrayBuffer(
      dotenv.env['AGENT_X'] ?? '',
    );
    final nonce = Encryption_().generateRandomNonce();

    final encrypted = await Encryption_().encryptData(
      secretKey,
      nonce,
      AgentX_().compressString(json),
    );

    final concatenatedArray = Encryption_().concatBuffers(nonce, encrypted);
    final output = Encryption_().arrayBufferToBase64(concatenatedArray);

    return output;
  }

  Future<dynamic> agentJson(String buffer) async {
    final decryptedJson = await Encryption_().decryptUBUriPage(
      buffer,
      dotenv.env['AGENT_X'] ?? '',
    );

    return jsonDecode(decryptedJson);
  }

  String compressString(String input) {
    List<int> inputBytes = utf8.encode(input);

    List<int> compressedBytes = GZipEncoder().encode(inputBytes);

    return base64Encode(compressedBytes);
  }

  List<dynamic> decompressString(String compressedInput) {
    //List<int> compressedBytes = base64Decode(compressedInput);
    //List<int> decompressedBytes = GZipDecoder().decodeBytes(compressedBytes);
    //return jsonDecode(utf8.decode(decompressedBytes));
    return jsonDecode(compressedInput);
  }

  Uint8List generateRandomIV(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => random.nextInt(256)),
    );
  }

  String encryptAES256CBC(String plainText) {
    final key = Key(base64Decode(dotenv.env['SECRET_B64'] ?? ''));
    final iv = IV(generateRandomIV(16));
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc, padding: 'PKCS7'));
    final encrypted = encrypter.encrypt(plainText, iv: iv);

    return base64Encode(iv.bytes + encrypted.bytes);
  }

  String decryptAES256CBC(String encryptedTextWithIV) {
    final key = Key(base64Decode(dotenv.env['SECRET_B64'] ?? ''));
    final encryptedBytes = base64Decode(encryptedTextWithIV);

    final iv = IV(encryptedBytes.sublist(0, 16));
    final cipherText = Encrypted(encryptedBytes.sublist(16));

    final encrypter = Encrypter(AES(key, mode: AESMode.cbc, padding: 'PKCS7'));
    return encrypter.decrypt(cipherText, iv: iv);
  }

  String decodeTicketId(String hexBase64EncodedUid) {
    Uint8List hexDecoded = hexToBytes(hexBase64EncodedUid);

    Uint8List base64Decoded = base64Decode(utf8.decode(hexDecoded));

    return utf8.decode(base64Decoded);
  }

  Uint8List hexToBytes(String hex) {
    return Uint8List.fromList(
      List.generate(
        hex.length ~/ 2,
        (i) => int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16),
      ),
    );
  }

  String encodeTicketId(String ticketId) {
    Uint8List utf8Bytes = utf8.encode(ticketId);

    String base64Encoded = base64Encode(utf8Bytes);

    return bytesToHex(utf8.encode(base64Encoded));
  }

  String bytesToHex(Uint8List bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
