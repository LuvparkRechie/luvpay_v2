import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luvpay/auth/authentication.dart';
import 'package:luvpay/features/helpcenter/controller.dart';
import 'package:luvpay/shared/widgets/colors.dart';
import 'package:luvpay/shared/widgets/custom_scaffold.dart';
import 'package:luvpay/shared/widgets/luvpay_text.dart';

import 'chat_screen.dart';
import 'support_chat_service.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  static const SupportUserProfile _emptyProfile = SupportUserProfile(
      firstName: "", middleName: "", lastName: "", mobileNo: "", email: "");

  final SupportChatService _chatService = SupportChatService();

  SupportUserProfile _profile = _emptyProfile;
  List<SupportChatSession> _sessions = const [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    unawaited(_loadSessions());
  }

  Future<void> _loadSessions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final profile =
        SupportUserProfile.tryParse(await Authentication().getUserData2()) ??
            _emptyProfile;

    try {
      final sessions = await _chatService.listSessions(profile: profile);
      if (!mounted) return;

      setState(() {
        _profile = profile;
        _sessions = sessions;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _profile = profile;
        _sessions = const [];
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _openSession(SupportChatSession session) async {
    await Get.to(() => ChatScreen(
        ticketNumber: session.sessionNo, category: session.category));
    if (mounted) unawaited(_loadSessions());
  }

  Future<void> _openNewChat() async {
    await Get.to(() => const ChatScreen());
    if (mounted) unawaited(_loadSessions());
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffoldV2(
        appBarTitle: "Chat History",
        padding: EdgeInsets.zero,
        floatingButton: FloatingActionButton(
            onPressed: _openNewChat,
            backgroundColor: AppColorV2.lpBlueBrand,
            child: const Icon(Icons.add_comment_outlined, color: Colors.white)),
        scaffoldBody: _buildBody(context));
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return RefreshIndicator(
          onRefresh: _loadSessions,
          child: ListView(
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              padding: const EdgeInsets.all(20),
              children: [
                _HistoryState(
                    icon: Icons.cloud_off_outlined,
                    title: "Unable to load chat history",
                    message: _errorMessage!),
              ]));
    }

    if (_sessions.isEmpty) {
      return RefreshIndicator(
          onRefresh: _loadSessions,
          child: ListView(
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              padding: const EdgeInsets.all(20),
              children: [
                _HistoryState(
                    icon: Icons.forum_outlined,
                    title: "No chats yet",
                    message:
                        "Your resolved and open support conversations will appear here."),
              ]));
    }

    return RefreshIndicator(
        onRefresh: _loadSessions,
        child: ListView.separated(
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 96),
            itemCount: _sessions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final session = _sessions[index];
              return _ChatHistoryTile(
                  session: session,
                  ownerName: _profile.displayName,
                  onTap: () => _openSession(session));
            }));
  }
}

class _ChatHistoryTile extends StatelessWidget {
  final SupportChatSession session;
  final String ownerName;
  final VoidCallback onTap;

  const _ChatHistoryTile({
    required this.session,
    required this.ownerName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isResolved = session.isResolved;
    final statusColor =
        isResolved ? AppColorV2.darkMintAccent : AppColorV2.lpBlueBrand;
    final lastMessage = session.lastMessage.isEmpty
        ? "Tap to view the conversation"
        : session.lastMessage;

    return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColorV2.boxStroke)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle),
                    child: Icon(
                        isResolved
                            ? Icons.check_circle_outline_rounded
                            : Icons.chat_bubble_outline_rounded,
                        color: statusColor)),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      LuvpayText(
                          text: session.sessionNo,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                          maxLines: 1),
                      const SizedBox(height: 3),
                      LuvpayText(
                          text: session.category,
                          fontSize: 12,
                          color: AppColorV2.bodyTextColor,
                          maxLines: 1),
                    ])),
                _StatusPill(
                    label: isResolved ? "Resolved" : "Open",
                    color: statusColor),
              ]),
              const SizedBox(height: 12),
              LuvpayText(
                  text: lastMessage,
                  fontSize: 13,
                  color: AppColorV2.bodyTextColor,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 10),
              Row(children: [
                if (ownerName.trim().isNotEmpty) ...[
                  Expanded(
                      child: LuvpayText(
                          text: ownerName,
                          fontSize: 12,
                          color: AppColorV2.bodyTextColor,
                          maxLines: 1)),
                ] else
                  const Spacer(),
                LuvpayText(
                    text: _formatDate(session.updatedAt ?? session.createdAt),
                    fontSize: 12,
                    color: AppColorV2.bodyTextColor,
                    maxLines: 1),
              ]),
            ])));
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14)),
        child: LuvpayText(
            text: label,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
            maxLines: 1));
  }
}

class _HistoryState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _HistoryState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColorV2.boxStroke)),
        child: Column(children: [
          Icon(icon, size: 34, color: AppColorV2.lpBlueBrand),
          const SizedBox(height: 12),
          LuvpayText(
              text: title,
              style: AppTextStyle.h3(context),
              textAlign: TextAlign.center,
              maxLines: 2),
          const SizedBox(height: 6),
          LuvpayText(
              text: message,
              fontSize: 13,
              color: AppColorV2.bodyTextColor,
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.visible),
        ]));
  }
}

String _formatDate(DateTime? value) {
  if (value == null) return "";

  final date = value.toLocal();
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, "0");
  final suffix = date.hour >= 12 ? "PM" : "AM";
  final month = _monthNames[date.month - 1];

  return "$month ${date.day}, ${date.year} $hour:$minute $suffix";
}

const List<String> _monthNames = [
  "Jan",
  "Feb",
  "Mar",
  "Apr",
  "May",
  "Jun",
  "Jul",
  "Aug",
  "Sep",
  "Oct",
  "Nov",
  "Dec",
];
