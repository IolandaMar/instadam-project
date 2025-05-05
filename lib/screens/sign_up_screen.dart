import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:instadamiolandafinal/screens/main_screen.dart';
import 'package:instadamiolandafinal/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  bool _mostrarContrasenya = false;
  bool _mostrarConfirmacio = false;

  Future<void> _desarDadesUsuari() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance.collection('usuaris').doc(uid).get();
    final prefs = await SharedPreferences.getInstance();

    if (doc.exists) {
      final data = doc.data()!;
      await prefs.setString('username', data['username'] ?? 'usuariperdefecte');
      await prefs.setString('bio', data['bio'] ?? 'biografia per defecte');
      await prefs.setString('avatar_$uid', data['photoUrl'] ?? '');
    }

    await prefs.setString('photoPath', '');
  }

  void registerUser() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Les contrasenyes no coincideixen.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    String resultat = await AuthService().registrarUsuari(
      email: _emailController.text.trim(),
      contrasenya: _passwordController.text.trim(),
      username: _usernameController.text.trim(),
    );

    if (resultat == "Compte creat correctament.") {
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
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
                controller: _usernameController,
                decoration: const InputDecoration(
                  hintText: 'Nom d\'usuari',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                ),
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
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPasswordController,
                obscureText: !_mostrarConfirmacio,
                decoration: InputDecoration(
                  hintText: 'Confirmar contrasenya',
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _mostrarConfirmacio ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _mostrarConfirmacio = !_mostrarConfirmacio;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : registerUser,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Registrar-se'),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Ja tens compte? "),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: _textGradient("Inicia sessió"),
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
