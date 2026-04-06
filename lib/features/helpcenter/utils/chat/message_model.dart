class MessageModel {
  final String message;
  final String sender;
  final String? attachment;
  final DateTime createdAt;
  final bool seen;

  MessageModel({
    required this.message,
    required this.sender,
    this.attachment,
    required this.createdAt,
    this.seen = false,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      message: json['message'],
      sender: json['sender'],
      attachment: json['attachment'],
      createdAt: DateTime.parse(json['created_at']),
      seen: json['seen'] == 1,
    );
  }
}
