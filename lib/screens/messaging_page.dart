import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:intl/intl.dart'; // For date formatting

// Helper widget for AppBar gradient
class _AppBarGradient extends StatelessWidget {
  const _AppBarGradient({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.purple.shade300],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}

// ChatListPage: Displays a list of ongoing conversations
class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _currentUser;
  String? _currentUserName;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserDetails();
  }

  Future<void> _fetchCurrentUserDetails() async {
    _currentUser = _auth.currentUser;
    if (_currentUser == null) {
      setState(() {
        _errorMessage = 'User not logged in.';
        _isLoading = false;
      });
      return;
    }

    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(_currentUser!.uid).get();
      if (userDoc.exists) {
        setState(() {
          _currentUserName = userDoc.get('fullName') ?? 'You';
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'User profile not found.';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching current user details: $e');
      setState(() {
        _errorMessage = 'Failed to load user details: $e';
        _isLoading = false;
      });
    }
  }

  // Helper to get the name of the other participant in a chat
  Future<String> _getOtherParticipantName(List<dynamic> participants) async {
    if (_currentUser == null) return 'Unknown User';

    String otherParticipantId = participants.firstWhere(
          (id) => id != _currentUser!.uid,
      orElse: () => _currentUser!.uid, // Fallback to current user if only one participant (shouldn't happen)
    );

    if (otherParticipantId == _currentUser!.uid) {
      return _currentUserName ?? 'You';
    }

    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(otherParticipantId).get();
      if (userDoc.exists) {
        return userDoc.get('fullName') ?? 'Unknown User';
      } else {
        // Check patients collection if not found in users (for patient-nurse chats)
        DocumentSnapshot patientDoc = await _firestore.collection('patients').doc(otherParticipantId).get();
        if (patientDoc.exists) {
          return patientDoc.get('name') ?? 'Unknown Patient';
        }
      }
    } catch (e) {
      print('Error fetching other participant name: $e');
    }
    return 'Unknown User';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        appBar: AppBar(
          title: Text('Chats 💬'),
          flexibleSpace: _AppBarGradient(),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Chats 💬'),
          flexibleSpace: const _AppBarGradient(),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
          ),
        ),
      );
    }

    if (_currentUser == null) {
      return const Scaffold(
        appBar: AppBar(
          title: Text('Chats 💬'),
          flexibleSpace: _AppBarGradient(),
        ),
        body: Center(child: Text('Please log in to view your chats.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats 💬'),
        flexibleSpace: const _AppBarGradient(),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue, Colors.purple],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          // Query chats where the current user is a participant
          stream: _firestore
              .collection('chats')
              .where('participants', arrayContains: _currentUser!.uid)
              .orderBy('lastMessageTimestamp', descending: true) // Order by most recent message
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('You have no conversations yet. Start a new chat!'));
            }

            final chatDocs = snapshot.data!.docs;

            return ListView.builder(
              itemCount: chatDocs.length,
              itemBuilder: (context, index) {
                final chat = chatDocs[index].data() as Map<String, dynamic>;
                final participants = List<String>.from(chat['participants']);
                final lastMessage = chat['lastMessage'] ?? '';
                final lastMessageTimestamp = (chat['lastMessageTimestamp'] as Timestamp?)?.toDate();

                return FutureBuilder<String>(
                  future: _getOtherParticipantName(participants),
                  builder: (context, nameSnapshot) {
                    if (nameSnapshot.connectionState == ConnectionState.waiting) {
                      return const ListTile(title: Text('Loading chat...'));
                    }
                    if (nameSnapshot.hasError) {
                      return ListTile(title: Text('Error loading chat: ${nameSnapshot.error}'));
                    }
                    final otherUserName = nameSnapshot.data ?? 'Unknown User';
                    final otherUserId = participants.firstWhere((id) => id != _currentUser!.uid, orElse: () => '');

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blueAccent.shade100,
                          child: Text(otherUserName.isNotEmpty ? otherUserName[0].toUpperCase() : '?'),
                        ),
                        title: Text('Chat with $otherUserName'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
                            if (lastMessageTimestamp != null)
                              Text(
                                DateFormat('MMM d, hh:mm a').format(lastMessageTimestamp),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                chatId: chatDocs[index].id, // Pass the Firestore document ID as chatId
                                recipientUid: otherUserId,
                                recipientName: otherUserName,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// ChatScreen: Displays the actual conversation with a specific user
class ChatScreen extends StatefulWidget {
  final String chatId;
  final String recipientUid;
  final String recipientName;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.recipientUid,
    required this.recipientName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _currentUser;
  String? _currentUserName;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserDetails();
  }

  Future<void> _fetchCurrentUserDetails() async {
    _currentUser = _auth.currentUser;
    if (_currentUser == null) {
      setState(() {
        _errorMessage = 'User not logged in.';
        _isLoading = false;
      });
      return;
    }
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(_currentUser!.uid).get();
      if (userDoc.exists) {
        setState(() {
          _currentUserName = userDoc.get('fullName') ?? 'You';
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'User profile not found.';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching current user details for chat screen: $e');
      setState(() {
        _errorMessage = 'Failed to load user details: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage({String? text}) async {
    if (text == null || text.trim().isEmpty || _currentUser == null) return;

    String messageText = text.trim();
    String senderId = _currentUser!.uid;

    try {
      // Add message to the 'messages' subcollection of the specific chat
      await _firestore.collection('chats').doc(widget.chatId).collection('messages').add({
        'senderId': senderId,
        'text': messageText,
        'timestamp': FieldValue.serverTimestamp(), // Use server timestamp
      });

      // Update the lastMessage and lastMessageTimestamp in the parent chat document
      await _firestore.collection('chats').doc(widget.chatId).update({
        'lastMessage': messageText,
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
      });

      _messageController.clear(); // Clear input field
      // Scroll to the bottom (most recent message)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0.0, // Scroll to the top (because ListView is reversed)
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      print('Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Chat with ${widget.recipientName}'),
          flexibleSpace: const _AppBarGradient(),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Chat with ${widget.recipientName}'),
          flexibleSpace: const _AppBarGradient(),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with ${widget.recipientName}'),
        flexibleSpace: const _AppBarGradient(),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.purple.shade50],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('chats')
                    .doc(widget.chatId)
                    .collection('messages')
                    .orderBy('timestamp', descending: true) // Order by newest first for reversed list
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No messages yet. Start the conversation!'));
                  }

                  final messages = snapshot.data!.docs;

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true, // Show most recent messages at the bottom
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index].data() as Map<String, dynamic>;
                      final isMe = msg['senderId'] == _currentUser!.uid;
                      final timestamp = (msg['timestamp'] as Timestamp?)?.toDate();

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.blueAccent.withOpacity(0.9) : Colors.grey[300]!.withOpacity(0.9),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(20),
                              topRight: const Radius.circular(20),
                              bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(0),
                              bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(20),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              Text(
                                msg['text'] ?? '',
                                style: TextStyle(
                                  color: isMe ? Colors.white : Colors.black,
                                  fontSize: 16,
                                ),
                              ),
                              if (timestamp != null)
                                Text(
                                  DateFormat('hh:mm a').format(timestamp),
                                  style: TextStyle(
                                    color: isMe ? Colors.white70 : Colors.black54,
                                    fontSize: 10,
                                  ),
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
                        hintText: 'Type a message... ✍️',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[200],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(text: _messageController.text.trim()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: () => _sendMessage(text: _messageController.text.trim()),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
