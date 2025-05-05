import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'likes_dialog.dart';

class CommentsScreen extends StatefulWidget {
  final String postId;

  const CommentsScreen({Key? key, required this.postId}) : super(key: key);

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final TextEditingController _comentariController = TextEditingController();
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  Map<String, String> avatars = {};

  @override
  void initState() {
    super.initState();
    _carregarAvatars();
  }

  Future<void> _carregarAvatars() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();

    final avatarMap = <String, String>{};
    for (var key in keys) {
      if (key.startsWith('avatar_')) {
        final uid = key.replaceFirst('avatar_', '');
        avatarMap[uid] = prefs.getString(key) ?? '';
      }
    }

    setState(() {
      avatars = avatarMap;
    });
  }

  void enviarComentari() async {
    final text = _comentariController.text.trim();
    if (text.isEmpty) return;

    final userDoc = await FirebaseFirestore.instance.collection('usuaris').doc(uid).get();
    final username = userDoc.data()?['username'] ?? 'Usuari';

    await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .add({
      'text': text,
      'uid': uid,
      'username': username,
      'timestamp': Timestamp.now(),
      'likes': [],
    });

    _comentariController.clear();
  }

  void _canviarLikeComentari(DocumentSnapshot comentari) async {
    final comentariRef = comentari.reference;
    final likes = List<String>.from(comentari['likes'] ?? []);

    if (likes.contains(uid)) {
      await comentariRef.update({
        'likes': FieldValue.arrayRemove([uid])
      });
    } else {
      await comentariRef.update({
        'likes': FieldValue.arrayUnion([uid])
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comentaris'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .doc(widget.postId)
                  .collection('comments')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final comentaris = snapshot.data!.docs.where((comentari) {
                  final data = comentari.data() as Map<String, dynamic>;
                  return data.containsKey('uid') &&
                      data.containsKey('username') &&
                      data.containsKey('text') &&
                      data.containsKey('timestamp');
                }).toList();

                if (comentaris.isEmpty) {
                  return const Center(child: Text('Encara no hi ha comentaris.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: comentaris.length,
                  itemBuilder: (context, index) {
                    final comentari = comentaris[index];
                    final data = comentari.data() as Map<String, dynamic>;

                    final timestamp = (data['timestamp'] as Timestamp).toDate();
                    final formattedDate =
                        '${timestamp.day}/${timestamp.month}/${timestamp.year} • ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';

                    final String comentUid = data['uid'];
                    final String? avatarPath = avatars[comentUid];
                    final List likes = data['likes'] ?? [];
                    final bool liked = likes.contains(uid);

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundImage: (avatarPath != null && avatarPath.isNotEmpty)
                                ? FileImage(File(avatarPath))
                                : null,
                            backgroundColor: Colors.grey,
                            child: (avatarPath == null || avatarPath.isEmpty)
                                ? const Icon(Icons.person, size: 18, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    style: Theme.of(context).textTheme.bodyMedium,
                                    children: [
                                      TextSpan(
                                        text: data['username'],
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const TextSpan(text: '  '),
                                      TextSpan(text: data['text']),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      formattedDate,
                                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                    ),
                                    const SizedBox(width: 12),
                                    GestureDetector(
                                      onTap: () => _canviarLikeComentari(comentari),
                                      child: Icon(
                                        liked ? Icons.favorite : Icons.favorite_border,
                                        color: liked ? Colors.red : Colors.grey,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    GestureDetector(
                                      onTap: () {
                                        if (likes.isNotEmpty) {
                                          showDialog(
                                            context: context,
                                            builder: (_) => LikesDialog(uids: List<String>.from(likes)),
                                          );
                                        }
                                      },
                                      child: Text(
                                        '${likes.length}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: likes.isNotEmpty ? Colors.blue : Colors.grey[600],
                                          decoration: likes.isNotEmpty
                                              ? TextDecoration.underline
                                              : null,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _comentariController,
                    decoration: InputDecoration(
                      hintText: 'Escriu un comentari...',
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[800]
                          : Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: enviarComentari,
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFFFEDA75),
                          Color(0xFFD62976),
                          Color(0xFF4F5BD5),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
