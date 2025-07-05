import 'package:flutter/material.dart';
import 'package:civilia/main.dart'; // For neonBlue

class MessageBubble extends StatelessWidget {
  final String sender;
  final String text;
  final String time;
  final bool isMe;

  const MessageBubble({
    super.key,
    required this.sender,
    required this.text,
    required this.time,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Display sender's name only if not 'You'
          if (!isMe)
            Text(
              sender,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7)),
            ),
          if (!isMe) const SizedBox(height: 4),
          Material(
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(12),
              topRight: const Radius.circular(12),
              bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
              bottomRight: isMe ? Radius.zero : const Radius.circular(12),
            ),
            color: isMe ? neonBlue : (Theme.of(context).brightness == Brightness.dark ? Colors.grey[700] : Colors.grey[300]), // Neon blue for sender, theme-based for receiver
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isMe ? Colors.black : Theme.of(context).textTheme.bodyMedium?.color, // Black text on neon blue, theme-based for receiver
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6), fontSize: 10),
          ),
        ],
      ),
    );
  }
}
