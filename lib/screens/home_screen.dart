import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:instadamiolandafinal/models/post.dart';
import 'package:instadamiolandafinal/screens/comments_screen.dart';
import 'package:instadamiolandafinal/services/post_service.dart';
import 'package:share_plus/share_plus.dart';
import 'likes_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final String uidActual = FirebaseAuth.instance.currentUser!.uid;
  Map<String, String> avatars = {};

  @override
  void initState() {
    super.initState();
    _carregarAvatars();
  }

  Future<void> _carregarAvatars() async {
    final snapshot = await FirebaseFirestore.instance.collection('usuaris').get();

    final Map<String, String> avatarMap = {};
    for (final doc in snapshot.docs) {
      final uid = doc.id;
      final data = doc.data();
      final photoUrl = data['photoUrl'] ?? '';
      avatarMap[uid] = photoUrl;
    }

    setState(() {
      avatars = avatarMap;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: StreamBuilder<List<Post>>(
        stream: PostService().obtenirPosts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Encara no hi ha publicacions.'));
          }

          final posts = snapshot.data!;

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              final bool liked = post.likes.contains(uidActual);
              final avatarUrl = avatars[post.uid] ?? '';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey[300],
                      backgroundImage:
                      avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                      child: avatarUrl.isEmpty
                          ? const Icon(Icons.person, color: Colors.white)
                          : null,
                    ),
                    title: Text(post.username,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      '${post.datePublished.day}/${post.datePublished.month}/${post.datePublished.year}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) {
                        if (value == 'compartir') {
                          final textToShare = post.description +
                              (post.photoUrls.isNotEmpty
                                  ? '\n${post.photoUrls.first}'
                                  : '');
                          Share.share(textToShare);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'compartir',
                          child: Text('Compartir publicació'),
                        ),
                      ],
                    ),
                  ),
                  if (post.photoUrls.isNotEmpty)
                    SizedBox(
                      height: 300,
                      child: PageView.builder(
                        itemCount: post.photoUrls.length,
                        controller: PageController(viewportFraction: 1),
                        itemBuilder: (context, imgIndex) {
                          return Image.network(
                            post.photoUrls[imgIndex],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (_, __, ___) => Container(
                              height: 250,
                              color: Colors.grey[300],
                              child: const Center(
                                  child: Text('Error en carregar la imatge')),
                            ),
                          );
                        },
                      ),
                    ),
                  Padding(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            liked ? Icons.favorite : Icons.favorite_border,
                            color: liked
                                ? Colors.red
                                : (isDark ? Colors.grey[400] : Colors.black),
                          ),
                          onPressed: () {
                            PostService().canviarLike(
                              postId: post.id,
                              uid: uidActual,
                              likesActuals: post.likes,
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.comment_outlined),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CommentsScreen(postId: post.id),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  if (post.likes.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => LikesDialog(uids: post.likes),
                          );
                        },
                        child: Text(
                          '${post.likes.length} m\'agrada${post.likes.length > 1 ? "s" : ""}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                    child: RichText(
                      text: TextSpan(
                        style: Theme.of(context).textTheme.bodyMedium,
                        children: [
                          TextSpan(
                            text: post.username,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const TextSpan(text: '  '),
                          TextSpan(text: post.description),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
