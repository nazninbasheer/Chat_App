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

                return Card(
                  elevation: 8,
                  shadowColor: Colors.black26,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                    title: Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 19,
                      ),
                    ),
                    trailing: const Icon(Icons.navigate_next,
                        color: Colors.deepPurple),
                    onTap: () {
                      final currentUserId =
                          FirebaseAuth.instance.currentUser!.uid;
                      final peerId = users[index]['uid'];
                      final peerEmail = users[index]['email'];
                      final peerName = users[index]['name'];

                      final chatId = getChatId(currentUserId, peerId);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            receiverId: peerId,
                            receiverEmail: peerEmail,
                            chatId: chatId,
                            receiverName: peerName,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
