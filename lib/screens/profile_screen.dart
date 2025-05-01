import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:instadamiolandafinal/models/post.dart';
import 'package:instadamiolandafinal/screens/create_post_screen.dart';
import 'package:instadamiolandafinal/services/post_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:instadamiolandafinal/widgets/edit_profile_dialog.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  Map<String, dynamic> usuari = {};
  bool _carregant = true;

  @override
  void initState() {
    super.initState();
    _carregarPerfil();
  }

  Future<void> _carregarPerfil() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final doc = await FirebaseFirestore.instance.collection('usuaris').doc(uid).get();

      usuari = {
        'username': 'usuariperdefecte',
        'bio': 'biografia per defecte',
        'photoPath': '',
      };

      if (doc.exists) {
        final data = doc.data()!;
        usuari['username'] = data['username'] ?? 'usuariperdefecte';
        usuari['bio'] = data['bio'] ?? 'biografia per defecte';
        await prefs.setString('username', usuari['username']);
        await prefs.setString('bio', usuari['bio']);
      } else {
        // Guardar per primer cop si no existia
        await FirebaseFirestore.instance.collection('usuaris').doc(uid).set({
          'uid': uid,
          'username': 'usuariperdefecte',
          'bio': 'biografia per defecte',
          'email': FirebaseAuth.instance.currentUser?.email ?? '',
          'photoUrl': '',
          'dataRegistre': DateTime.now(),
        });
      }

      usuari['photoPath'] = prefs.getString('photoPath') ?? '';

      setState(() => _carregant = false);
    } catch (e) {
      setState(() => _carregant = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al carregar el perfil: $e')),
      );
    }
  }

  void _mostrarPopupEditarPerfil() {
    showDialog(
      context: context,
      builder: (_) => EditProfileDialog(
        currentUsername: usuari['username'] ?? '',
        currentBio: usuari['bio'] ?? '',
        currentPhotoPath: usuari['photoPath'] ?? '',
        onUpdated: _carregarPerfil,
      ),
    );
  }

  Widget _botoGradient({required VoidCallback onTap, required String text}) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFEDA75),
            Color(0xFFD62976),
            Color(0xFF4F5BD5),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 20),
            child: Center(
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_carregant) return const Center(child: CircularProgressIndicator());

    final photoPath = usuari['photoPath'];
    final String username = usuari['username'] ?? 'usuariperdefecte';
    final String bio = usuari['bio'] ?? 'biografia per defecte';

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: GestureDetector(
                  onTap: _mostrarPopupEditarPerfil,
                  child: CircleAvatar(
                    radius: 42,
                    backgroundImage: (photoPath != null && photoPath.isNotEmpty)
                        ? FileImage(File(photoPath))
                        : null,
                    backgroundColor: Colors.grey[300],
                    child: (photoPath == null || photoPath.isEmpty)
                        ? const Icon(Icons.person, size: 40, color: Colors.white)
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        bio,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: 140,
                        child: _botoGradient(
                          onTap: _mostrarPopupEditarPerfil,
                          text: 'Editar perfil',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(thickness: 1),
          const SizedBox(height: 12),
          const Text(
            'Publicacions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<Post>>(
            stream: PostService().obtenirPosts(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

              final posts = snapshot.data!.where((p) => p.uid == uid).toList();

              if (posts.isEmpty) {
                return const Center(child: Text('Encara no has publicat res.'));
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: posts.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => Dialog(
                          backgroundColor: Colors.black,
                          child: PageView.builder(
                            itemCount: posts[index].photoUrls.length,
                            itemBuilder: (context, i) {
                              return Image.file(
                                File(posts[index].photoUrls[i]),
                                fit: BoxFit.contain,
                              );
                            },
                          ),
                        ),
                      );
                    },
                    onLongPress: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Eliminar publicació'),
                          content: const Text('Vols eliminar aquesta publicació?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel·la'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              onPressed: () async {
                                await FirebaseFirestore.instance
                                    .collection('posts')
                                    .doc(posts[index].id)
                                    .delete();
                                if (mounted) Navigator.pop(context);
                              },
                              child: const Text('Eliminar'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Image.file(
                      File(posts[index].photoUrls.first),
                      fit: BoxFit.cover,
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      floatingActionButton: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreatePostScreen()),
          );
        },
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              colors: [Color(0xFFFEDA75), Color(0xFFD62976), Color(0xFF4F5BD5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}
