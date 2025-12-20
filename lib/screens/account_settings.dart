import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_picker_web/image_picker_web.dart' as webPicker;
import 'package:chat_webapp/services/cloudinary_service.dart';


class AccountSettings extends StatefulWidget {
  const AccountSettings({super.key});

  @override
  _AccountSettingsState createState() => _AccountSettingsState();
}

class _AccountSettingsState extends State<AccountSettings> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final TextEditingController _nameController = TextEditingController();
  String? _avatarUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (currentUser == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _nameController.text = data['name'] ?? '';
        _avatarUrl = data['avatarUrl'];
      });
    }
  }

  Future<void> _pickImage() async {
  try {
    if (kIsWeb) {
      final bytes = await webPicker.ImagePickerWeb.getImageAsBytes();
      if (bytes == null) return;

      setState(() => _isLoading = true);

      final imageUrl = await CloudinaryService.uploadImage(
        webImage: bytes,
      );

      await _saveAvatarUrl(imageUrl);
    } else {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      setState(() => _isLoading = true);

      final imageUrl = await CloudinaryService.uploadImage(
        filePath: picked.path,
      );

      await _saveAvatarUrl(imageUrl);
    }
  } catch (e) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Upload failed: $e")));
  } finally {
    setState(() => _isLoading = false);
  }
}

Future<void> _saveAvatarUrl(String imageUrl) async {
  await FirebaseFirestore.instance
      .collection('users')
      .doc(currentUser!.uid)
      .update({'avatarUrl': imageUrl});

  setState(() {
    _avatarUrl = imageUrl;
  });
}


  Future<void> _saveName() async {
    if (currentUser == null || _nameController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .update({'name': _nameController.text.trim()});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update name: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and will permanently remove all your data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white, 
            backgroundColor: Colors.blue),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white, 
            backgroundColor: Colors.red  ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || currentUser == null) return;

    setState(() => _isLoading = true);

    try {
      // Delete user document from Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .delete();

      // Delete user from Firebase Auth
      await currentUser!.delete();

      // Sign out (though delete should sign out automatically)
      await FirebaseAuth.instance.signOut();

      // Navigate to login screen
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete account: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

Widget desktopCard({
  required bool isDesktop,
  required Widget child,
}) {
  if (!isDesktop) return child;

  return Center(
    child: Container(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Card(
        elevation: 1,
         shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          
          
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: child,
        ),
      ),
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isDesktop = constraints.maxWidth > 600; // Threshold for desktop

          return SingleChildScrollView(
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
    child: desktopCard(
      isDesktop: isDesktop,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// AVATAR SECTION
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundImage:
                      _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                  backgroundColor: Colors.deepPurple.shade200,
                  child: _avatarUrl == null
                      ? Text(
                          _nameController.text.isNotEmpty
                              ? _nameController.text[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
                if (_isLoading)
                  const CircularProgressIndicator(color: Colors.white),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.deepPurple,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.camera_alt,
                          size: 18, color: Colors.white),
                      onPressed: _isLoading ? null : _pickImage,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          /// PERSONAL INFO
          const Text(
            "Personal Information",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 12),

          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveName,
              style: TextButton.styleFrom(
                 backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save Name'),
            ),
          ),

          const SizedBox(height: 32),
          const Divider(),

          /// ACCOUNT INFO
          const SizedBox(height: 20),
          const Text(
            "Account",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),

          _InfoRow(
            label: "Email",
            value: currentUser?.email ?? '',
            icon: Icons.email_outlined,
          ),

          const SizedBox(height: 32),

          /// DELETE ACCOUNT
          Center(
            child: TextButton.icon(
              onPressed: _isLoading ? null : _deleteAccount,
              icon: const Icon(Icons.delete_forever),
              label: const Text('Delete Account'),
              style: TextButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    ),
  ),
);
        },
      ),
    );
  }
  
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
