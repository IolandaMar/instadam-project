import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class LikesDialog extends StatelessWidget {
  final List<String> uids;

  const LikesDialog({super.key, required this.uids});

  Future<List<Map<String, String>>> _carregarUsuaris() async {
    final firestore = FirebaseFirestore.instance;
    final List<Map<String, String>> usuaris = [];

    for (String uid in uids) {
      final doc = await firestore.collection('usuaris').doc(uid).get();
      final data = doc.data();
      if (data != null) {
        usuaris.add({
          'username': data['username'] ?? 'Usuari',
          'photoUrl': data['photoUrl'] ?? '',
        });
      }
    }

    return usuaris;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Usuaris que han donat like'),
      content: FutureBuilder<List<Map<String, String>>>(
        future: _carregarUsuaris(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
          }

          final usuaris = snapshot.data!;
          if (usuaris.isEmpty) {
            return const Text('Encara no hi ha likes.');
          }

          return SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: usuaris.length,
              itemBuilder: (context, index) {
                final username = usuaris[index]['username']!;
                final photoUrl = usuaris[index]['photoUrl']!;

                return ListTile(
                  leading: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                    child: photoUrl.isEmpty
                        ? const Icon(Icons.person, color: Colors.white)
                        : null,
                  ),
                  title: Text(username),
                );
              },
            ),
          );
        },
      ),
      actions: [
        TextButton(
          child: const Text('Tancar'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
