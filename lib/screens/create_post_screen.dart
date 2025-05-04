import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:instadamiolandafinal/services/post_service.dart';
import 'package:uuid/uuid.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({Key? key}) : super(key: key);

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _descController = TextEditingController();
  final List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  bool _loading = false;

  Future<void> _seleccionarImatges() async {
    try {
      final List<XFile> imatges = await _picker.pickMultiImage();

      if (imatges.length > 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Només pots seleccionar fins a 5 imatges.')),
        );
        return;
      }

      setState(() {
        _selectedImages.clear();
        _selectedImages.addAll(imatges);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error seleccionant imatges: $e')),
      );
    }
  }

  Future<void> _pujarPost() async {
    if (_descController.text.trim().isEmpty || _selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Afegeix una descripció i almenys una imatge.')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final userDoc = await FirebaseFirestore.instance.collection('usuaris').doc(uid).get();
      final username = userDoc['username'] ?? 'Usuari';

      final postId = const Uuid().v1();

      final photoPaths = _selectedImages.map((xfile) => xfile.path).toList();

      final resultat = await PostService().pujarPost(
        uid: uid,
        username: username,
        description: _descController.text.trim(),
        photoUrls: photoPaths,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resultat)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar el post: $e')),
      );
    }

    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova publicació'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Descripció',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                onPressed: _seleccionarImatges,
                icon: const Icon(Icons.photo_library),
                label: const Text('Seleccionar imatges'),
              ),
            ),
            if (_selectedImages.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _selectedImages.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                itemBuilder: (context, index) {
                  return Image.file(
                    File(_selectedImages[index].path),
                    fit: BoxFit.cover,
                  );
                },
              ),
            const SizedBox(height: 24),
            _loading
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
              onPressed: _pujarPost,
              icon: const Icon(Icons.publish),
              label: const Text('Publicar'),
            ),
          ],
        ),
      ),
    );
  }
}
