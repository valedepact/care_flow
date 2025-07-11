messaging_page
import 'dart:io' show File;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'firebase_options.dart';

import 'package:care_flow/screens/visit_schedule_page.dart';
import 'package:flutter/material.dart';
import 'package:care_flow/screens/home_page.dart'; main

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class DefaultFirebaseOptions {
  // ignore: prefer_typing_uninitialized_variables
  static var currentPlatform;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(

      title: 'Chats',

      title: 'Care Flow',
      initialRoute: '/',
      routes: {
        '/visitSchedule': (context)=> VisitSchedulePage(),
      },

      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      home: const ChatListPage(),
    );
  }
}


class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

  Future<String?> _getUserName(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.data()?['name'] as String?;
  }

  Future<String?> _getUserRole(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.data()?['role'] as String?;
  }

  Future<List<String>> _getAllowedChatUserIds(String currentUserId, String role) async {
    if (role == 'patient') {
      final doc = await FirebaseFirestore.instance.collection('assignments').doc(currentUserId).get();
      final nurseId = doc.data()?['nurseId'];
      return nurseId != null ? [nurseId] : [];
    } else if (role == 'nurse') {
      final query = await FirebaseFirestore.instance
          .collection('assignments')
          .where('nurseId', isEqualTo: currentUserId)
          .get();
      return query.docs.map((doc) => doc.id).toList();
    }
    return [];
  }

  Future<String> _getLastMessage(String chatId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('messages')
        .doc(chatId)
        .collection('chats')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) {
      final msg = snapshot.docs.first;
      if (msg.data().containsKey('imageUrl')) {
        return '[Image]';
      }
      return msg['text'] ?? '';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return FutureBuilder<String?>(
      future: _getUserRole(currentUserId),
      builder: (context, roleSnapshot) {
        if (!roleSnapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final userRole = roleSnapshot.data ?? '';
        return FutureBuilder<List<String>>(
          future: _getAllowedChatUserIds(currentUserId, userRole),
          builder: (context, allowedSnapshot) {
            if (!allowedSnapshot.hasData) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            final allowedUserIds = allowedSnapshot.data!;
            return Scaffold(
              appBar: AppBar(
                title: const Text('Chats 💬'),
                flexibleSpace: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.purple.shade300],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
              body: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade50, Colors.purple.shade50],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('messages')
                      .where('participants', arrayContains: currentUserId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final chats = snapshot.data!.docs.where((chat) {
                      final participants = List<String>.from(chat['participants']);
                      return participants.any((id) => allowedUserIds.contains(id));
                    }).toList();

                    if (chats.isEmpty) {
                      return const Center(child: Text('You have no conversations yet.'));
                    }

                    return ListView.builder(
                      itemCount: chats.length,
                      itemBuilder: (context, index) {
                        final chat = chats[index];
                        final participants = List<String>.from(chat['participants']);
                        final otherUserId = participants.firstWhere((id) => id != currentUserId);
                        return FutureBuilder<String?>(
                          future: _getUserName(otherUserId),
                          builder: (context, userSnapshot) {
                            final userName = userSnapshot.data ?? otherUserId;
                            return FutureBuilder<String>(
                              future: _getLastMessage(chat.id),
                              builder: (context, msgSnapshot) {
                                final preview = msgSnapshot.data ?? '';
                                return Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.blueAccent.shade100,
                                      child: Text(userName[0]),
                                    ),
                                    title: Text('Chat with $userName'),
                                    subtitle: Text(preview, maxLines: 1, overflow: TextOverflow.ellipsis),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ChatScreen(
                                            chatId: chat.id,
                                            recipientUid: otherUserId,
                                            recipientName: userName,
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
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String recipientUid;
  final String recipientName;

  const ChatScreen({super.key, required this.chatId, required this.recipientUid, required this.recipientName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final picker = ImagePicker();

  void _sendMessage({String? text, String? imageUrl}) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || (text?.isEmpty ?? true) && imageUrl == null) return;

    final chatDoc = FirebaseFirestore.instance.collection('messages').doc(widget.chatId);
    if (!(await chatDoc.get()).exists) {
      await chatDoc.set({
        'participants': [currentUser.uid, widget.recipientUid],
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    final messageData = {
      'senderId': currentUser.uid,
      'timestamp': FieldValue.serverTimestamp(),
    };
    if (text != null) messageData['text'] = text;
    if (imageUrl != null) messageData['imageUrl'] = imageUrl;

    await chatDoc.collection('chats').add(messageData);
    _messageController.clear();
    _scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final ref = FirebaseStorage.instance.ref().child('chat_images').child(DateTime.now().toIso8601String());
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        await ref.putData(bytes);
      } else {
        await ref.putFile(File(pickedFile.path));
      }
      final url = await ref.getDownloadURL();
      _sendMessage(imageUrl: url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserUid = FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with ${widget.recipientName}'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade400, Colors.purple.shade300],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
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
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('messages')
                    .doc(widget.chatId)
                    .collection('chats')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final messages = snapshot.data!.docs;
                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMe = msg['senderId'] == currentUserUid;
                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            // ignore: deprecated_member_use
                            color: isMe ? Colors.blueAccent.withOpacity(0.9) : Colors.grey[300]!.withOpacity(0.9),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(20),
                              topRight: const Radius.circular(20),
                              bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(0),
                              bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(20),
                            ),
                          ),
                          child: msg['imageUrl'] != null
                              ? Image.network(msg['imageUrl'], width: 200)
                              : Text(
                                  msg['text'] ?? '',
                                  style: TextStyle(
                                    color: isMe ? Colors.white : Colors.black,
                                    fontSize: 16,
                                  ),
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
                  IconButton(
                    icon: const Icon(Icons.image, color: Colors.blue),
                    onPressed: _pickImage,
                  ),
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


