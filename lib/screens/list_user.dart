import 'package:chat_webapp/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'chat_screen.dart';
import 'login_screen.dart';
import 'account_settings.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  _UserListScreenState createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> with TickerProviderStateMixin {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSettingsTab = false;
  Map<String, Map<String, dynamic>> _usersMap = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _isSettingsTab = _tabController.index == 2;
      });
    });
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
    _loadUsers();
  }

  void _loadUsers() async {
    final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
    setState(() {
      _usersMap = {for (var doc in usersSnapshot.docs) doc.id: doc.data()};
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<String> getUserName() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .get();
    return doc['name'] ?? 'User';
  }

  Future<List<Map<String, dynamic>>> getSortedUsers(bool showOnlyUnread, String searchQuery) async {
    final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
    final List<Map<String, dynamic>> sortedUsers = [];

    for (var userDoc in usersSnapshot.docs) {
      final userData = userDoc.data();
      final uid = userData['uid'];
      if (uid == currentUser!.uid) continue;
      final name = userData['name'] ?? '';
      if (!name.toLowerCase().contains(searchQuery)) continue;

      final chatId = getChatId(currentUser!.uid, uid);

      // Get unread count
      final unreadSnapshot = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('receiverId', isEqualTo: currentUser!.uid)
          .where('read', isEqualTo: false)
          .get();
      final unreadCount = unreadSnapshot.docs.length;

      if (showOnlyUnread && unreadCount == 0) continue;

      // Get last message timestamp
      final lastMsgSnapshot = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      Timestamp? lastTimestamp;
      if (lastMsgSnapshot.docs.isNotEmpty) {
        lastTimestamp = lastMsgSnapshot.docs.first['timestamp'] as Timestamp?;
      }

      sortedUsers.add({
        'userData': userData,
        'lastTimestamp': lastTimestamp,
        'unreadCount': unreadCount,
      });
    }

    // Sort by lastTimestamp descending, nulls last
    sortedUsers.sort((a, b) {
      final aTime = a['lastTimestamp'] as Timestamp?;
      final bTime = b['lastTimestamp'] as Timestamp?;
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return bTime.compareTo(aTime);
    });

    return sortedUsers;
  }

  Widget _buildUserList(bool showOnlyUnread) {
    if (_usersMap.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/listuserbg.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: false,
            floating: false,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: Padding(
              padding: const EdgeInsets.all(6.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .where('participants', arrayContains: currentUser!.uid)
                  .snapshots(),
              builder: (context, chatSnapshot) {
                if (chatSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                }

                final chatMap = <String, Map<String, dynamic>>{};
                if (chatSnapshot.hasData) {
                  for (var doc in chatSnapshot.data!.docs) {
                    chatMap[doc.id] = doc.data() as Map<String, dynamic>;
                  }
                }

                final List<Map<String, dynamic>> sortedUsers = [];

                for (var entry in _usersMap.entries) {
                  final userData = entry.value;
                  final uid = userData['uid'];
                  if (uid == currentUser!.uid) continue;
                  final name = userData['name'] ?? '';
                  if (!name.toLowerCase().contains(_searchQuery)) continue;

                  final chatId = getChatId(currentUser!.uid, uid);
                  final chatData = chatMap[chatId];

                  final lastTimestamp = chatData?['lastTimestamp'] as Timestamp?;
                  final lastMessage = chatData?['lastMessage'] as String? ?? 'No messages yet';

                  final isUser1 = currentUser!.uid.compareTo(uid) < 0;
                  final unreadField = isUser1 ? 'unreadCountForUser1' : 'unreadCountForUser2';
                  final unreadCount = chatData?[unreadField] as int? ?? 0;

                  if (showOnlyUnread && unreadCount == 0) continue;

                  sortedUsers.add({
                    'userData': userData,
                    'lastTimestamp': lastTimestamp,
                    'lastMessage': lastMessage,
                    'unreadCount': unreadCount,
                  });
                }

                // Sort by lastTimestamp descending, nulls last
                sortedUsers.sort((a, b) {
                  final aTime = a['lastTimestamp'] as Timestamp?;
                  final bTime = b['lastTimestamp'] as Timestamp?;
                  if (aTime == null && bTime == null) return 0;
                  if (aTime == null) return 1;
                  if (bTime == null) return -1;
                  return bTime.compareTo(aTime);
                });

                if (sortedUsers.isEmpty) {
                  return Center(
                    child: Text(
                      showOnlyUnread ? "No users with unread messages." : "No other users found.",
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: sortedUsers.length,
                  itemBuilder: (context, index) {
                    final userMap = sortedUsers[index];
                    final userData = userMap['userData'] as Map<String, dynamic>;
                    final lastTimestamp = userMap['lastTimestamp'] as Timestamp?;
                    final lastMessage = userMap['lastMessage'] as String;
                    final unreadCount = userMap['unreadCount'] as int;

                    final name = userData['name'] ?? 'No Name';
                    final email = userData['email'] ?? '';
                    final peerId = userData['uid'];
                    final chatId = getChatId(currentUser!.uid, peerId);

                    String timeText = '';
                    if (lastTimestamp != null) {
                      final dt = lastTimestamp.toDate();
                      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
                      final minute = dt.minute.toString().padLeft(2, '0');
                      final period = dt.hour >= 12 ? 'PM' : 'AM';
                      timeText = '$hour:$minute $period';
                    }

                    return Card(
                      elevation: 12,
                      shadowColor: Colors.black26,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          radius: 26,
                          backgroundImage: userData['avatarUrl'] != null ? NetworkImage(userData['avatarUrl']) : null,
                          backgroundColor: Colors.deepPurple.shade200,
                          child: userData['avatarUrl'] == null ? Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ) : null,
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
                                  color: Colors.deepPurple,
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
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _isSettingsTab ? Colors.deepPurple : const Color.fromARGB(255, 198, 193, 248),
        title: _isSettingsTab ? const Text(
          'Account Settings',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ) : StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser!.uid)
              .snapshots(),
          builder: (context, snapshot) {
            final name = snapshot.data?.data() != null
                ? (snapshot.data!.data() as Map<String, dynamic>)['name'] ?? 'User'
                : 'User';
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
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUserList(false),
          _buildUserList(true),
          const AccountSettings(),
        ],
      ),
      bottomNavigationBar: Container(
        height: 53,
        child: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: ImageIcon(AssetImage('assets/chat1.png')),
              text: 'Chats',
            ),
            Tab(
              icon: ImageIcon(AssetImage('assets/chat2.png')),
              text: 'Unread',
            ),
            Tab(
              icon: Icon(Icons.settings),
              text: 'Account',
            ),
          ],
        ),
      ),
    );
  }
}
