import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:instadamiolandafinal/providers/theme_provider.dart';
import 'package:instadamiolandafinal/screens/login_screen.dart';
import 'package:instadamiolandafinal/screens/main_screen.dart';

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

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const InstadamApp()),
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
              Color(0xFFFEDA75),
              Color(0xFFFC8C34),
              Color(0xFFD62976),
              Color(0xFF962FBF),
              Color(0xFF4F5BD5),
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

class InstadamApp extends StatelessWidget {
  const InstadamApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return AnimatedTheme(
      duration: const Duration(milliseconds: 300),
      data: themeProvider.isDarkMode ? ThemeData.dark() : ThemeData.light(),
      child: MaterialApp(
        title: 'Instadam',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.light,
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
        home: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            return snapshot.hasData ? const MainScreen() : const LoginScreen();
          },
        ),
      ),
    );
  }
}
