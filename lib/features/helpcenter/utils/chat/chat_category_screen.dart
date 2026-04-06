import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../shared/widgets/luvpay_text.dart';
import 'chat_screen.dart';

class ChatCategoryScreen extends StatelessWidget {
  const ChatCategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = [
      "Account Concern",
      "Wallet / Balance",
      "Cash In",
      "Cash Out",
      "QR Payment",
      "Refund",
      "Parking",
      "App Error",
      "Verification",
      "Others",
    ];

    return Scaffold(
      appBar: AppBar(title: const LuvpayText(text: "Chat with us")),
      body: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: LuvpayText(text: categories[index]),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Get.to(() => ChatScreen(category: categories[index]));
            },
          );
        },
      ),
    );
  }
}
