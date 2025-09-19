import 'dart:convert';

class Message {
  final String id;
  final String senderId;
  final String content;

  Message({required this.id, required this.senderId, required this.content});

  Map<String, dynamic> toMap() => {
    'id': id,
    'senderId': senderId,
    'content': content,
  };

  static Message fromJson(String jsonString) {
    final map = json.decode(jsonString);
    return Message(
      id: map['id'],
      senderId: map['senderId'],
      content: map['content'],
    );
  }

  String toJson() => json.encode(toMap());
}
