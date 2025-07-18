import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // For fetching chat data
import 'package:firebase_auth/firebase_auth.dart'; // For current user ID
import 'package:intl/intl.dart'; // For date formatting
import 'package:care_flow/screens/chat_screen.dart'; // Import the new ChatScreen
import 'dart:async'; // Import for StreamSubscription
import 'package:care_flow/screens/new_chart.dart'; // Corrected Import

// Define a simple ChatMessage model (re-used from ChatScreen for consistency)
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

  // Generates a consistent chatRoomId by sorting and concatenating user IDs
  String _generateChatRoomId(String user1Id, String user2Id) {
    List<String> ids = [user1Id, user2Id];
    ids.sort(); // Sorts alphabetically to ensure consistent order
    String generatedId = ids.join('_');
    debugPrint('ChatListPage: _generateChatRoomId: IDs: $user1Id, $user2Id -> Generated: $generatedId');
    return generatedId;
  }

  Future<void> _initializeUserAndListenToChats() async {
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser == null) {
      setState(() {
        _errorMessage = 'User not logged in. Cannot fetch messages.';
        _isLoading = false;
      });
      debugPrint('ChatListPage: No current user. Setting error message.');
      return;
    }

    debugPrint('ChatListPage: Current User UID: ${_currentUser!.uid}');

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get();

      if (userDoc.exists) {
        _currentUserName = userDoc.get('fullName') ?? 'Unknown User';
        _currentUserRole = userDoc.get('role');
        debugPrint('ChatListPage: User Name: $_currentUserName, Role: $_currentUserRole');
      } else {
        _currentUserName = 'Unknown User';
        _currentUserRole = 'Unknown Role';
        debugPrint('ChatListPage: User document not found for UID: ${_currentUser!.uid}');
      }
      _listenToChatThreads(); // Start listening to chat threads
    } catch (e) {
      debugPrint('ChatListPage: Error initializing user or setting up chat listeners: $e');
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
    debugPrint('ChatListPage: Starting to listen to chat threads for UID: ${_currentUser!.uid}');

    // Listen to messages sent by the current user
    _sentMessagesSubscription = FirebaseFirestore.instance
        .collection('messages')
        .where('senderId', isEqualTo: _currentUser!.uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      _latestSentSnapshot = snapshot;
      debugPrint('ChatListPage: Received new sent messages snapshot. Docs: ${snapshot.docs.length}');
      _processCombinedSnapshots(); // Process whenever sent messages update
    }, onError: (e) {
      debugPrint('ChatListPage: Stream error (sent messages): $e');
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
      debugPrint('ChatListPage: Received new received messages snapshot. Docs: ${snapshot.docs.length}');
      _processCombinedSnapshots(); // Process whenever received messages update
    }, onError: (e) {
      debugPrint('ChatListPage: Stream error (received messages): $e');
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
      debugPrint('ChatListPage: _processCombinedSnapshots: Waiting for both snapshots to load.');
      return;
    }
    debugPrint('ChatListPage: _processCombinedSnapshots: Processing combined snapshots.');

    try {
      Map<String, ChatMessage> latestMessagesByPartner = {};

      void processMessages(QuerySnapshot snapshot, bool isSender) {
        for (var doc in snapshot.docs) {
          ChatMessage message = ChatMessage.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
          String partnerId = isSender ? message.receiverId : message.senderId;

          debugPrint('ChatListPage: Processing message ID: ${message.id}, chatRoomId: ${message.chatRoomId}, Sender: ${message.senderId}, Receiver: ${message.receiverId}, Partner ID: $partnerId');

          if (!latestMessagesByPartner.containsKey(partnerId) ||
              message.timestamp.isAfter(latestMessagesByPartner[partnerId]!.timestamp)) {
            latestMessagesByPartner[partnerId] = message;
            debugPrint('ChatListPage: Updated latest message for partner $partnerId.');
          }
        }
      }

      processMessages(_latestSentSnapshot!, true);
      processMessages(_latestReceivedSnapshot!, false);

      List<Map<String, dynamic>> threads = latestMessagesByPartner.values.map((msg) {
        String partnerName = (msg.senderId == _currentUser!.uid) ? msg.receiverName : msg.senderName;
        String partnerId = (msg.senderId == _currentUser!.uid) ? msg.receiverId : msg.senderId;
        String chatRoomId = _generateChatRoomId(_currentUser!.uid, partnerId); // Generate chatRoomId here

        debugPrint('ChatListPage: Thread for Partner: $partnerName (ID: $partnerId), Generated chatRoomId: $chatRoomId');

        // Dummy unread logic (as before, for a real app this needs proper backend support)
        bool isUnread = (msg.receiverId == _currentUser!.uid) && (msg.timestamp.isAfter(DateTime.now().subtract(const Duration(minutes: 30))));

        return {
          'partnerName': partnerName,
          'lastMessage': msg.message,
          'timestamp': msg.timestamp,
          'partnerId': partnerId,
          'chatRoomId': chatRoomId, // Include chatRoomId in the thread map
          'isUnread': isUnread,
        };
      }).toList();

      threads.sort((a, b) => (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));

      if (mounted) {
        setState(() {
          _chatThreads = threads;
          _isLoading = false;
        });
        debugPrint('ChatListPage: Updated _chatThreads. Total threads: ${_chatThreads.length}');
      }
    } catch (e) {
      debugPrint('ChatListPage: Error processing combined snapshots: $e');
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
                debugPrint('ChatListPage: Tapped thread for partner: ${thread['partnerName']}, passing chatRoomId: ${thread['chatRoomId']}');
                // Navigate to actual chat screen, passing partner details AND chatRoomId
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      partnerId: thread['partnerId']!,
                      partnerName: thread['partnerName']!,
                      chatRoomId: thread['chatRoomId']!, // Pass the chatRoomId
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

          debugPrint('ChatListPage: Floating action button pressed. Current User UID: ${_currentUser!.uid}, Role: ${_currentUserRole!}');

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
              // Generate chatRoomId for the new chat
              final newChatRoomId = _generateChatRoomId(_currentUser!.uid, selectedPartner['id']!);
              debugPrint('ChatListPage: Selected partner: ${selectedPartner['name']} (ID: ${selectedPartner['id']}), Generated newChatRoomId: $newChatRoomId');

              Navigator.push(
                currentContext, // Use captured context
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    partnerId: selectedPartner['id']!,
                    partnerName: selectedPartner['name']!,
                    chatRoomId: newChatRoomId, // Pass the newly generated chatRoomId
                  ),
                ),
              );
            }
          } else {
            debugPrint('ChatListPage: No partner selected or selection cancelled.');
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
