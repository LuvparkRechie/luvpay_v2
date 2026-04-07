// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:luvpay/shared/widgets/custom_scaffold.dart';
import 'package:luvpay/shared/widgets/luvpay_text.dart';
import 'package:luvpay/shared/widgets/tap_guard.dart';

import '../../../../shared/dialogs/dialogs.dart';

class ChatScreen extends StatefulWidget {
  final String? ticketNumber;
  final String? category;

  const ChatScreen({super.key, this.ticketNumber, this.category});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatMessagesController _controller = ChatMessagesController();

  final ChatUser _currentUser = ChatUser(id: 'user', firstName: 'You');
  final ChatUser _supportUser =
      ChatUser(id: 'support', firstName: 'LuvPay Support');

  bool _isLoading = false;
  bool isClosed = false;

  static const String sendKey = "chat_send";
  static const String attachKey = "chat_attach";

  @override
  void initState() {
    super.initState();

    _controller.addMessage(
      ChatMessage(
        text: "Welcome to LuvPay Support 👋\n\n"
            "Ticket: ${widget.ticketNumber ?? "LP-NEW"}\n"
            "Category: ${widget.category ?? "General"}\n\n"
            "Please describe your concern and our support team will assist you.",
        user: _supportUser,
        createdAt: DateTime.now(),
      ),
    );

    _controller.addMessage(
      ChatMessage(
        text:
            "⚠️ For your security, never share your OTP, password, or PIN. LuvPay will never ask for this information.",
        user: _supportUser,
        createdAt: DateTime.now(),
      ),
    );
  }

  void handleSendMessage(ChatMessage message) {
    TapGuard.run(
      key: sendKey,
      action: () async {
        _controller.addMessage(message);

        setState(() => _isLoading = true);

        await Future.delayed(const Duration(seconds: 1));

        _controller.addMessage(
          ChatMessage(
            text: "Support will reply shortly. Thank you!",
            user: _supportUser,
            createdAt: DateTime.now(),
          ),
        );

        setState(() => _isLoading = false);
      },
    );
  }

  Future<void> pickAttachment() async {
    TapGuard.run(
      key: attachKey,
      action: () async {
        showModalBottomSheet(
          context: context,
          builder: (_) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: const LuvpayText(text: "1. Take Photo"),
                    onTap: () async {
                      Navigator.pop(context);
                      final picker = ImagePicker();
                      final XFile? image =
                          await picker.pickImage(source: ImageSource.camera);
                      if (image != null) {
                        sendFileMessage(File(image.path));
                      }
                    },
                  ),
                  ListTile(
                    title: const LuvpayText(text: "2. Choose from Gallery"),
                    onTap: () async {
                      Navigator.pop(context);
                      final picker = ImagePicker();
                      final XFile? image =
                          await picker.pickImage(source: ImageSource.gallery);
                      if (image != null) {
                        sendFileMessage(File(image.path));
                      }
                    },
                  ),
                  ListTile(
                    title: const LuvpayText(text: "3. Choose File"),
                    onTap: () async {
                      Navigator.pop(context);
                      FilePickerResult? result = await FilePicker.pickFiles();
                      if (result != null) {
                        sendFileMessage(File(result.files.single.path!));
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void sendFileMessage(File file) {
    final fileName = file.path.split('/').last;

    _controller.addMessage(
      ChatMessage(
        text: "📎 $fileName",
        user: _currentUser,
        createdAt: DateTime.now(),
      ),
    );
  }

  Widget quickReply(String text) {
    return GestureDetector(
      onTap: () {
        handleSendMessage(
          ChatMessage(
            text: text,
            user: _currentUser,
            createdAt: DateTime.now(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(text),
      ),
    );
  }

  Color getStatusColor(String status) {
    switch (status) {
      case "Open":
        return Colors.blue;
      case "Pending":
        return Colors.orange;
      case "Resolved":
        return Colors.green;
      case "Closed":
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final status = isClosed ? "Closed" : "Open";

    return CustomScaffoldV2(
      appBarTitle: "Chat Support",
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(35),
        child: Column(
          children: [
            LuvpayText(
              text: "Ticket #${widget.ticketNumber ?? "LP-NEW"}",
              color: cs.onPrimary,
              fontWeight: FontWeight.bold,
            ),
            LuvpayText(
              text: "Status: $status",
              color: getStatusColor(status),
            ),
          ],
        ),
      ),
      scaffoldBody: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            color: Colors.blue.withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.support_agent, size: 16),
                SizedBox(width: 6),
                LuvpayText(
                  text: "Support typically replies within a few minutes.",
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                AiChatWidget(
                  currentUser: _currentUser,
                  aiUser: _supportUser,
                  controller: _controller,
                  onSendMessage: (message) {
                    if (isClosed) {
                      CustomDialogStack.showSnackBar(
                        context,
                        "This ticket is already closed.",
                        null,
                        null,
                      );
                      return;
                    }
                    handleSendMessage(message);
                  },
                  loadingConfig: LoadingConfig(isLoading: _isLoading),
                  inputOptions: const InputOptions(
                    autofocus: true,
                  ),
                ),
                Positioned(
                  bottom: 70,
                  right: 10,
                  child: FloatingActionButton(
                    mini: true,
                    onPressed: isClosed ? null : pickAttachment,
                    child: const Icon(Icons.attach_file),
                  ),
                ),
              ],
            ),
          ),
          if (!isClosed)
            Container(
              height: 40,
              margin: const EdgeInsets.only(bottom: 5, left: 10),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  quickReply("Follow up"),
                  quickReply("Thank you"),
                  quickReply("I will wait"),
                  quickReply("Issue resolved"),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
