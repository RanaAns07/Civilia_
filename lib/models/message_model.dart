class Message {
  final String content;
  final DateTime timestamp;
  final bool isSent; // true if sent by this device
  final String? senderName;

  Message({
    required this.content,
    required this.isSent,
    this.senderName,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}