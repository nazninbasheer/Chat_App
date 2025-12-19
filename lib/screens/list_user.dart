import 'package:chat_webapp/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'chat_screen.dart';
import 'login_screen.dart';  
class UserListScreen extends StatelessWidget {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  UserListScreen({super.key});

  Future<String> getUserName() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .get();
    return doc['name'] ?? 'User';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar with style
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.deepPurple,
        title: FutureBuilder<String?>(
          future: getUserName(),
          builder: (context, snapshot) {
            final name = snapshot.data ?? 'User';
            return Text(
              "Hi ✋ $name",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            color: Colors.white,
            tooltip: "Logout",
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),

      // Background gradient
      body: Container(
       decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6A11CB).withOpacity(0.7),
            const Color(0xFF2575FC).withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),

        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            }

            final users = snapshot.data!.docs
                .where((doc) => doc['uid'] != currentUser!.uid)
                .toList();

            if (users.isEmpty) {
              return const Center(
                child: Text(
                  "No other users found.",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final userData = users[index].data() as Map<String, dynamic>;
                final name = userData['name'] ?? 'No Name';
                final email = userData['email'] ?? '';
                final peerId = userData['uid'];
                final chatId = getChatId(currentUser!.uid, peerId);

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('chats')
                      .doc(chatId)
                      .collection('messages')
                      .where('receiverId', isEqualTo: currentUser!.uid)
                      .where('read', isEqualTo: false)
                      .snapshots(),
                  builder: (context, snapshot) {
                    int unreadCount = 0;
                    if (snapshot.hasData) {
                      unreadCount = snapshot.data!.docs.length;
                    }

                    return Card(
  elevation: 8,
  shadowColor: Colors.black26,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
  ),
  margin: const EdgeInsets.symmetric(vertical: 10),
  child: StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots(),
    builder: (context, messageSnapshot) {
      String lastMessage = 'No messages yet';
      String timeText = '';
      if (messageSnapshot.hasData && messageSnapshot.data!.docs.isNotEmpty) {
  final lastMsgDoc = messageSnapshot.data!.docs.first.data() as Map<String, dynamic>;
  lastMessage = lastMsgDoc['text'] ?? 'No messages yet';
  final timestamp = lastMsgDoc['timestamp'] as Timestamp?;
  if (timestamp != null) {
    final dt = timestamp.toDate();

    // Convert to 12-hour format with AM/PM
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    timeText = '$hour:$minute $period';
  }
}


      return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 26,
          backgroundColor: Colors.deepPurple.shade200,
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              timeText,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        subtitle: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                lastMessage,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (unreadCount > 0)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                constraints: const BoxConstraints(
                  minWidth: 24,
                  minHeight: 24,
                ),
                alignment: Alignment.center,
                child: Text(
                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        trailing: const Icon(
          Icons.navigate_next,
          color: Colors.deepPurple,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                receiverId: peerId,
                receiverEmail: email,
                chatId: chatId,
                receiverName: name,
              ),
            ),
          );
        },
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
