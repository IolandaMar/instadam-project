import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditProfileDialog extends StatefulWidget {
  final String currentUsername;
  final String currentBio;
  final String currentPhotoPath;
  final VoidCallback onUpdated;

  const EditProfileDialog({
    Key? key,
    required this.currentUsername,
    required this.currentBio,
    required this.currentPhotoPath,
    required this.onUpdated,
  }) : super(key: key);

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  final uid = FirebaseAuth.instance.currentUser!.uid;

  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  String? _photoPath;
  bool _avatarActualitzat = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.currentUsername);
    _bioController = TextEditingController(text: widget.currentBio);
    _photoPath = widget.currentPhotoPath;
  }

  Future<void> _seleccionarAvatar() async {
    final picker = ImagePicker();
    final imatge = await picker.pickImage(source: ImageSource.gallery);
    if (imatge != null) {
      setState(() {
        _photoPath = imatge.path;
        _avatarActualitzat = true;
      });
    }
  }

  Future<String?> _pujarAvatarAlStorage(String path) async {
    try {
      final ref = FirebaseStorage.instance.ref().child('avatars').child('$uid.jpg');
      await ref.putFile(File(path));
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error pujant avatar: $e');
      return null;
    }
  }

  Future<void> _guardarCanvis() async {
    final prefs = await SharedPreferences.getInstance();
    final username = _usernameController.text.trim();
    final bio = _bioController.text.trim();

    try {
      final userRef = FirebaseFirestore.instance.collection('usuaris').doc(uid);

      String? novaUrlAvatar;
      if (_avatarActualitzat && _photoPath != null) {
        novaUrlAvatar = await _pujarAvatarAlStorage(_photoPath!);
        if (novaUrlAvatar != null) {
          await userRef.update({'photoUrl': novaUrlAvatar});
          await prefs.setString('avatar_$uid', novaUrlAvatar);
        } else {
          throw 'No s\'ha pogut pujar l\'avatar.';
        }
      }

      await userRef.update({'username': username, 'bio': bio});
      await prefs.setString('username', username);
      await prefs.setString('bio', bio);

      widget.onUpdated();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      print('Error desant perfil: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error desant el perfil.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar perfil'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            GestureDetector(
              onTap: _seleccionarAvatar,
              child: CircleAvatar(
                radius: 40,
                backgroundImage: (_photoPath != null && _photoPath!.isNotEmpty)
                    ? FileImage(File(_photoPath!))
                    : null,
                backgroundColor: Colors.grey[300],
                child: (_photoPath == null || _photoPath!.isEmpty)
                    ? const Icon(Icons.person, size: 40, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Nom d\'usuari'),
            ),
            TextField(
              controller: _bioController,
              decoration: const InputDecoration(labelText: 'Biografia'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel·la'),
        ),
        ElevatedButton(
          onPressed: _guardarCanvis,
          child: const Text('Desar'),
        ),
      ],
    );
  }
}
