import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class SupportTicketResult {
  final bool success;
  final String message;
  final String? ticketNo;

  const SupportTicketResult({
    required this.success,
    required this.message,
    this.ticketNo,
  });
}

class SupportTicketService {
  static const String endpoint = "https://luvpark.ph/support/send-email.php";
  static const int maxAttachmentBytes = 5 * 1024 * 1024;
  static const Duration requestTimeout = Duration(seconds: 35);

  Future<SupportTicketResult> submitTicket({
    required String name,
    required String mobileNo,
    required String email,
    required String category,
    required String message,
    File? attachment,
  }) async {
    try {
      if (attachment != null &&
          await attachment.length() > maxAttachmentBytes) {
        return const SupportTicketResult(
            success: false, message: "File size must be less than 5MB");
      }

      final request = http.MultipartRequest("POST", Uri.parse(endpoint))
        ..fields.addAll({
          "name": name.trim(),
          "mobile_no": mobileNo.trim(),
          "email": email.trim(),
          "category": category.trim(),
          "message": message.trim(),
          "platform": Platform.operatingSystem,
        });

      if (attachment != null) {
        request.files.add(
            await http.MultipartFile.fromPath("attachment", attachment.path));
      }

      final response = await request.send().timeout(requestTimeout);
      final body = await response.stream.bytesToString();
      final payload = _decodePayload(body);
      final success = response.statusCode >= 200 &&
          response.statusCode < 300 &&
          payload["success"] == true;

      if (!success) {
        _logFailedResponse(response.statusCode, body);
      }

      return SupportTicketResult(
          success: success,
          message: _readMessage(payload, success, response.statusCode, body),
          ticketNo: payload["ticket_no"]?.toString());
    } on TimeoutException {
      return const SupportTicketResult(
          success: false, message: "Request timed out. Please try again.");
    } on SocketException {
      return const SupportTicketResult(
          success: false,
          message: "No internet connection. Please try again later.");
    } catch (e) {
      debugPrint("Support ticket request failed: $e");
      return const SupportTicketResult(
          success: false,
          message: "Unable to send support request. Please try again.");
    }
  }

  Map<String, dynamic> _decodePayload(String body) {
    if (body.trim().isEmpty) return <String, dynamic>{};

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (e) {
      debugPrint("Unable to decode support ticket response: $e");
    }

    return <String, dynamic>{};
  }

  String _readMessage(
      Map<String, dynamic> payload, bool success, int statusCode, String body) {
    final message = payload["message"]?.toString().trim();
    if (message != null && message.isNotEmpty) return message;

    if (success) return "Support request sent.";

    if (statusCode >= 500 || body.trim().isEmpty) {
      return "Support server is unavailable. Please try again later.";
    }

    return "Unable to send support request. Please try again.";
  }

  void _logFailedResponse(int statusCode, String body) {
    final responseBody = body.trim();
    debugPrint("Support ticket request failed with status $statusCode.");
    if (responseBody.isNotEmpty) {
      debugPrint("Support ticket response: $responseBody");
    }
  }
}
