import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> iniciarSessio({
    required String email,
    required String contrasenya,
  }) async {
    String resultat = "Alguna cosa ha fallat. Torna-ho a intentar.";

    try {
      if (email.isNotEmpty && contrasenya.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear(); // 🔄 Neteja qualsevol dada d'usuari anterior

        await _auth.signInWithEmailAndPassword(
          email: email,
          password: contrasenya,
        );

        final uid = _auth.currentUser!.uid;
        final doc = await _firestore.collection('usuaris').doc(uid).get();
        if (doc.exists) {
          final data = doc.data()!;
          await prefs.setString('username', data['username'] ?? 'usuariperdefecte');
          await prefs.setString('bio', data['bio'] ?? 'biografia per defecte');
          await prefs.setString('avatar_$uid', data['photoUrl'] ?? '');
          await prefs.setString('photoPath', data['photoUrl'] ?? '');
        }

        resultat = "Sessió iniciada correctament.";
      } else {
        resultat = "Si us plau, omple tots els camps.";
      }
    } on FirebaseAuthException catch (e) {
      resultat = e.message ?? resultat;
    }

    return resultat;
  }

  Future<String> registrarUsuari({
    required String email,
    required String contrasenya,
    required String username,
  }) async {
    String resultat = "Alguna cosa ha fallat. Torna-ho a intentar.";

    try {
      if (email.isEmpty || contrasenya.isEmpty || username.isEmpty) {
        return "Si us plau, omple tots els camps.";
      }

      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: contrasenya,
      );

      final uid = cred.user!.uid;
      final docRef = _firestore.collection('usuaris').doc(uid);
      final existeix = (await docRef.get()).exists;

      if (!existeix) {
        await docRef.set({
          'uid': uid,
          'email': email,
          'username': username,
          'bio': 'biografia per defecte',
          'photoUrl': '',
          'dataRegistre': DateTime.now(),
        });
      }

      resultat = "Compte creat correctament.";
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        resultat = "Aquest correu ja està registrat.";
      } else if (e.code == 'weak-password') {
        resultat = "La contrasenya és massa dèbil.";
      } else {
        resultat = e.message ?? resultat;
      }
    }

    return resultat;
  }

  Future<void> tancarSessio() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await _auth.signOut();
  }
}
