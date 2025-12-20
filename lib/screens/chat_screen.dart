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
    ensureChatDocument();
    markMessagesAsRead();
    updateLastSeen();
  }

  void ensureChatDocument() async {
    final chatDoc = await FirebaseFirestore.instance.collection('chats').doc(chatId).get();
    if (!chatDoc.exists || !(chatDoc.data()?.containsKey('participants') ?? false)) {
      await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
        'participants': [currentUser!.uid, widget.receiverId],
      }, SetOptions(merge: true));
    }
  }

  void updateLastSeen() async {
    await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).set({
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  void markMessagesAsRead() async {
    final unreadMessages = await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('receiverId', isEqualTo: currentUser!.uid)
        .where('read', isEqualTo: false)
        .get();

    final unreadCount = unreadMessages.docs.length;

    for (var doc in unreadMessages.docs) {
      await doc.reference.update({'read': true});
    }

    // Decrement unread count in chat document
    if (unreadCount > 0) {
      final isUser1 = currentUser!.uid.compareTo(widget.receiverId) < 0;
      final unreadField = isUser1 ? 'unreadCountForUser1' : 'unreadCountForUser2';

      await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
        unreadField: FieldValue.increment(-unreadCount),
      }, SetOptions(merge: true));
    }
  }

  void sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final messageText = _messageController.text.trim();

    // Update chat document with participants, last message, and unread count
    final isUser1 = currentUser!.uid.compareTo(widget.receiverId) < 0;
    final unreadField = isUser1 ? 'unreadCountForUser2' : 'unreadCountForUser1';

    await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
      'participants': [currentUser!.uid, widget.receiverId],
      'lastMessage': messageText,
      'lastTimestamp': FieldValue.serverTimestamp(),
      unreadField: FieldValue.increment(1),
    }, SetOptions(merge: true));

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'senderId': currentUser!.uid,
      'receiverId': widget.receiverId,
      'timestamp': FieldValue.serverTimestamp(),
      'text': messageText,
      'read': false,
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
        elevation: 1,
        backgroundColor: Color.fromARGB(255, 255, 228, 247),
        foregroundColor: Colors.black,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.deepPurple.shade300,
              child: Text(
                widget.receiverName.isNotEmpty ? widget.receiverName[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.receiverName.isNotEmpty ? widget.receiverName : 'Unknown User',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection('users').doc(widget.receiverId).snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return const SizedBox.shrink();
                      }
                      final data = snapshot.data!.data() as Map<String, dynamic>?;
                      final lastSeen = data?['lastSeen'] as Timestamp?;
                      if (lastSeen == null) {
                        return const SizedBox.shrink();
                      }
                      final now = DateTime.now();
                      final lastSeenDate = lastSeen!.toDate();
                      final difference = now.difference(lastSeenDate);
                      if (difference.inMinutes < 1) {
                        return const Text(
                          'Online',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        );
                      } else {
                        return Text(
                          'Last seen ${difference.inMinutes} min ago',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      body: Stack(
    children: [
      //  Background image
      Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/image.png'),
            fit: BoxFit.cover,
          ),
        ),
      ),
      Column(
        children: [
          /// Messages
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg['senderId'] == currentUser!.uid;

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: IntrinsicWidth(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth:
                                MediaQuery.of(context).size.width * 0.75,
                          ),
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.fromLTRB(12, 8, 8, 6),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? Colors.deepPurple
                                  : Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: isMe
                                    ? const Radius.circular(16)
                                    : Radius.zero,
                                bottomRight: isMe
                                    ? Radius.zero
                                    : const Radius.circular(16),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                /// Message text (LEFT aligned always)
                                Text(
                                  msg['text'],
                                  textAlign: TextAlign.start,
                                  style: TextStyle(
                                    fontSize: 15.5,
                                    color: isMe
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),

                                const SizedBox(height: 4),

                                /// Time + tick (RIGHT aligned)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      msg['timestamp'] != null
                                          ? DateFormat('hh:mm a').format(
                                              (msg['timestamp'] as Timestamp)
                                                  .toDate(),
                                            )
                                          : '',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isMe
                                            ? Colors.white70
                                            : Colors.grey,
                                      ),
                                    ),
                                    if (isMe) ...[
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.check,
                                        size: 14,
                                        color: ((msg.data()
                                                        as Map<String,
                                                            dynamic>?)
                                                    ?.containsKey('read') ==
                                                true &&
                                            msg['read'] == true)
                                            ? Colors.yellow
                                            : Colors.white70,
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          /// Input bar
          SafeArea(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 255, 199, 239),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromARGB(31, 255, 224, 224),
                    blurRadius: 4,
                    offset: Offset(0, -1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      onSubmitted: (_) => sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        filled: true,
                        fillColor: const Color(0xFFF1F1F1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Colors.deepPurple,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ],
      ),
    );
  }
}
