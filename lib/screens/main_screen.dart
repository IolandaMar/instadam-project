import 'package:flutter/material.dart';
import 'package:instadamiolandafinal/screens/home_screen.dart';
import 'package:instadamiolandafinal/screens/profile_screen.dart';
import 'package:instadamiolandafinal/screens/settings_screen.dart';
import 'package:instadamiolandafinal/screens/chat_list_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _paginaActual = 0;

  final List<Widget> _pantalles = const [
    HomeScreen(),
    ProfileScreen(),
    ChatListScreen(),
    SettingsScreen(),
  ];

  void canviarPagina(int index) {
    setState(() {
      _paginaActual = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final logo = isDark ? 'assets/logo_dark.png' : 'assets/logo_white.png';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Align(
          alignment: Alignment.centerRight,
          child: Image.asset(
            logo,
            height: 36,
          ),
        ),
      ),
      body: _pantalles[_paginaActual],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _paginaActual,
        onTap: canviarPagina,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inici',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Xat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Configuració',
          ),
        ],
      ),
    );
  }
}
