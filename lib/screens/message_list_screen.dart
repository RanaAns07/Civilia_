// lib/screens/message_list_screen.dart (UPDATED for Firestore)
import 'package:flutter/material.dart';
import 'package:civilia/main.dart'; // For neonBlue
import 'package:civilia/widgets/bottom_navigation_bar.dart';
import 'package:civilia/screens/messages_screen.dart'; // To navigate to individual message screen

import 'package:cloud_firestore/cloud_firestore.dart'; // NEW: Import Cloud Firestore
import 'package:firebase_auth/firebase_auth.dart'; // NEW: Import Firebase Auth

class MessageListScreen extends StatefulWidget {
  const MessageListScreen({super.key});

  @override
  State<MessageListScreen> createState() => _MessageListScreenState();
}

class _MessageListScreenState extends State<MessageListScreen> {
  int _selectedIndex = 2; // Index for the "Messages" tab
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
        break; // Already on this screen
      case 3: // Profile
        Navigator.of(context).pushReplacementNamed('/profile');
        break;
      default:
        break;
    }
  }

  // Helper for showing snackbars
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
        backgroundColor: isError ? Colors.redAccent : neonBlue,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Function to create a new chat or open an existing one
  Future<void> _startNewChat() async {
    // For now, this will create a simple mock group chat or a direct chat.
    // In a real app, you'd have a UI to select users or enter a group name.
    // For demonstration, let's create a dummy chat.

    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      _showSnackBar('You must be logged in to start a chat.', isError: true);
      return;
    }

    // Example: Create a new conversation document in Firestore
    // For simplicity, let's create a fixed "Emergency Responders" group chat
    // You would typically query for existing chats or allow user to select participants
    try {
      final String currentUserId = currentUser.uid;
      final String currentUserName = currentUser.displayName ?? 'Anonymous User'; // Fallback for display name

      // Check if a conversation with "Emergency Responders" already exists
      final QuerySnapshot existingChats = await _firestore
          .collection('conversations')
          .where('participants', arrayContains: currentUserId)
          .get();

      String? existingConversationId;
      String? chatTitleToNavigate;

      for (var doc in existingChats.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['name'] == 'Emergency Responders Group') { // Check for specific group name
          existingConversationId = doc.id;
          chatTitleToNavigate = data['name'];
          break;
        }
      }

      if (existingConversationId != null) {
        _showSnackBar('Opening existing chat with Emergency Responders.');
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MessagesScreen(
              conversationId: existingConversationId!,
              chatTitle: chatTitleToNavigate!,
            ),
          ),
        );
      } else {
        // Create a new conversation
        final DocumentReference newConversationRef = await _firestore.collection('conversations').add({
          'name': 'Emergency Responders Group', // A fixed group name for now
          'participants': [currentUserId], // Add current user as participant
          'lastMessageText': 'No messages yet.',
          'lastMessageSenderId': '',
          'lastMessageTimestamp': Timestamp.now(),
          'createdAt': Timestamp.now(),
        });

        _showSnackBar('New chat created with Emergency Responders!');
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MessagesScreen(
              conversationId: newConversationRef.id,
              chatTitle: 'Emergency Responders Group',
            ),
          ),
        );
      }
    } catch (e) {
      _showSnackBar('Failed to start new chat: $e', isError: true);
      debugPrint('Error starting new chat: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    final User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Messages')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.message_outlined, size: 80, color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
              const SizedBox(height: 20),
              Text(
                'Please log in to view messages.',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed('/login');
                },
                child: const Text('Login Now'),
              ),
            ],
          ),
        ),
        bottomNavigationBar: CustomBottomNavigationBar(
          selectedIndex: _selectedIndex,
          onItemTapped: _onItemTapped,
        ),
      );
    }

    // Use StreamBuilder to listen for real-time updates from Firestore
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.of(context).pop(); // Go back to previous screen (e.g., Home)
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search functionality
              _showSnackBar('Search tapped! (Placeholder)');
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: Implement more options
              _showSnackBar('More options tapped! (Placeholder)');
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Query conversations where the current user is a participant
        stream: _firestore
            .collection('conversations')
            .where('participants', arrayContains: currentUser.uid)
            .orderBy('lastMessageTimestamp', descending: true) // Order by most recent activity
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: neonBlue));
          }
          if (snapshot.hasError) {
            debugPrint('Firestore Error: ${snapshot.error}');
            return Center(child: Text('Error loading messages: ${snapshot.error}', style: Theme.of(context).textTheme.bodyMedium));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.message_outlined, size: 80, color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
                  const SizedBox(height: 20),
                  Text(
                    'No conversations yet. Start a new chat!',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final conversations = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conversationData = conversations[index].data() as Map<String, dynamic>;
              final String conversationId = conversations[index].id;
              final String chatName = conversationData['name'] ?? 'Unknown Chat'; // Use 'name' field for chat title
              final String lastMessage = conversationData['lastMessageText'] ?? 'No messages yet.';
              final Timestamp? lastMessageTimestamp = conversationData['lastMessageTimestamp'] as Timestamp?;

              // Format timestamp for display
              String timeDisplay = 'N/A';
              if (lastMessageTimestamp != null) {
                final DateTime lastMsgDateTime = lastMessageTimestamp.toDate();
                if (DateTime.now().difference(lastMsgDateTime).inDays == 0) {
                  timeDisplay = '${lastMsgDateTime.hour % 12 == 0 ? 12 : lastMsgDateTime.hour % 12}:${lastMsgDateTime.minute.toString().padLeft(2, '0')} ${lastMsgDateTime.hour < 12 ? 'AM' : 'PM'}';
                } else if (DateTime.now().difference(lastMsgDateTime).inDays == 1) {
                  timeDisplay = 'Yesterday';
                } else {
                  timeDisplay = '${lastMsgDateTime.month}/${lastMsgDateTime.day}/${lastMsgDateTime.year.toString().substring(2, 4)}';
                }
              }

              // Placeholder for avatar. In a real app, you'd fetch based on participants.
              IconData avatarIcon = Icons.groups_outlined; // Default for group
              if (conversationData['participants'] != null && conversationData['participants'].length == 2) {
                avatarIcon = Icons.person_outline; // Assume 1-to-1 chat
              }


              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4.0),
                color: Theme.of(context).cardTheme.color,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: neonBlue.withOpacity(0.2),
                    child: Icon(avatarIcon, color: neonBlue),
                  ),
                  title: Text(
                    chatName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Text(
                    lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.8)),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        timeDisplay,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10, color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6)),
                      ),
                      // TODO: Implement unread count if needed (requires more complex Firestore queries/listeners)
                      // if (conversation['unreadCount'] > 0)
                      //   Container(
                      //     margin: const EdgeInsets.only(top: 4),
                      //     padding: const EdgeInsets.all(6),
                      //     decoration: BoxDecoration(
                      //       color: Colors.redAccent,
                      //       shape: BoxShape.circle,
                      //     ),
                      //     child: Text(
                      //       '${conversation['unreadCount']}',
                      //       style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white, fontSize: 12),
                      //     ),
                      //   ),
                    ],
                  ),
                  onTap: () {
                    // Navigate to the individual MessagesScreen, passing conversation ID and title
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => MessagesScreen(
                          conversationId: conversationId,
                          chatTitle: chatName,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _startNewChat, // Connect to function to start new chat
        backgroundColor: neonBlue,
        foregroundColor: Colors.black,
        child: const Icon(Icons.chat),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
