import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:instadamiolandafinal/models/post.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String cacheKey = 'cached_posts';

  Future<String> pujarPost({
    required String uid,
    required String username,
    required String description,
    required List<String> photoUrls,
  }) async {
    String resultat = "Error en pujar el post. Torna-ho a intentar.";

    try {
      String postId = const Uuid().v1();

      final post = Post(
        id: postId,
        uid: uid,
        username: username,
        description: description,
        photoUrls: photoUrls,
        datePublished: DateTime.now(),
        likes: [],
      );

      await _firestore.collection('posts').doc(postId).set(post.toJson());
      resultat = "Post pujat correctament.";
    } catch (e) {
      resultat = "Error: ${e.toString()}";
    }

    return resultat;
  }

  Stream<List<Post>> obtenirPosts() {
    return _firestore
        .collection('posts')
        .orderBy('datePublished', descending: true)
        .snapshots()
        .map((snapshot) {
      final posts = snapshot.docs
          .map((doc) {
        try {
          return Post.fromSnap(doc);
        } catch (_) {
          return null;
        }
      })
          .whereType<Post>()
          .toList();

      _guardarPostsEnLocal(posts);
      return posts;
    });
  }

  Future<void> _guardarPostsEnLocal(List<Post> posts) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> jsonPosts = posts.map((p) => jsonEncode(p.toJson())).toList();
    await prefs.setStringList(cacheKey, jsonPosts);
  }

  Future<List<Post>> obtenirPostsDesDelCache() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? cached = prefs.getStringList(cacheKey);

    if (cached != null && cached.isNotEmpty) {
      return cached.map((jsonStr) {
        try {
          final Map<String, dynamic> data = jsonDecode(jsonStr);
          return Post(
            id: data['id'] ?? '',
            uid: data['uid'] ?? '',
            username: data['username'] ?? '',
            description: data['description'] ?? '',
            photoUrls: List<String>.from(data['photoUrls'] ?? []),
            datePublished: DateTime.tryParse(data['datePublished'] ?? '') ?? DateTime.now(),
            likes: List<String>.from(data['likes'] ?? []),
          );
        } catch (_) {
          return null;
        }
      }).whereType<Post>().toList();
    } else {
      return [];
    }
  }

  Future<void> canviarLike({
    required String postId,
    required String uid,
    required List likesActuals,
  }) async {
    try {
      final docRef = _firestore.collection('posts').doc(postId);
      if (likesActuals.contains(uid)) {
        await docRef.update({'likes': FieldValue.arrayRemove([uid])});
      } else {
        await docRef.update({'likes': FieldValue.arrayUnion([uid])});
      }
    } catch (e) {
      print('[LIKE ERROR] ${e.toString()}');
    }
  }
}
