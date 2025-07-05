// lib/screens/messages_screen.dart (UPDATED for Firestore)
import 'package:flutter/material.dart';
import 'package:civilia/main.dart'; // For neonBlue
import 'package:civilia/widgets/bottom_navigation_bar.dart';
import 'package:civilia/widgets/message_bubble.dart'; // Import the MessageBubble widget

import 'package:cloud_firestore/cloud_firestore.dart'; // NEW: Import Cloud Firestore
import 'package:firebase_auth/firebase_auth.dart'; // NEW: Import Firebase Auth

class MessagesScreen extends StatefulWidget {
  final String chatTitle; // Title for the chat (e.g., "Dr. Elena Petrova")
  final String conversationId; // NEW: ID of the Firestore conversation

  const MessagesScreen({super.key, required this.chatTitle, required this.conversationId});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  int _selectedIndex = 2; // Index for the "Messages" tab in bottom nav
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser; // To store the current authenticated user

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser; // Get current user on init
    if (_currentUser == null) {
      // Handle case where user is not logged in (e.g., redirect to login)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You must be logged in to view messages.', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
            backgroundColor: Colors.redAccent,
          ),
        );
        Navigator.of(context).pushReplacementNamed('/login');
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Navigate based on the selected index
    switch (index) {
      case 0: // Map
        Navigator.of(context).pushReplacementNamed('/home');
        break;
      case 1: // First Aid
        Navigator.of(context).pushReplacementNamed('/firstAidCategories');
        break;
      case 2: // Messages
        Navigator.of(context).pushReplacementNamed('/messageList'); // Go back to message list
        break;
      case 3: // Profile
        Navigator.of(context).pushReplacementNamed('/profile');
        break;
      default:
        break;
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) {
      return; // Don't send empty messages
    }

    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You must be logged in to send messages.', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final String messageText = _messageController.text.trim();
    _messageController.clear(); // Clear input field immediately

    try {
      final String currentUserId = _currentUser!.uid;
      final String currentUserName = _currentUser!.displayName ?? 'Anonymous User'; // Get display name from Firebase Auth

      // Add message to the 'messages' subcollection of the current conversation
      await _firestore
          .collection('conversations')
          .doc(widget.conversationId)
          .collection('messages')
          .add({
        'senderId': currentUserId,
        'senderName': currentUserName,
        'text': messageText,
        'timestamp': FieldValue.serverTimestamp(), // Use server timestamp for consistency
      });

      // Update the 'lastMessage' fields in the parent conversation document
      await _firestore
          .collection('conversations')
          .doc(widget.conversationId)
          .update({
        'lastMessageText': messageText,
        'lastMessageSenderId': currentUserId,
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
      });

    } catch (e) {
      debugPrint('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: $e', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: neonBlue)), // Show loading while redirecting
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chatTitle), // Use the passed chatTitle
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.of(context).pop(); // Go back to MessageListScreen
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline), // Or a call/video icon
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Contact info/call options tapped! (Placeholder)', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
                  backgroundColor: neonBlue,
                  duration: const Duration(milliseconds: 500),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // Listen to messages in the specific conversation, ordered by timestamp
              stream: _firestore
                  .collection('conversations')
                  .doc(widget.conversationId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true) // Display newest messages at the bottom
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: neonBlue));
                }
                if (snapshot.hasError) {
                  debugPrint('Firestore Message Error: ${snapshot.error}');
                  return Center(child: Text('Error loading messages: ${snapshot.error}', style: Theme.of(context).textTheme.bodyMedium));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'Say hello! Your messages will appear here.',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  reverse: true, // Display messages from bottom to top (newest at bottom)
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final messageData = messages[index].data() as Map<String, dynamic>;
                    final String senderId = messageData['senderId'];
                    final String senderName = messageData['senderName'] ?? 'Unknown User';
                    final String text = messageData['text'];
                    final Timestamp? timestamp = messageData['timestamp'] as Timestamp?;

                    // Determine if the message was sent by the current user
                    final bool isMe = senderId == _currentUser!.uid;

                    // Format timestamp for display
                    String timeDisplay = 'N/A';
                    if (timestamp != null) {
                      final DateTime messageDateTime = timestamp.toDate();
                      timeDisplay = '${messageDateTime.hour % 12 == 0 ? 12 : messageDateTime.hour % 12}:${messageDateTime.minute.toString().padLeft(2, '0')} ${messageDateTime.hour < 12 ? 'AM' : 'PM'}';
                    }

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: MessageBubble(
                        sender: senderName,
                        text: text,
                        time: timeDisplay,
                        isMe: isMe,
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Message input bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).cardColor, // Use theme's card color
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: neonBlue,
                  radius: 24,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.black),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
