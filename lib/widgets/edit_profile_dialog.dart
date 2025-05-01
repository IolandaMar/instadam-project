import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
      setState(() => _photoPath = imatge.path);
    }
  }

  Future<void> _guardarCanvis() async {
    final prefs = await SharedPreferences.getInstance();
    final username = _usernameController.text.trim();
    final bio = _bioController.text.trim();

    try {
      await FirebaseFirestore.instance.collection('usuaris').doc(uid).update({
        'username': username,
        'bio': bio,
      });
    } catch (_) {}

    await prefs.setString('username', username);
    await prefs.setString('bio', bio);

    if (_photoPath != null) {
      await prefs.setString('photoPath', _photoPath!);
      await prefs.setString('avatar_$uid', _photoPath!); // ✅ Guardem per ús global
    }

    widget.onUpdated();
    if (mounted) Navigator.pop(context);
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
