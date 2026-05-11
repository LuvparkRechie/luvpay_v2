import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:luvpay/features/helpcenter/controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SupportChatMessageRecord {
  final String sender;
  final String message;
  final String source;
  final DateTime? createdAt;

  const SupportChatMessageRecord({
    required this.sender,
    required this.message,
    required this.source,
    this.createdAt,
  });

  factory SupportChatMessageRecord.fromMap(Map<String, dynamic> data) {
    return SupportChatMessageRecord(
        sender: _readString(data, "sender", fallback: "assistant"),
        message: _readString(data, "message"),
        source: _readString(data, "source"),
        createdAt: _readDate(data["created_at"]));
  }

  bool get isUser => sender == "user";
  bool get isSystem => sender == "system";
}

class SupportChatSession {
  final String sessionNo;
  final String status;
  final String category;
  final String lastMessage;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;
  final List<SupportChatMessageRecord> messages;

  const SupportChatSession({
    required this.sessionNo,
    required this.status,
    required this.category,
    required this.lastMessage,
    this.createdAt,
    this.updatedAt,
    this.resolvedAt,
    this.messages = const [],
  });

  factory SupportChatSession.fromMap(Map<String, dynamic> data) {
    final messages = _readMapList(data["messages"])
        .map(SupportChatMessageRecord.fromMap)
        .where((message) => message.message.isNotEmpty)
        .toList();

    return SupportChatSession(
        sessionNo: _readString(data, "session_no"),
        status: _readString(data, "status", fallback: "open"),
        category: _readString(data, "category", fallback: "General Support"),
        lastMessage: _readString(data, "last_message"),
        createdAt: _readDate(data["created_at"]),
        updatedAt: _readDate(data["updated_at"]),
        resolvedAt: _readDate(data["resolved_at"]),
        messages: messages);
  }

  bool get isResolved => status.toLowerCase() == "resolved";
}

class SupportChatException implements Exception {
  final String message;

  const SupportChatException(this.message);

  @override
  String toString() => message;
}

class SupportChatService {
  static const String endpoint = "https://luvpark.ph/support/chat-api.php";
  static const Duration timeout = Duration(seconds: 12);
  static const String _clientIdKey = "support_chat_client_id";

  Future<SupportChatSession> startOrResumeSession({
    required SupportUserProfile profile,
    String category = "General Support",
  }) async {
    final payload = await _basePayload(profile);
    payload.addAll({"action": "start_session", "category": category});

    final data = await _post(payload);
    return _sessionFromResponse(data);
  }

  Future<SupportChatSession?> getOpenSession({
    required SupportUserProfile profile,
  }) async {
    final payload = await _basePayload(profile);
    payload["action"] = "get_open_session";

    final data = await _post(payload);
    return _nullableSessionFromResponse(data);
  }

  Future<SupportChatSession> getSession({
    required SupportUserProfile profile,
    required String sessionNo,
  }) async {
    final payload = await _basePayload(profile);
    payload.addAll({"action": "get_session", "session_no": sessionNo});

    final data = await _post(payload);
    return _sessionFromResponse(data);
  }

  Future<List<SupportChatSession>> listSessions({
    required SupportUserProfile profile,
  }) async {
    final payload = await _basePayload(profile);
    payload["action"] = "list_sessions";

    final data = await _post(payload);
    final sessions = _readMapList(data["sessions"])
        .map(SupportChatSession.fromMap)
        .where((session) => session.sessionNo.isNotEmpty)
        .toList();

    return sessions;
  }

  Future<void> appendMessage({
    required SupportUserProfile profile,
    required String sessionNo,
    required String sender,
    required String message,
    required String source,
  }) async {
    final text = message.trim();
    if (text.isEmpty) return;

    final payload = await _basePayload(profile);
    payload.addAll({
      "action": "append_message",
      "session_no": sessionNo,
      "sender": sender,
      "message": text,
      "source": source,
    });

    await _post(payload);
  }

  Future<SupportChatSession> resolveSession({
    required SupportUserProfile profile,
    required String sessionNo,
  }) async {
    final payload = await _basePayload(profile);
    payload.addAll({"action": "resolve_session", "session_no": sessionNo});

    final data = await _post(payload);
    return _sessionFromResponse(data);
  }

  Future<Map<String, dynamic>> _basePayload(SupportUserProfile profile) async {
    return {
      "client_id": await _clientId(),
      "name": profile.displayName,
      "mobile_no": profile.localMobileNo,
      "email": profile.email,
    };
  }

  Future<Map<String, dynamic>> _post(Map<String, dynamic> payload) async {
    try {
      final response = await http
          .post(Uri.parse(endpoint),
              headers: const {
                "Accept": "application/json",
                "Content-Type": "application/json",
              },
              body: jsonEncode(payload))
          .timeout(timeout);

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map) {
        throw const SupportChatException("Invalid chat server response.");
      }

      final data = Map<String, dynamic>.from(decoded);
      final success = data["success"] == true;
      if (!success) {
        throw SupportChatException(
            _readString(data, "message", fallback: "Chat request failed."));
      }

      return data;
    } on TimeoutException {
      throw const SupportChatException("Chat server request timed out.");
    } on SupportChatException {
      rethrow;
    } catch (e) {
      debugPrint("Support chat API failed: $e");
      throw const SupportChatException("Unable to connect to chat server.");
    }
  }

  SupportChatSession _sessionFromResponse(Map<String, dynamic> data) {
    final sessionData = data["session"];
    if (sessionData is! Map) {
      throw const SupportChatException("Chat session is missing.");
    }

    final session =
        SupportChatSession.fromMap(Map<String, dynamic>.from(sessionData));
    if (session.sessionNo.isEmpty) {
      throw const SupportChatException("Chat session number is missing.");
    }

    return session;
  }

  SupportChatSession? _nullableSessionFromResponse(Map<String, dynamic> data) {
    final sessionData = data["session"];
    if (sessionData == null) return null;
    if (sessionData is! Map) {
      throw const SupportChatException("Invalid chat session response.");
    }

    final session =
        SupportChatSession.fromMap(Map<String, dynamic>.from(sessionData));
    return session.sessionNo.isEmpty ? null : session;
  }

  Future<String> _clientId() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_clientIdKey);
    if (saved != null && saved.trim().isNotEmpty) return saved;

    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    final id = base64UrlEncode(bytes).replaceAll("=", "");
    await prefs.setString(_clientIdKey, id);
    return id;
  }
}

String _readString(Map<String, dynamic> data, String key,
    {String fallback = ""}) {
  final value = data[key];
  if (value == null) return fallback;

  final text = value.toString().trim();
  if (text.isEmpty || text.toLowerCase() == "null") return fallback;

  return text;
}

DateTime? _readDate(dynamic value) {
  if (value == null) return null;

  final text = value.toString().trim();
  if (text.isEmpty || text.toLowerCase() == "null") return null;

  return DateTime.tryParse(text.replaceFirst(" ", "T"));
}

List<Map<String, dynamic>> _readMapList(dynamic value) {
  if (value is! List) return const [];

  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}
