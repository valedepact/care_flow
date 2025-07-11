import 'package:flutter/material.dart';

// --- Dummy Data and Logic (No Firebase for now) ---
// In a real application, this data would come from a backend.

// Simulate current user
const String _currentUserId = 'current_user_id_123';
const String _currentUserRole = 'patient'; // Can be 'patient', 'nurse', 'doctor'

// Simulate user names for display
Map<String, String> _dummyUserNames = {
  'current_user_id_123': 'You',
  'nurse_id_456': 'Nurse Jane',
  'patient_id_789': 'Patient John',
  'doctor_id_012': 'Dr. Emily',
};

// Simulate chat relationships based on roles
List<Map<String, dynamic>> _dummyChatData = [
  {
    'chatId': 'chat_1_nurse_patient',
    'participants': ['current_user_id_123', 'nurse_id_456'],
    'lastMessage': 'Hello, how are you feeling today?',
    'lastMessageIsImage': false,
  },
  {
    'chatId': 'chat_2_patient_doctor',
    'participants': ['current_user_id_123', 'doctor_id_012'],
    'lastMessage': 'Remember your appointment tomorrow.',
    'lastMessageIsImage': false,
  },
  // Add more dummy chats as needed
];

// Simulate messages within a chat
Map<String, List<Map<String, dynamic>>> _dummyMessages = {
  'chat_1_nurse_patient': [
    {'senderId': 'nurse_id_456', 'text': 'Hello, how are you feeling today?', 'timestamp': DateTime.now().subtract(Duration(minutes: 5))},
    {'senderId': 'current_user_id_123', 'text': 'I am feeling much better, thank you!', 'timestamp': DateTime.now().subtract(Duration(minutes: 3))},
    {'senderId': 'nurse_id_456', 'text': 'That\'s great to hear!', 'timestamp': DateTime.now().subtract(Duration(minutes: 1))},
  ],
  'chat_2_patient_doctor': [
    {'senderId': 'doctor_id_012', 'text': 'Remember your appointment tomorrow at 10 AM.', 'timestamp': DateTime.now().subtract(Duration(hours: 2))},
    {'senderId': 'current_user_id_123', 'text': 'Got it, thanks for the reminder!', 'timestamp': DateTime.now().subtract(Duration(hours: 1))},
  ],
};

// --- End Dummy Data ---

// Helper widget for AppBar gradient - moved outside of any specific class
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
class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

  // Dummy function to get user name
  String _getDummyUserName(String uid) {
    return _dummyUserNames[uid] ?? 'Unknown User';
  }

  // Dummy function to get user role
  String _getDummyUserRole(String uid) {
    // In a real app, this would be fetched from auth or user profile
    return _currentUserRole; // For simplicity, assume current user's role
  }

  // Dummy function to determine allowed chat user IDs based on role
  List<String> _getDummyAllowedChatUserIds(String currentUserId, String role) {
    List<String> allowed = [];
    if (role == 'patient') {
      // Patient can chat with their nurse and doctor (dummy IDs)
      allowed.add('nurse_id_456');
      allowed.add('doctor_id_012');
    } else if (role == 'nurse') {
      // Nurse can chat with patients (dummy IDs)
      allowed.add('patient_id_789');
    }
    // Add logic for 'doctor' role if needed
    return allowed;
  }

  // Dummy function to get the last message for preview
  String _getDummyLastMessage(String chatId) {
    final messages = _dummyMessages[chatId];
    if (messages != null && messages.isNotEmpty) {
      final lastMsg = messages.last; // Assuming last message is the most recent
      if (lastMsg.containsKey('imageUrl')) {
        return '[Image]';
      }
      return lastMsg['text'] ?? '';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    // Simulate current user being logged in
    final currentUserId = _currentUserId;
    final userRole = _getDummyUserRole(currentUserId);
    final allowedUserIds = _getDummyAllowedChatUserIds(currentUserId, userRole);

    // Filter dummy chats to only show those with allowed participants
    final filteredChats = _dummyChatData.where((chat) {
      final participants = List<String>.from(chat['participants']);
      return participants.contains(currentUserId) &&
          participants.any((id) => id != currentUserId && allowedUserIds.contains(id));
    }).toList();

    if (filteredChats.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Chats 💬'),
          flexibleSpace: _AppBarGradient(), // Use the new widget
        ),
        body: Center(child: Text('You have no conversations yet. Start a new chat!')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats 💬'),
        flexibleSpace: const _AppBarGradient(), // Use the new widget
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue, Colors.purple],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView.builder(
          itemCount: filteredChats.length,
          itemBuilder: (context, index) {
            final chat = filteredChats[index];
            final participants = List<String>.from(chat['participants']);
            final otherUserId = participants.firstWhere((id) => id != currentUserId);
            final userName = _getDummyUserName(otherUserId);
            final preview = _getDummyLastMessage(chat['chatId']);

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blueAccent.shade100,
                  child: Text(userName.isNotEmpty ? userName[0].toUpperCase() : '?'),
                ),
                title: Text('Chat with $userName'),
                subtitle: Text(preview, maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () {
                  // Navigate to the specific chat screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        chatId: chat['chatId'],
                        recipientUid: otherUserId,
                        recipientName: userName,
                      ),
                    ),
                  );
                },
              ),
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

  // Local list to simulate messages for the current chat
  List<Map<String, dynamic>> _currentChatMessages = [];

  @override
  void initState() {
    super.initState();
    // Initialize messages for the current chat from dummy data
    _currentChatMessages = List.from(_dummyMessages[widget.chatId] ?? []);
    // Sort messages by timestamp (oldest first for display, then reverse for ListView.builder)
    _currentChatMessages.sort((a, b) => (a['timestamp'] as DateTime).compareTo(b['timestamp'] as DateTime));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Simulates sending a message (text only for now)
  void _sendMessage({String? text}) {
    if (text == null || text.trim().isEmpty) return;

    final currentUserUid = _currentUserId; // Use dummy current user ID

    final messageData = {
      'senderId': currentUserUid,
      'text': text.trim(),
      'timestamp': DateTime.now(), // Use current time for timestamp
    };

    setState(() {
      _currentChatMessages.add(messageData); // Add new message to local list
    });

    _messageController.clear(); // Clear input field
    // Scroll to the bottom (most recent message)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        0.0, // Scroll to the top (because ListView is reversed)
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserUid = _currentUserId; // Use dummy current user ID

    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with ${widget.recipientName}'),
        flexibleSpace: const _AppBarGradient(), // Use the new widget
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.purple.shade50],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                reverse: true, // Show most recent messages at the bottom
                itemCount: _currentChatMessages.length,
                itemBuilder: (context, index) {
                  // Access messages in reverse order to show newest at bottom
                  final msg = _currentChatMessages[_currentChatMessages.length - 1 - index];
                  final isMe = msg['senderId'] == currentUserUid; // Check if message is from current user
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
                      child: Text(
                        msg['text'] ?? '', // Display text
                        style: TextStyle(
                          color: isMe ? Colors.white : Colors.black,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  // Image picking button removed as Firebase Storage is not used
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
                      onSubmitted: (_) => _sendMessage(text: _messageController.text.trim()), // Send on enter
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: () => _sendMessage(text: _messageController.text.trim()), // Send on button tap
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
