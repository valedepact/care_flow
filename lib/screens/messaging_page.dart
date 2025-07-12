import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // For fetching chat data
import 'package:firebase_auth/firebase_auth.dart'; // For current user ID
import 'package:intl/intl.dart'; // For date formatting
import 'package:care_flow/screens/chat_screen.dart'; // Import the new ChatScreen
import 'dart:async'; // Import for StreamSubscription
import 'package:care_flow/screens/new_chart.dart'; // Import the SelectChatPartnerScreen

// Define a simple ChatMessage model (re-used from ChatScreen for consistency)
class ChatMessage {
  final String id; // Document ID
  final String senderId;
  final String senderName;
  final String receiverId; // The ID of the other participant
  final String receiverName; // The name of the other participant
  final String message;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
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
      'senderId': senderId,
      'senderName': senderName,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp), // Convert DateTime to Timestamp
    };
  }
}

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  User? _currentUser;
  String? _currentUserName;
  String? _currentUserRole;
  bool _isLoading = true;
  String _errorMessage = '';

  List<Map<String, dynamic>> _chatThreads = [];

  // Stream subscriptions for real-time updates
  StreamSubscription? _sentMessagesSubscription;
  StreamSubscription? _receivedMessagesSubscription;

  // Store the latest snapshots from each stream
  QuerySnapshot? _latestSentSnapshot;
  QuerySnapshot? _latestReceivedSnapshot;

  @override
  void initState() {
    super.initState();
    _initializeUserAndListenToChats();
  }

  @override
  void dispose() {
    // Cancel stream subscriptions to prevent memory leaks
    _sentMessagesSubscription?.cancel();
    _receivedMessagesSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeUserAndListenToChats() async {
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser == null) {
      setState(() {
        _errorMessage = 'User not logged in. Cannot fetch messages.';
        _isLoading = false;
      });
      return;
    }

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get();

      if (userDoc.exists) {
        _currentUserName = userDoc.get('fullName') ?? 'Unknown User';
        _currentUserRole = userDoc.get('role');
      } else {
        _currentUserName = 'Unknown User';
        _currentUserRole = 'Unknown Role';
      }
      _listenToChatThreads(); // Start listening to chat threads
    } catch (e) {
      debugPrint('Error initializing user or setting up chat listeners: $e');
      setState(() {
        _errorMessage = 'Failed to load user data or chat threads: $e';
        _isLoading = false;
      });
    }
  }

  // Use streams to listen for real-time updates to chat threads
  void _listenToChatThreads() {
    if (_currentUser == null) return;

    // Cancel previous subscriptions if they exist
    _sentMessagesSubscription?.cancel();
    _receivedMessagesSubscription?.cancel();

    // Initial load state
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    // Listen to messages sent by the current user
    _sentMessagesSubscription = FirebaseFirestore.instance
        .collection('messages')
        .where('senderId', isEqualTo: _currentUser!.uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      _latestSentSnapshot = snapshot;
      _processCombinedSnapshots(); // Process whenever sent messages update
    }, onError: (e) {
      debugPrint('Stream error (sent messages): $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading sent messages: $e';
          _isLoading = false;
        });
      }
    });

    // Listen to messages received by the current user
    _receivedMessagesSubscription = FirebaseFirestore.instance
        .collection('messages')
        .where('receiverId', isEqualTo: _currentUser!.uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      _latestReceivedSnapshot = snapshot;
      _processCombinedSnapshots(); // Process whenever received messages update
    }, onError: (e) {
      debugPrint('Stream error (received messages): $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading received messages: $e';
          _isLoading = false;
        });
      }
    });
  }

  // Helper to process combined snapshots and update chat threads
  // Now takes no arguments, uses stored latest snapshots
  void _processCombinedSnapshots() {
    // Only proceed if both snapshots have been initialized at least once
    if (_latestSentSnapshot == null || _latestReceivedSnapshot == null) {
      return;
    }

    try {
      Map<String, ChatMessage> latestMessagesByPartner = {};

      void processMessages(QuerySnapshot snapshot, bool isSender) {
        for (var doc in snapshot.docs) {
          ChatMessage message = ChatMessage.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
          String partnerId = isSender ? message.receiverId : message.senderId;

          if (!latestMessagesByPartner.containsKey(partnerId) ||
              message.timestamp.isAfter(latestMessagesByPartner[partnerId]!.timestamp)) {
            latestMessagesByPartner[partnerId] = message;
          }
        }
      }

      processMessages(_latestSentSnapshot!, true);
      processMessages(_latestReceivedSnapshot!, false);

      List<Map<String, dynamic>> threads = latestMessagesByPartner.values.map((msg) {
        String partnerName = (msg.senderId == _currentUser!.uid) ? msg.receiverName : msg.senderName;
        String partnerId = (msg.senderId == _currentUser!.uid) ? msg.receiverId : msg.senderId;

        // Dummy unread logic (as before, for a real app this needs proper backend support)
        bool isUnread = (msg.receiverId == _currentUser!.uid) && (msg.timestamp.isAfter(DateTime.now().subtract(const Duration(minutes: 30))));

        return {
          'partnerName': partnerName,
          'lastMessage': msg.message,
          'timestamp': msg.timestamp,
          'partnerId': partnerId,
          'isUnread': isUnread,
        };
      }).toList();

      threads.sort((a, b) => (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));

      if (mounted) {
        setState(() {
          _chatThreads = threads;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error processing combined snapshots: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Error processing chat updates: $e';
          _isLoading = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Messages (${_currentUserName ?? "Loading..."} - ${_currentUserRole ?? "Role Unknown"})'),
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red, fontSize: 16),
          ),
        ),
      )
          : _chatThreads.isEmpty
          ? const Center(
        child: Text('No active conversations. Start a new chat!'),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _chatThreads.length,
        itemBuilder: (context, index) {
          final thread = _chatThreads[index];
          final bool isUnread = thread['isUnread'] ?? false;
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: () {
                // Navigate to actual chat screen, passing partner details
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      partnerId: thread['partnerId']!,
                      partnerName: thread['partnerName']!,
                    ),
                  ),
                );
                debugPrint('Opening chat with ${thread['partnerName']} (ID: ${thread['partnerId']})');
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.indigo.shade100,
                      child: Icon(
                        Icons.person,
                        color: Colors.indigo.shade700,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            thread['partnerName']!,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                              color: Colors.indigo.shade800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            thread['lastMessage']!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isUnread ? Colors.black : Colors.grey[600],
                              fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          DateFormat('h:mm a').format(thread['timestamp']),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isUnread ? Colors.indigo.shade800 : Colors.grey[500],
                            fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        if (isUnread)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'NEW',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // Capture context before any async operations that might dispose the widget
          final currentContext = context;

          if (_currentUser == null || _currentUserRole == null) {
            if (currentContext.mounted) { // Use captured context and check mounted
              ScaffoldMessenger.of(currentContext).showSnackBar(
                const SnackBar(content: Text('Please log in to start a new chat.')),
              );
            }
            return;
          }

          final selectedPartner = await Navigator.push(
            currentContext, // Use captured context
            MaterialPageRoute(
              builder: (context) => SelectChatPartnerScreen(
                currentUserId: _currentUser!.uid,
                currentUserRole: _currentUserRole!,
              ),
            ),
          );

          // If a partner was selected, navigate to the ChatScreen
          if (selectedPartner != null && selectedPartner is Map<String, dynamic>) {
            if (currentContext.mounted) { // Use captured context and check mounted
              Navigator.push(
                currentContext, // Use captured context
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    partnerId: selectedPartner['id']!,
                    partnerName: selectedPartner['name']!,
                  ),
                ),
              );
            }
          }
          debugPrint('Start New Chat pressed by ${_currentUserName ?? "Unknown User"}');
        },
        label: const Text('New Chat'),
        icon: const Icon(Icons.add_comment),
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
      ),
    );
  }
}
