import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // For date formatting

// Re-using the ChatMessage model from messaging_page.dart for consistency
class ChatMessage {
  final String id; // Document ID
  final String chatRoomId; // New: ID for the chat conversation
  final String senderId;
  final String senderName;
  final String receiverId; // The ID of the other participant
  final String receiverName; // The name of the other participant
  final String message;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.chatRoomId, // New: Required in constructor
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.receiverName,
    required this.message,
    required this.timestamp,
  });

  factory ChatMessage.fromFirestore(Map<String, dynamic> data, String id) {
    return ChatMessage(
      id: id,
      chatRoomId: data['chatRoomId'] ?? '', // New: Parse chatRoomId
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? 'Unknown Sender',
      receiverId: data['receiverId'] ?? '',
      receiverName: data['receiverName'] ?? 'Unknown Receiver',
      message: data['message'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'chatRoomId': chatRoomId, // New: Include chatRoomId
      'senderId': senderId,
      'senderName': senderName,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp), // Convert DateTime to Timestamp
    };
  }
}

class ChatScreen extends StatefulWidget {
  final String partnerId;
  final String partnerName;
  final String chatRoomId; // NEW: Add chatRoomId to the constructor

  const ChatScreen({
    super.key,
    required this.partnerId,
    required this.partnerName,
    required this.chatRoomId, // NEW: Make it required
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  User? _currentUser;
  String? _currentUserName; // Full name of the current user
  // Removed _chatRoomId from state as it's now passed via widget

  @override
  void initState() {
    super.initState();
    _initializeCurrentUser(); // Initialize current user and their full name
  }

  // Initialize current user and their full name
  Future<void> _initializeCurrentUser() async {
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser != null) {
      debugPrint('Chat Room ID from widget: ${widget.chatRoomId}'); // Debug print

      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser!.uid)
            .get();
        if (userDoc.exists) {
          setState(() {
            _currentUserName = userDoc.get('fullName') ?? 'You';
          });
        }
      } catch (e) {
        debugPrint('Error fetching current user name: $e');
        setState(() {
          _currentUserName = 'You'; // Fallback
        });
      }
    } else {
      debugPrint('No current user found in ChatScreen.');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: User not logged in.')),
        );
        Navigator.pop(context); // Go back if no user
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _currentUser == null || _currentUserName == null) {
      return; // Don't send empty messages or if user is not logged in
    }

    final String messageText = _messageController.text.trim();
    _messageController.clear(); // Clear input field immediately

    try {
      final ChatMessage newMessage = ChatMessage(
        id: '', // Firestore will generate this
        chatRoomId: widget.chatRoomId, // Use the chat room ID from the widget
        senderId: _currentUser!.uid,
        senderName: _currentUserName!,
        receiverId: widget.partnerId,
        receiverName: widget.partnerName,
        message: messageText,
        timestamp: DateTime.now(),
      );

      await FirebaseFirestore.instance.collection('messages').add(newMessage.toFirestore());
      debugPrint('Message sent: "$messageText" in chat room ${widget.chatRoomId}');

      // Scroll to the bottom after sending a message
      // Add a small delay to allow message to render before scrolling
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      debugPrint('Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ensure _currentUser is initialized before building StreamBuilder
    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.partnerName),
          backgroundColor: Colors.indigo.shade700,
          foregroundColor: Colors.white,
          elevation: 4,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.partnerName), // Display the name of the chat partner
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('messages')
                  .where('chatRoomId', isEqualTo: widget.chatRoomId) // Query by chatRoomId from widget
                  .orderBy('timestamp', descending: false) // Order by timestamp ascending
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  debugPrint('Error fetching messages: ${snapshot.error}');
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Say hello! No messages yet.'));
                }

                final messages = snapshot.data!.docs.map((doc) {
                  return ChatMessage.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
                }).toList();

                // Scroll to the bottom when new messages arrive
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12.0),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final bool isMe = message.senderId == _currentUser?.uid;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.indigo.shade100 : Colors.grey.shade200,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(12),
                            topRight: const Radius.circular(12),
                            bottomLeft: isMe ? const Radius.circular(12) : const Radius.circular(0),
                            bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(12),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Text(
                              isMe ? 'You' : message.senderName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isMe ? Colors.indigo.shade800 : Colors.grey.shade700,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              message.message,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('MMM d, h:mm a').format(message.timestamp),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade200,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                    ),
                    onSubmitted: (_) => _sendMessage(), // Send on Enter key
                  ),
                ),
                const SizedBox(width: 8.0),
                FloatingActionButton(
                  onPressed: _sendMessage,
                  mini: true,
                  backgroundColor: Colors.indigo.shade700,
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
