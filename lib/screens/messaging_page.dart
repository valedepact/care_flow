import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // For fetching chat data
import 'package:firebase_auth/firebase_auth.dart'; // For current user ID
import 'package:intl/intl.dart'; // For date formatting
// Removed: import 'package:flutter/foundation.dart'; // debugPrint is already provided by material.dart

// Define a simple ChatMessage model
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
      'timestamp': timestamp,
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
  String? _currentUserRole; // This variable is now used
  bool _isLoading = true;
  String _errorMessage = '';

  // This list will hold the "chat threads" or "conversations"
  // Each map will represent a unique chat partner and the last message exchanged.
  List<Map<String, dynamic>> _chatThreads = [];

  @override
  void initState() {
    super.initState();
    _initializeUserAndFetchChats();
  }

  Future<void> _initializeUserAndFetchChats() async {
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
        _currentUserRole = userDoc.get('role'); // Get the role
      } else {
        _currentUserName = 'Unknown User';
        _currentUserRole = 'Unknown Role';
      }
      await _fetchChatThreads();
    } catch (e) {
      debugPrint('Error initializing user or fetching chat threads: $e');
      setState(() {
        _errorMessage = 'Failed to load user data or chat threads: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchChatThreads() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Fetch messages where the current user is either the sender or the receiver.
      // This is a simplified way to get conversations. A more robust solution
      // would involve a dedicated 'conversations' collection with 'participants' arrays.
      QuerySnapshot sentMessagesSnapshot = await FirebaseFirestore.instance
          .collection('messages')
          .where('senderId', isEqualTo: _currentUser!.uid)
          .orderBy('timestamp', descending: true)
          .get();

      QuerySnapshot receivedMessagesSnapshot = await FirebaseFirestore.instance
          .collection('messages')
          .where('receiverId', isEqualTo: _currentUser!.uid)
          .orderBy('timestamp', descending: true)
          .get();

      // Combine and process messages to identify unique chat partners and their last message
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

      processMessages(sentMessagesSnapshot, true);
      processMessages(receivedMessagesSnapshot, false);

      List<Map<String, dynamic>> threads = latestMessagesByPartner.values.map((msg) {
        // Determine partner name based on who the current user is
        String partnerName = (msg.senderId == _currentUser!.uid) ? msg.receiverName : msg.senderName;
        String partnerId = (msg.senderId == _currentUser!.uid) ? msg.receiverId : msg.senderId;

        // For simplicity, we'll assume a message is 'unread' if it's the latest
        // and was sent by the partner (i.e., received by current user)
        // and its timestamp is more recent than a hypothetical 'lastRead' timestamp.
        // A real unread count would require more complex logic (e.g., per-user read receipts).
        bool isUnread = (msg.receiverId == _currentUser!.uid) && (msg.timestamp.isAfter(DateTime.now().subtract(const Duration(minutes: 30)))); // Dummy unread logic

        return {
          'partnerName': partnerName,
          'lastMessage': msg.message,
          'timestamp': msg.timestamp,
          'partnerId': partnerId,
          'isUnread': isUnread,
        };
      }).toList();

      // Sort threads by latest message timestamp
      threads.sort((a, b) => (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));

      if (mounted) {
        setState(() {
          _chatThreads = threads;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching chat threads: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading chat list: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Display current user's name and role in the AppBar
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
                // TODO: Navigate to actual chat screen, passing partner details
                debugPrint('Opening chat with ${thread['partnerName']} (ID: ${thread['partnerId']})');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Opening chat with ${thread['partnerName']} (Chat screen coming soon!)')),
                );
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
        onPressed: () {
          // TODO: Implement logic to start a new chat (e.g., select a contact from users/patients list)
          debugPrint('Start New Chat pressed by ${_currentUserName ?? "Unknown User"}');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Start New Chat functionality coming soon!')),
          );
        },
        label: const Text('New Chat'),
        icon: const Icon(Icons.add_comment),
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
      ),
    );
  }
}
