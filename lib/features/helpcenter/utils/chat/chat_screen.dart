import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:luvpay/auth/authentication.dart';
import 'package:luvpay/features/helpcenter/controller.dart';
import 'package:luvpay/shared/dialogs/dialogs.dart';
import 'package:luvpay/shared/widgets/colors.dart';
import 'package:luvpay/shared/widgets/custom_scaffold.dart';
import 'package:luvpay/shared/widgets/luvpay_text.dart';

import 'chat_list_screen.dart';
import 'support_chat_service.dart';

class SupportChatTopic {
  final String id;
  final String label;
  final IconData icon;
  final Color color;
  final List<SupportChatQuestion> questions;

  const SupportChatTopic({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    required this.questions,
  });

  factory SupportChatTopic.fromMap(Map<String, dynamic> data) {
    final questions = _readMapList(data["questions"])
        .map(SupportChatQuestion.fromMap)
        .where((question) => question.title.isNotEmpty)
        .toList();

    return SupportChatTopic(
        id: _readString(data, "id", fallback: "topic"),
        label: _readString(data, "label", fallback: "Support"),
        icon: _topicIcon(_readString(data, "icon")),
        color: _hexColor(_readString(data, "color"),
            fallback: AppColorV2.lpBlueBrand),
        questions: questions);
  }
}

class SupportChatQuestion {
  final String id;
  final String title;
  final List<String> answers;
  final List<String> keywords;

  const SupportChatQuestion({
    required this.id,
    required this.title,
    required this.answers,
    this.keywords = const [],
  });

  factory SupportChatQuestion.fromMap(Map<String, dynamic> data) {
    return SupportChatQuestion(
        id: _readString(data, "id", fallback: "question"),
        title: _readString(data, "title"),
        answers: _readStringList(data["answers"]),
        keywords: _readStringList(data["keywords"]));
  }
}

class SupportChatMessage {
  final String text;
  final bool isUser;
  final bool isSystem;

  const SupportChatMessage({
    required this.text,
    required this.isUser,
    this.isSystem = false,
  });

  factory SupportChatMessage.fromRecord(SupportChatMessageRecord record) {
    return SupportChatMessage(
        text: record.message, isUser: record.isUser, isSystem: record.isSystem);
  }
}

class SupportChatContent {
  final List<String> quickReplies;
  final List<SupportChatQuestion> starterQuestions;
  final List<SupportChatTopic> topics;

  const SupportChatContent({
    required this.quickReplies,
    required this.starterQuestions,
    required this.topics,
  });

  factory SupportChatContent.fromMap(Map<String, dynamic> data) {
    final quickReplies = _readStringList(data["quick_replies"]);
    final starterQuestions = _readMapList(data["starter_questions"])
        .map(SupportChatQuestion.fromMap)
        .where((question) => question.title.isNotEmpty)
        .toList();
    final topics = _readMapList(data["topics"])
        .map(SupportChatTopic.fromMap)
        .where((topic) => topic.questions.isNotEmpty)
        .toList();

    if (quickReplies.isEmpty || starterQuestions.isEmpty || topics.isEmpty) {
      throw const FormatException("Chat content is incomplete.");
    }

    return SupportChatContent(
        quickReplies: quickReplies,
        starterQuestions: starterQuestions,
        topics: topics);
  }

  static const fallback = SupportChatContent(
      quickReplies: _quickReplies,
      starterQuestions: _starterQuestions,
      topics: _topics);
}

class SupportChatContentService {
  static const String endpoint = "https://luvpark.ph/support/chat-api.php";
  static const Duration timeout = Duration(seconds: 8);

  Future<SupportChatContent> loadContent() async {
    try {
      final response = await http
          .post(Uri.parse(endpoint),
              headers: const {
                "Accept": "application/json",
                "Content-Type": "application/json",
              },
              body: jsonEncode({"action": "get_content"}))
          .timeout(timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception("Unexpected status ${response.statusCode}");
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map) {
        throw const FormatException("Chat content must be a JSON object.");
      }

      final payload = Map<String, dynamic>.from(decoded);
      if (payload["success"] != true) {
        throw FormatException(_readString(payload, "message",
            fallback: "Chat content request failed."));
      }

      return SupportChatContent.fromMap(payload);
    } on TimeoutException {
      debugPrint("Support chat content request timed out.");
    } catch (e) {
      debugPrint("Unable to load support chat content: $e");
    }

    return SupportChatContent.fallback;
  }
}

String _readString(Map<String, dynamic> data, String key,
    {String fallback = ""}) {
  final value = data[key];
  if (value == null) return fallback;

  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

List<String> _readStringList(dynamic value) {
  if (value is! List) return const [];

  return value
      .map((item) => item?.toString().trim() ?? "")
      .where((item) => item.isNotEmpty)
      .toList();
}

List<Map<String, dynamic>> _readMapList(dynamic value) {
  if (value is! List) return const [];

  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}

IconData _topicIcon(String key) {
  switch (key.trim().toLowerCase()) {
    case "wallet":
    case "payment":
      return Icons.account_balance_wallet_outlined;
    case "parking":
      return Icons.local_parking_outlined;
    case "account":
    case "profile":
      return Icons.person_outline;
    case "security":
    case "fraud":
      return Icons.security_outlined;
    case "promo":
    case "promos":
      return Icons.local_offer_outlined;
    default:
      return Icons.support_agent_outlined;
  }
}

Color _hexColor(String value, {required Color fallback}) {
  final hex = value.replaceAll("#", "").trim();
  if (hex.length != 6 && hex.length != 8) return fallback;

  final parsed = int.tryParse(hex.length == 6 ? "FF$hex" : hex, radix: 16);
  return parsed == null ? fallback : Color(parsed);
}

class ChatScreen extends StatefulWidget {
  final String? ticketNumber;
  final String? category;

  const ChatScreen({super.key, this.ticketNumber, this.category});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const SupportUserProfile _emptyProfile = SupportUserProfile(
      firstName: "", middleName: "", lastName: "", mobileNo: "", email: "");

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final SupportChatService _chatService = SupportChatService();

  final List<SupportChatMessage> _messages = [];
  SupportChatContent _content = SupportChatContent.fallback;
  List<SupportChatQuestion> _currentSuggestions =
      SupportChatContent.fallback.starterQuestions;
  SupportUserProfile _profile = _emptyProfile;
  SupportChatSession? _session;
  bool _hasUserInteracted = false;
  bool _isLoadingSession = true;
  bool _isStartingSession = false;
  bool _isResolving = false;
  String? _sessionWarning;

  @override
  void initState() {
    super.initState();
    _messages.add(_welcomeMessage("there"));
    _loadChatContent();
    unawaited(_loadSession());
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadChatContent() async {
    final content = await SupportChatContentService().loadContent();
    if (!mounted) return;

    setState(() {
      _content = content;
      if (!_isReadOnly &&
          (!_hasUserInteracted || _isShowingFallbackSuggestions)) {
        _currentSuggestions = content.starterQuestions;
      }
    });
  }

  Future<void> _loadSession() async {
    final profile =
        SupportUserProfile.tryParse(await Authentication().getUserData2()) ??
            _emptyProfile;
    final name = _displayName(profile);

    try {
      final sessionNo = widget.ticketNumber?.trim();
      final session = sessionNo == null || sessionNo.isEmpty
          ? await _chatService.getOpenSession(profile: profile)
          : await _chatService.getSession(
              profile: profile,
              sessionNo: sessionNo,
            );

      final savedMessages =
          session?.messages.map(SupportChatMessage.fromRecord).toList() ??
              const <SupportChatMessage>[];
      final welcome = _welcomeMessage(name);
      final nextMessages = savedMessages.isEmpty ? [welcome] : savedMessages;

      if (!mounted) return;

      setState(() {
        _profile = profile;
        _session = session;
        _messages
          ..clear()
          ..addAll(nextMessages);
        _hasUserInteracted = nextMessages.any((message) => message.isUser);
        _currentSuggestions =
            session?.isResolved == true ? const [] : _content.starterQuestions;
        _isLoadingSession = false;
        _sessionWarning = null;
      });

      _scrollToBottom();
    } catch (e) {
      debugPrint("Unable to load support chat session: $e");
      if (!mounted) return;

      setState(() {
        _profile = profile;
        _session = null;
        _messages[0] = _welcomeMessage(name);
        _currentSuggestions = const [];
        _isLoadingSession = false;
        _sessionWarning =
            "Chat history is unavailable. Chat will be enabled after the cPanel chat database is configured.";
      });
    }
  }

  String _displayName(SupportUserProfile profile) {
    final displayName = profile.displayName.trim();
    return displayName.isEmpty ? "there" : displayName.toUpperCase();
  }

  static SupportChatMessage _welcomeMessage(String name) {
    return SupportChatMessage(
        isUser: false,
        text: "Hi, $name! Thank you for reaching out to LuvPay Support.\n\n"
            "By continuing with this chat, please do not share your OTP, PIN, password, or full card details.\n\n"
            "Type your question below or select one of the available options.");
  }

  void _openTopic(SupportChatTopic topic) {
    unawaited(_openTopicAsync(topic));
  }

  Future<void> _openTopicAsync(SupportChatTopic topic) async {
    if (!_canUseChat) return;
    final session = await _ensureActiveSession();
    if (session == null || !mounted) return;

    final userMessage = SupportChatMessage(text: topic.label, isUser: true);
    final assistantMessage = SupportChatMessage(
        text:
            "Here are the common ${topic.label.toLowerCase()} questions I can help with.",
        isUser: false);

    setState(() {
      _hasUserInteracted = true;
      _messages.add(userMessage);
      _messages.add(assistantMessage);
      _currentSuggestions = topic.questions;
    });

    unawaited(_persistMessage(userMessage, source: "topic"));
    unawaited(_persistMessage(assistantMessage, source: "topic"));
    _scrollToBottom();
  }

  void _sendQuestion(SupportChatQuestion question) {
    _sendText(question.title, exactQuestion: question);
  }

  void _sendTypedMessage() {
    _sendText(_textController.text);
  }

  void _sendText(String value, {SupportChatQuestion? exactQuestion}) {
    unawaited(_sendTextAsync(value, exactQuestion: exactQuestion));
  }

  Future<void> _sendTextAsync(String value,
      {SupportChatQuestion? exactQuestion}) async {
    final text = value.trim();
    if (text.isEmpty) return;
    if (!_canUseChat) return;
    final session = await _ensureActiveSession();
    if (session == null || !mounted) return;

    _textController.clear();
    final userMessage = SupportChatMessage(text: text, isUser: true);

    setState(() {
      _hasUserInteracted = true;
      _messages.add(userMessage);
      _currentSuggestions = const [];
    });

    unawaited(_persistMessage(
      userMessage,
      source: exactQuestion == null ? "typed" : "suggestion",
    ));

    Future<void>.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) return;

      final matchedQuestion = exactQuestion ?? _matchQuestion(text);
      final replies = <SupportChatMessage>[];

      setState(() {
        if (matchedQuestion == null) {
          replies.add(const SupportChatMessage(
              isUser: false,
              text:
                  "I could not find an exact self-service answer for that yet. If this needs account review, use Email us so the support team receives your details and attachments as a ticket."));
          _currentSuggestions = _content.starterQuestions;
        } else {
          for (final answer in matchedQuestion.answers) {
            replies.add(SupportChatMessage(text: answer, isUser: false));
          }
          _currentSuggestions = _relatedQuestions(matchedQuestion);
        }

        _messages.addAll(replies);
      });

      for (final reply in replies) {
        unawaited(_persistMessage(reply, source: "assistant"));
      }

      _scrollToBottom();
    });

    _scrollToBottom();
  }

  Future<SupportChatSession?> _ensureActiveSession() async {
    final current = _session;
    if (current != null && !current.isResolved) return current;

    setState(() {
      _isStartingSession = true;
      _sessionWarning = null;
    });

    try {
      final session = await _chatService.startOrResumeSession(
          profile: _profile, category: widget.category ?? "General Support");
      if (!mounted) return session;

      setState(() {
        _session = session;
        _isStartingSession = false;
      });

      return session;
    } catch (e) {
      debugPrint("Unable to start support chat session: $e");
      if (!mounted) return null;

      setState(() {
        _isStartingSession = false;
        _sessionWarning =
            "Chat could not start. Please try again when the cPanel chat database is ready.";
      });
      CustomDialogStack.showSnackBar(context, e.toString(), null, null);
      return null;
    }
  }

  Future<void> _persistMessage(
    SupportChatMessage message, {
    required String source,
  }) async {
    final sessionNo = _session?.sessionNo;
    if (sessionNo == null || sessionNo.isEmpty) return;

    try {
      await _chatService.appendMessage(
          profile: _profile,
          sessionNo: sessionNo,
          sender: _senderFor(message),
          message: message.text,
          source: source);
    } catch (e) {
      debugPrint("Unable to save support chat message: $e");
      if (!mounted || _sessionWarning != null) return;

      setState(() {
        _sessionWarning =
            "Chat history is temporarily unavailable. Your next successful connection will continue from the last saved message.";
      });
    }
  }

  String _senderFor(SupportChatMessage message) {
    if (message.isUser) return "user";
    if (message.isSystem) return "system";

    return "assistant";
  }

  SupportChatQuestion? _matchQuestion(String text) {
    final normalized = text.toLowerCase();

    for (final topic in _content.topics) {
      for (final question in topic.questions) {
        if (question.title.toLowerCase() == normalized) return question;
      }
    }

    for (final topic in _content.topics) {
      for (final question in topic.questions) {
        if (question.keywords.any(normalized.contains)) return question;
      }
    }

    return null;
  }

  List<SupportChatQuestion> _relatedQuestions(SupportChatQuestion selected) {
    for (final topic in _content.topics) {
      if (topic.questions.any((question) => question.id == selected.id)) {
        return topic.questions
            .where((question) => question.id != selected.id)
            .take(3)
            .toList();
      }
    }

    return _content.starterQuestions;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut);
    });
  }

  bool get _isReadOnly => _session?.isResolved == true;

  bool get _canUseChat =>
      !_isLoadingSession &&
      !_isStartingSession &&
      !_isReadOnly &&
      _sessionWarning == null;

  bool get _canResolve =>
      _hasUserInteracted &&
      _session != null &&
      !_isReadOnly &&
      !_isLoadingSession &&
      !_isStartingSession &&
      !_isResolving &&
      _sessionWarning == null;

  bool get _isShowingFallbackSuggestions {
    if (_currentSuggestions.length !=
        SupportChatContent.fallback.starterQuestions.length) {
      return false;
    }

    for (var i = 0; i < _currentSuggestions.length; i++) {
      if (_currentSuggestions[i].id !=
          SupportChatContent.fallback.starterQuestions[i].id) {
        return false;
      }
    }

    return true;
  }

  void _resolveChat() {
    final sessionNo = _session?.sessionNo;
    if (sessionNo == null || sessionNo.isEmpty || !_canResolve) return;

    CustomDialogStack.showConfirmation(
        context,
        "Resolve Chat?",
        "This will close the current chat. You can still view it in history, and your next concern will start a new chat.",
        () => Get.back(), () {
      Get.back();
      unawaited(_resolveConfirmedChat(sessionNo));
    }, leftText: "Cancel", rightText: "Resolve", textAlign: TextAlign.center);
  }

  Future<void> _resolveConfirmedChat(String sessionNo) async {
    setState(() => _isResolving = true);

    try {
      final session = await _chatService.resolveSession(
          profile: _profile, sessionNo: sessionNo);
      final messages =
          session.messages.map(SupportChatMessage.fromRecord).toList();

      if (!mounted) return;

      setState(() {
        _session = session;
        _messages
          ..clear()
          ..addAll(messages);
        _currentSuggestions = const [];
        _isResolving = false;
        _sessionWarning = null;
      });

      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;

      setState(() => _isResolving = false);
      CustomDialogStack.showSnackBar(context, e.toString(), null, null);
    }
  }

  Future<void> _openHistory() async {
    await Get.to(() => const ChatListScreen());
    if (mounted && widget.ticketNumber == null) {
      unawaited(_loadSession());
    }
  }

  void _startNewChat() {
    Get.off(() => const ChatScreen());
  }

  Future<void> _handleBack() async {
    FocusScope.of(context).unfocus();

    if (_isStartingSession || _isResolving) {
      CustomDialogStack.showSnackBar(
          context, "Please wait for the chat action to finish.", null, null);
      return;
    }

    final didPop = await Navigator.of(context).maybePop();
    if (!didPop && Get.key.currentState?.canPop() == true) {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffoldV2(
        appBarTitle: "LuvPay Assist",
        onPressedLeading: () => unawaited(_handleBack()),
        appBarAction: [
          IconButton(
              tooltip: "Chat history",
              onPressed: _openHistory,
              icon: const Icon(Icons.history_rounded)),
          if (!_isReadOnly)
            IconButton(
                tooltip: "Mark resolved",
                onPressed: _canResolve ? _resolveChat : null,
                icon: _isResolving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check_circle_outline_rounded)),
        ],
        padding: EdgeInsets.zero,
        scaffoldBody: Column(children: [
          _PrivacyNotice(
              title: _noticeTitle(),
              stepText: _isReadOnly ? "Resolved" : "Open",
              statusColor: _isReadOnly
                  ? AppColorV2.darkMintAccent
                  : AppColorV2.lpBlueBrand),
          if (_sessionWarning != null)
            _SessionWarning(message: _sessionWarning!),
          Expanded(
              child: ListView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics()),
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                  children: [
                for (final message in _messages) _ChatBubble(message: message),
                const SizedBox(height: 8),
                if (!_isReadOnly && _canUseChat) ...[
                  _TopicRail(topics: _content.topics, onTopicTap: _openTopic),
                  const SizedBox(height: 14),
                  if (_currentSuggestions.isNotEmpty)
                    _SuggestionPanel(
                        questions: _currentSuggestions,
                        onQuestionTap: _sendQuestion),
                ] else if (_isReadOnly)
                  _ResolvedChatFooter(onStartNew: _startNewChat),
                if (!_isReadOnly && !_canUseChat) const _ChatUnavailablePanel(),
              ])),
          if (_isReadOnly)
            _ResolvedComposer(onStartNew: _startNewChat)
          else
            _ChatComposer(
                controller: _textController,
                quickReplies: _content.quickReplies,
                enabled: _canUseChat,
                onQuickReplyTap: _sendText,
                onSend: _sendTypedMessage),
        ]));
  }

  String _noticeTitle() {
    return "Privacy Notice";
  }
}

class _PrivacyNotice extends StatelessWidget {
  final String title;
  final String stepText;
  final Color statusColor;

  const _PrivacyNotice({
    required this.title,
    required this.stepText,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
            color: AppColorV2.warning.withValues(alpha: 0.12),
            border: Border(
                bottom: BorderSide(
                    color: AppColorV2.warning.withValues(alpha: 0.18)))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                  color: AppColorV2.warning.withValues(alpha: 0.18),
                  shape: BoxShape.circle),
              child: const Icon(Icons.notifications_active_outlined,
                  size: 16, color: AppColorV2.warning)),
          const SizedBox(width: 8),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                LuvpayText(
                    text: title,
                    style: AppTextStyle.body1(context),
                    color: AppColorV2.warning,
                    maxLines: 1),
                const SizedBox(height: 2),
                const LuvpayText(
                    text: "Never share OTP, PIN, password, or card details.",
                    fontSize: 11,
                    color: AppColorV2.bodyTextColor,
                    overflow: TextOverflow.ellipsis),
              ])),
          Container(
              constraints: const BoxConstraints(minWidth: 72),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14)),
              child: LuvpayText(
                  text: "Status: $stepText",
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  textAlign: TextAlign.center,
                  color: statusColor,
                  maxLines: 1)),
        ]));
  }
}

class _SessionWarning extends StatelessWidget {
  final String message;

  const _SessionWarning({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: AppColorV2.warning.withValues(alpha: 0.08),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.info_outline_rounded,
              size: 18, color: AppColorV2.warning),
          const SizedBox(width: 8),
          Expanded(
              child: LuvpayText(
                  text: message,
                  fontSize: 12,
                  color: AppColorV2.warning,
                  maxLines: 3,
                  overflow: TextOverflow.visible)),
        ]));
  }
}

class _ChatUnavailablePanel extends StatelessWidget {
  const _ChatUnavailablePanel();

  @override
  Widget build(BuildContext context) {
    return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColorV2.boxStroke)),
        child: const Column(children: [
          Icon(Icons.storage_outlined, color: AppColorV2.lpBlueBrand),
          SizedBox(height: 10),
          LuvpayText(
              text: "Chat history is connecting",
              fontSize: 14,
              fontWeight: FontWeight.w700,
              maxLines: 1),
          SizedBox(height: 4),
          LuvpayText(
              text:
                  "Messages are disabled until the cPanel chat database is ready, so this conversation will not be erased.",
              fontSize: 12,
              color: AppColorV2.bodyTextColor,
              maxLines: 3,
              textAlign: TextAlign.center,
              overflow: TextOverflow.visible),
        ]));
  }
}

class _TopicRail extends StatelessWidget {
  final List<SupportChatTopic> topics;
  final ValueChanged<SupportChatTopic> onTopicTap;

  const _TopicRail({required this.topics, required this.onTopicTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: 112,
        child: ListView.separated(
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            itemCount: topics.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final topic = topics[index];

              return _TopicCard(topic: topic, onTap: () => onTopicTap(topic));
            }));
  }
}

class _TopicCard extends StatelessWidget {
  final SupportChatTopic topic;
  final VoidCallback onTap;

  const _TopicCard({required this.topic, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
            width: 116,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColorV2.boxStroke)),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                  width: 42,
                  height: 42,
                  decoration:
                      BoxDecoration(color: topic.color, shape: BoxShape.circle),
                  child: Icon(topic.icon, color: Colors.white, size: 22)),
              const SizedBox(height: 10),
              LuvpayText(
                  text: topic.label,
                  textAlign: TextAlign.center,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                  maxLines: 2,
                  minFontSize: 10),
            ])));
  }
}

class _SuggestionPanel extends StatelessWidget {
  final List<SupportChatQuestion> questions;
  final ValueChanged<SupportChatQuestion> onQuestionTap;

  const _SuggestionPanel({
    required this.questions,
    required this.onQuestionTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
        decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColorV2.boxStroke)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: LuvpayText(
                  text: "You may want to ask:",
                  style: AppTextStyle.h3(context),
                  maxLines: 1)),
          for (final question in questions)
            InkWell(
                onTap: () => onQuestionTap(question),
                child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: const BoxDecoration(
                        border: Border(
                            top: BorderSide(color: AppColorV2.boxStroke))),
                    child: LuvpayText(
                        text: question.title,
                        fontSize: 14,
                        color: AppColorV2.lpBlueBrand,
                        maxLines: 2,
                        overflow: TextOverflow.visible))),
        ]));
  }
}

class _ChatBubble extends StatelessWidget {
  final SupportChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (message.isSystem) {
      return Center(
          child: Container(
              margin: const EdgeInsets.only(bottom: 12, top: 2),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                  color: AppColorV2.boxStroke.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(18)),
              child: LuvpayText(
                  text: message.text,
                  fontSize: 12,
                  color: AppColorV2.bodyTextColor,
                  maxLines: 4,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.visible)));
    }

    final alignment =
        message.isUser ? Alignment.centerRight : Alignment.centerLeft;
    final bubbleColor =
        message.isUser ? AppColorV2.pastelBlueAccent : cs.surface;
    final borderColor =
        message.isUser ? Colors.transparent : AppColorV2.boxStroke;

    return Align(
        alignment: alignment,
        child: Container(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.78),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(8),
                    topRight: const Radius.circular(8),
                    bottomLeft: Radius.circular(message.isUser ? 8 : 2),
                    bottomRight: Radius.circular(message.isUser ? 2 : 8)),
                border: Border.all(color: borderColor)),
            child: LuvpayText(
                text: message.text,
                fontSize: 14,
                color: cs.onSurface,
                maxLines: 16,
                overflow: TextOverflow.visible)));
  }
}

class _ResolvedChatFooter extends StatelessWidget {
  final VoidCallback onStartNew;

  const _ResolvedChatFooter({required this.onStartNew});

  @override
  Widget build(BuildContext context) {
    return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: AppColorV2.darkMintAccent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: AppColorV2.darkMintAccent.withValues(alpha: 0.18))),
        child: Row(children: [
          const Icon(Icons.check_circle_outline_rounded,
              color: AppColorV2.darkMintAccent),
          const SizedBox(width: 10),
          const Expanded(
              child: LuvpayText(
                  text:
                      "This chat is resolved and saved in your support history.",
                  fontSize: 13,
                  color: AppColorV2.bodyTextColor,
                  maxLines: 2,
                  overflow: TextOverflow.visible)),
          TextButton(
              onPressed: onStartNew,
              child: const LuvpayText(
                  text: "New chat",
                  color: AppColorV2.lpBlueBrand,
                  fontWeight: FontWeight.w700)),
        ]));
  }
}

class _ResolvedComposer extends StatelessWidget {
  final VoidCallback onStartNew;

  const _ResolvedComposer({required this.onStartNew});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        top: false,
        child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColorV2.boxStroke))),
            child: ElevatedButton.icon(
                onPressed: onStartNew,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColorV2.lpBlueBrand,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8))),
                icon: const Icon(Icons.add_comment_outlined),
                label: const LuvpayText(
                    text: "Start New Chat",
                    color: Colors.white,
                    fontWeight: FontWeight.w700))));
  }
}

class _ChatComposer extends StatelessWidget {
  final TextEditingController controller;
  final List<String> quickReplies;
  final bool enabled;
  final ValueChanged<String> onQuickReplyTap;
  final VoidCallback onSend;

  const _ChatComposer({
    required this.controller,
    required this.quickReplies,
    required this.enabled,
    required this.onQuickReplyTap,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        top: false,
        child: Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColorV2.boxStroke))),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              SizedBox(
                  height: 36,
                  child: ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      scrollDirection: Axis.horizontal,
                      itemCount: quickReplies.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final reply = quickReplies[index];

                        return ActionChip(
                            label: LuvpayText(
                                text: reply,
                                maxLines: 1,
                                fontSize: 12,
                                color: AppColorV2.bodyTextColor),
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: AppColorV2.boxStroke),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            onPressed:
                                enabled ? () => onQuickReplyTap(reply) : null);
                      })),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                    child: TextField(
                        controller: controller,
                        enabled: enabled,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) {
                          if (enabled) onSend();
                        },
                        decoration: InputDecoration(
                            hintText: enabled
                                ? "Type your question here"
                                : "Connecting to chat history...",
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(22),
                                borderSide: const BorderSide(
                                    color: AppColorV2.boxStroke)),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(22),
                                borderSide: const BorderSide(
                                    color: AppColorV2.boxStroke)),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(22),
                                borderSide: const BorderSide(
                                    color: AppColorV2.lpBlueBrand))))),
                const SizedBox(width: 8),
                Material(
                    color: AppColorV2.lpBlueBrand,
                    shape: const CircleBorder(),
                    child: IconButton(
                        onPressed: enabled ? onSend : null,
                        color: Colors.white,
                        icon: const Icon(Icons.send_rounded))),
              ]),
            ])));
  }
}

const List<String> _quickReplies = [
  "Contact support",
];

const List<SupportChatQuestion> _starterQuestions = [
  SupportChatQuestion(
      id: "contact_support",
      title: "I need help with my account",
      keywords: [
        "help",
        "support",
        "account"
      ],
      answers: [
        "Chat content is temporarily unavailable. Please try again later or use Email Support for account review."
      ]),
];

const List<SupportChatTopic> _topics = [
  SupportChatTopic(
      id: "support",
      label: "Support",
      icon: Icons.support_agent_outlined,
      color: AppColorV2.lpBlueBrand,
      questions: _starterQuestions),
];
