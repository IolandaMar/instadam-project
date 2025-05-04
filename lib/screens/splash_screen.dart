import 'dart:async';
import 'package:flutter/material.dart';
import 'package:instadamiolandafinal/main_app.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();

    Timer(const Duration(milliseconds: 300), () {
      setState(() => _opacity = 1.0);
    });

    _iniciarApp();
  }

  Future<void> _iniciarApp() async {
    await Future.delayed(const Duration(seconds: 3));
    final Widget app = await iniciarAppAmbTema();

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => app),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFEDA75), // groc
              Color(0xFFFC8C34), // taronja
              Color(0xFFD62976), // rosa
              Color(0xFF962FBF), // lila
              Color(0xFF4F5BD5), // blau
            ],
          ),
        ),
        child: Center(
          child: AnimatedOpacity(
            opacity: _opacity,
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeInOut,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/logo_white.png',
                  width: 160,
                ),
                const SizedBox(height: 12),
                const Text(
                  'INSTADAM',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.4,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

