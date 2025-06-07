import 'package:chat_webapp/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'chat_screen.dart';
import 'login_screen.dart'; // Replace with your actual login screen file

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
      appBar: AppBar(
              backgroundColor: const Color(0xFF1995AD),
              title: FutureBuilder<String?>(
                future: getUserName(),
                builder: (context, snapshot) {
                  final name = snapshot.data ?? 'User';
                  return Text(
                    "Hi✋ '$name' Chat With Anyone",
                    style: TextStyle(color: Colors.white),
                  );
                },
              ),

       actions: [
          IconButton(
            icon: Icon(Icons.logout),
            color: const Color(0xFFF1F1F2),hoverColor: const Color(0xFF003E77),           
            onPressed: () async {
              await FirebaseAuth.instance.signOut();

              // Navigate back to login screen
              Navigator.pushAndRemoveUntil(context,
                MaterialPageRoute(builder: (_) => LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
        ),
      body: Container(
        color: const Color(0xFFA1D6E2),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
        
            final users = snapshot.data!.docs.where((doc) => doc['uid'] != currentUser!.uid).toList();
        
            if (users.isEmpty) return Center(child: Text("No other users found."));
          
            return ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final userData = users[index].data() as Map<String, dynamic>;
                final name = userData['name'] ?? 'No Name';
                final email = userData['email'] ?? '';
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
                  ),
                  title: Text(name),
                  subtitle: Text(email),
                  onTap: () {
                    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
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
