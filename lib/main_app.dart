import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:instadamiolandafinal/screens/login_screen.dart';
import 'package:instadamiolandafinal/screens/main_screen.dart';
import 'package:instadamiolandafinal/services/settings_service.dart';

class InstadamApp extends StatelessWidget {
  final bool modeFoscActivat;

  const InstadamApp({Key? key, required this.modeFoscActivat}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
      themeMode: modeFoscActivat ? ThemeMode.dark : ThemeMode.light,
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
    );
  }
}

Future<Widget> iniciarAppAmbTema() async {
  final modeFosc = await SettingsService().getModeFosc();
  return InstadamApp(modeFoscActivat: modeFosc);
}

