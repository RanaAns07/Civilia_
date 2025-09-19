import '../models/message_model.dart';

class MessageService {
  final List<Message> _messages = [];

  List<Message> get messages => _messages;

  void addMessage(Message message) {
    _messages.add(message);
  }

  void clearMessages() {
    _messages.clear();
  }
}