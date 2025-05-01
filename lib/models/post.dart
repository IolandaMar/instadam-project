import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String uid;
  final String username;
  final String description;
  final List<String> photoUrls;
  final DateTime datePublished;
  final List<String> likes;

  Post({
    required this.id,
    required this.uid,
    required this.username,
    required this.description,
    required this.photoUrls,
    required this.datePublished,
    required this.likes,
  });

  // Constructor des de Firestore
  factory Post.fromSnap(DocumentSnapshot snap) {
    final data = snap.data() as Map<String, dynamic>;

    return Post(
      id: data['id'] ?? '',
      uid: data['uid'] ?? '',
      username: data['username'] ?? '',
      description: data['description'] ?? '',
      photoUrls: List<String>.from(data['photoUrls'] ?? []),
      datePublished: (data['datePublished'] is Timestamp)
          ? (data['datePublished'] as Timestamp).toDate()
          : DateTime.tryParse(data['datePublished'] ?? '') ?? DateTime.now(),
      likes: List<String>.from(data['likes'] ?? []),
    );
  }

  // Constructor des de Map<String, dynamic> (per JSON/local)
  factory Post.fromMap(Map<String, dynamic> data) {
    return Post(
      id: data['id'] ?? '',
      uid: data['uid'] ?? '',
      username: data['username'] ?? '',
      description: data['description'] ?? '',
      photoUrls: List<String>.from(data['photoUrls'] ?? []),
      datePublished: DateTime.tryParse(data['datePublished'] ?? '') ?? DateTime.now(),
      likes: List<String>.from(data['likes'] ?? []),
    );
  }

  // Exportar a Firestore / JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'uid': uid,
    'username': username,
    'description': description,
    'photoUrls': photoUrls,
    'datePublished': datePublished.toIso8601String(),
    'likes': likes,
  };
}
