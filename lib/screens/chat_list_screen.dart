import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:instadamiolandafinal/screens/chat_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final uidActual = FirebaseAuth.instance.currentUser!.uid;
  Map<String, String> cachedAvatars = {};

  @override
  void initState() {
    super.initState();
    _carregarAvatars();
  }

  Future<void> _carregarAvatars() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();

    final Map<String, String> avatars = {};
    for (var key in keys) {
      if (key.startsWith('avatar_')) {
        final uid = key.replaceFirst('avatar_', '');
        avatars[uid] = prefs.getString(key) ?? '';
      }
    }

    setState(() {
      cachedAvatars = avatars;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Xats'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          const Divider(height: 1, thickness: 1),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('usuaris').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No hi ha altres usuaris.'));
                }

                final usuaris = snapshot.data!.docs
                    .where((doc) => doc.data().toString().contains('uid') && doc['uid'] != uidActual)
                    .toList();

                if (usuaris.isEmpty) {
                  return const Center(child: Text('No hi ha altres usuaris amb qui xatejar.'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemCount: usuaris.length,
                  itemBuilder: (context, index) {
                    final usuari = usuaris[index];
                    final String uid = usuari['uid'];
                    final String avatarPath = cachedAvatars[uid] ?? '';

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      leading: CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: avatarPath.isNotEmpty ? FileImage(File(avatarPath)) : null,
                        child: avatarPath.isEmpty
                            ? const Icon(Icons.person, color: Colors.white)
                            : null,
                      ),
                      title: Text(
                        usuari['username'] ?? 'Usuari',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      subtitle: Text(
                        usuari['email'] ?? '',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey[400] : Colors.grey[700],
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              receptorUid: uid,
                              receptorNom: usuari['username'] ?? 'Usuari',
                            ),
                          ),
                        );
                      },
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
}
