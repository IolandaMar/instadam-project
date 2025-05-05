import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class LikesDialog extends StatelessWidget {
  final List<String> uids;

  const LikesDialog({super.key, required this.uids});

  Future<List<String>> _carregarUsuaris() async {
    final firestore = FirebaseFirestore.instance;
    final List<String> noms = [];

    for (String uid in uids) {
      final doc = await firestore.collection('usuaris').doc(uid).get();
      final data = doc.data();
      if (data != null && data.containsKey('username')) {
        noms.add(data['username']);
      }
    }

    return noms;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Usuaris que han donat like'),
      content: FutureBuilder<List<String>>(
        future: _carregarUsuaris(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
          }

          final noms = snapshot.data!;
          if (noms.isEmpty) {
            return const Text('Encara no hi ha likes.');
          }

          return SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: noms.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(noms[index]),
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
