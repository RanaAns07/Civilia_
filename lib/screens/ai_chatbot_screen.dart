import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:civilia/main.dart'; // For neonBlue

class AiChatbotScreen extends StatefulWidget {
  const AiChatbotScreen({super.key});

  @override
  State<AiChatbotScreen> createState() => _AiChatbotScreenState();
}

class _AiChatbotScreenState extends State<AiChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  final String _apiKey = "AIzaSyD8aVV85uSoFq7TilD2lQcxHKtVhi99574";
  final String _apiUrl =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=";

  @override
  void initState() {
    super.initState();
    _addMessage(
      ChatMessage(
        text: "Hello! I'm your Civilia AI Assistant. How can I help you today?",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _addMessage(ChatMessage message) {
    setState(() {
      _messages.insert(0, message);
    });
  }

  Future<void> _sendMessage() async {
    final String text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    _addMessage(ChatMessage(text: text, isUser: true, timestamp: DateTime.now()));

    setState(() {
      _isTyping = true;
    });

    final String fullApiUrl = _apiUrl + _apiKey;

    try {
      List<Map<String, dynamic>> chatHistory = [];
      final int historyLength = _messages.length > 10 ? 10 : _messages.length;
      for (int i = historyLength - 1; i >= 0; i--) {
        final msg = _messages[i];
        chatHistory.add({
          "role": msg.isUser ? "user" : "model",
          "parts": [{"text": msg.text}]
        });
      }

      final payload = {
        "contents": chatHistory,
      };

      final response = await http.post(
        Uri.parse(fullApiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        String aiResponseText = "I'm sorry, I couldn't generate a response.";
        if (responseData['candidates'] != null &&
            responseData['candidates'].isNotEmpty &&
            responseData['candidates'][0]['content'] != null &&
            responseData['candidates'][0]['content']['parts'] != null &&
            responseData['candidates'][0]['content']['parts'].isNotEmpty) {
          aiResponseText = responseData['candidates'][0]['content']['parts'][0]['text'];
        } else if (responseData['promptFeedback'] != null &&
            responseData['promptFeedback']['blockReason'] != null) {
          aiResponseText = "My response was blocked due to: ${responseData['promptFeedback']['blockReason']}. Please try rephrasing.";
        }

        _addMessage(ChatMessage(text: aiResponseText, isUser: false, timestamp: DateTime.now()));
      } else {
        String errorText;
        switch (response.statusCode) {
          case 400:
            errorText = "Error: Bad request to AI. Check your prompt or API key.";
            break;
          case 403:
            errorText = "Error: API key forbidden. Please ensure your API key is valid and has access.";
            break;
          case 429:
            errorText = "Error: Too many requests. Please wait a moment and try again.";
            break;
          case 500:
            errorText = "Error: Internal server error from AI. Please try again later.";
            break;
          default:
            errorText = "Error: Could not connect to AI. Status ${response.statusCode}.";
        }
        _addMessage(ChatMessage(text: errorText, isUser: false, timestamp: DateTime.now()));
      }
    } catch (e) {
      _addMessage(ChatMessage(text: "An unexpected error occurred. Please try again.", isUser: false, timestamp: DateTime.now()));
    } finally {
      setState(() {
        _isTyping = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Assistant'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: [
              Theme.of(context).scaffoldBackgroundColor.withOpacity(0.9),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                reverse: true,
                padding: const EdgeInsets.all(16.0),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return _buildMessageBubble(_messages[index], context);
                },
              ),
            ),
            if (_isTyping)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    Icon(Icons.smart_toy_outlined, color: neonBlue, size: 20),
                    const SizedBox(width: 8),
                    const Text('AI is typing...', style: TextStyle(color: Colors.white54)),
                    const SizedBox(width: 4),
                    const SizedBox(
                      width: 10,
                      height: 10,
                      child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white54),
                    )
                  ],
                ),
              ),
            _buildMessageInput(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, BuildContext context) {
    final bool isMe = message.isUser;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: isMe ? neonBlue : Theme.of(context).cardColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: isMe ? const Radius.circular(18) : const Radius.circular(6),
              bottomRight: isMe ? const Radius.circular(6) : const Radius.circular(18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 0.5,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                message.text,
                style: TextStyle(
                  color: isMe ? Colors.black : Theme.of(context).textTheme.bodyMedium?.color,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${message.timestamp.hour % 12 == 0 ? 12 : message.timestamp.hour % 12}:${message.timestamp.minute.toString().padLeft(2, '0')} ${message.timestamp.hour < 12 ? 'AM' : 'PM'}',
                style: TextStyle(
                  color: isMe ? Colors.black54 : Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(30.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    spreadRadius: 0.5,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Ask the AI...',
                  hintStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [neonBlue.withOpacity(0.9), neonBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: neonBlue.withOpacity(0.4),
                    blurRadius: 10,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.send, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({required this.text, required this.isUser, required this.timestamp});
}
