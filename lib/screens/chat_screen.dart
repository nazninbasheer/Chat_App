import 'package:chat_webapp/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverEmail;
  final String receiverName;
  final String chatId;

  const ChatScreen({
    super.key,
    required this.receiverId,
    required this.receiverEmail,
    required this.chatId,
    required this.receiverName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser;

  late final String chatId;

  @override
  void initState() {
    super.initState();
    chatId = getChatId(currentUser!.uid, widget.receiverId);
  }

  // Send message
  void sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'senderId': currentUser!.uid,
      'receiverId': widget.receiverId,
      'timestamp': FieldValue.serverTimestamp(),
      'text': _messageController.text.trim(),
    });

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final messagesRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true);

    return Scaffold(
      appBar: AppBar(
        title:  Row(
      children: [
        // CircleAvatar with initial
        CircleAvatar(
          radius: 20,
          backgroundColor: Colors.deepPurple.shade200,
          child: Text(
            widget.receiverName.isNotEmpty
                ? widget.receiverName[0].toUpperCase()
                : '?',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Name text
        Text(
          widget.receiverName,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ],
    ),
      ),
     body: Stack(
  children: [
    // Conditional background
    LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 600; // breakpoint for mobile
        return Container(
          decoration: BoxDecoration(
            color: isMobile ? null : Colors.blueGrey.shade100, // web/desktop bg color
            image: isMobile
                ? DecorationImage(
                    image: AssetImage("assets/chatbg.jpg"),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.2),
                      BlendMode.darken,
                    ),
                  )
                : null,
          ),
        );
      },
    ),

    // Foreground chat content
    Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: messagesRef.snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final messages = snapshot.data!.docs;

              return ListView.builder(
                reverse: true,
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  final isMe = msg['senderId'] == currentUser!.uid;

                  return Align(
                    alignment:
                        isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isMe
                            ? Colors.deepPurple
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
      crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        // Message text
        Text(
          msg['text'],
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        // Message time
        Text(
          msg['timestamp'] != null
              ? DateFormat('hh:mm a').format(
                  (msg['timestamp'] as Timestamp).toDate(),
                )
              : '',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
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
        // Message input 
        Padding( padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6), 
        child: Material( elevation: 5, shadowColor: Colors.black, borderRadius: BorderRadius.circular(24), color: Colors.grey[200]?.withOpacity(0.9), child: Padding( padding: const EdgeInsets.symmetric( horizontal: 12, vertical: 4), child: Row( children: [ Expanded( child: TextField( controller: _messageController, decoration: const InputDecoration( hintText: 'Type a message...', border: InputBorder.none, ), style: const TextStyle(fontSize: 16), ), ), IconButton( icon: const Icon(Icons.send, color: Colors.deepPurple), onPressed: sendMessage, ), ], ), ), ), ),
      ],
    ),
  ],
),

    );
  }
}
