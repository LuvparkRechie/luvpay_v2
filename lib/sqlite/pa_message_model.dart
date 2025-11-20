class PaMessageDataFields {
  static final List<String> values = [
    pushMsgId,
    message,
    createdDate,
    userId,
    status,
    runOn,
    isRead,
  ];

  static const String pushMsgId = 'push_msg_id';
  static const String userId = 'user_id';
  static const String message = 'message';
  static const String createdDate = 'created_on';
  static const String status = 'push_status';
  static const String runOn = 'run_on';
  static const String isRead = "is_read";
}
