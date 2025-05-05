import 'dart:io';
import 'package:flutter/material.dart';
import 'package:instadamiolandafinal/screens/sign_up_screen.dart';
import 'package:instadamiolandafinal/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:instadamiolandafinal/screens/main_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _mostrarContrasenya = false;

  Future<void> _desarDadesUsuari() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance.collection('usuaris').doc(uid).get();
    final prefs = await SharedPreferences.getInstance();

    if (doc.exists) {
      final data = doc.data()!;
      await prefs.setString('username', data['username'] ?? 'usuariperdefecte');
      await prefs.setString('bio', data['bio'] ?? 'biografia per defecte');
      await prefs.setString('avatar_$uid', data['photoUrl'] ?? '');
    } else {
      await prefs.setString('username', 'usuariperdefecte');
      await prefs.setString('bio', 'biografia per defecte');
    }

    await prefs.setString('photoPath', prefs.getString('photoPath') ?? '');
  }

  void loginUser() async {
    setState(() => _isLoading = true);

    String resultat = await AuthService().iniciarSessio(
      email: _emailController.text.trim(),
      contrasenya: _passwordController.text.trim(),
    );

    if (resultat == "Sessió iniciada correctament.") {
      await _desarDadesUsuari();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(resultat)),
      );
    }

    setState(() => _isLoading = false);
  }

  Future<void> loginWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      await _desarDadesUsuari();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error amb Google: $e')),
      );
    }
  }

  Widget _textGradient(String text) {
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return const LinearGradient(
          colors: [Color(0xFFFEDA75), Color(0xFFD62976), Color(0xFF4F5BD5)],
        ).createShader(bounds);
      },
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                isDark ? 'assets/logo_dark.png' : 'assets/logo_white.png',
                height: 80,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  hintText: 'Correu electrònic',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: !_mostrarContrasenya,
                decoration: InputDecoration(
                  hintText: 'Contrasenya',
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _mostrarContrasenya ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _mostrarContrasenya = !_mostrarContrasenya;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : loginUser,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Iniciar sessió'),
              ),
              const SizedBox(height: 16),
              Row(
                children: const [
                  Expanded(child: Divider(thickness: 1)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text('O'),
                  ),
                  Expanded(child: Divider(thickness: 1)),
                ],
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: loginWithGoogle,
                icon: Image.asset('assets/google_icon.png', height: 20),
                label: const Text('Inicia sessió amb Google'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("No tens compte? "),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SignUpScreen()),
                      );
                    },
                    child: _textGradient("Registra't"),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
