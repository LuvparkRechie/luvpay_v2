import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../shared/widgets/luvpay_text.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tickets = [
      {"ticket": "LP-0001", "status": "Open", "category": "Payment Issue"},
      {"ticket": "LP-0002", "status": "Resolved", "category": "Refund"},
    ];

    return Scaffold(
      appBar: AppBar(title: const LuvpayText(text: "My Support Tickets")),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.toNamed("/chatCategory");
        },
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        itemCount: tickets.length,
        itemBuilder: (context, index) {
          final item = tickets[index];

          return ListTile(
            title: LuvpayText(text: "Ticket #${item["ticket"]}"),
            subtitle: LuvpayText(text: item["category"].toString()),
            trailing: LuvpayText(
              text: item["status"].toString(),
              style: TextStyle(
                color: item["status"] == "Open" ? Colors.blue : Colors.green,
              ),
            ),
            onTap: () {
              Get.to(() => ChatScreen(
                    ticketNumber: item["ticket"].toString(),
                    category: item["category"].toString(),
                  ));
            },
          );
        },
      ),
    );
  }
}
