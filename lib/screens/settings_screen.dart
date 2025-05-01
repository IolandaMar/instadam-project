import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:instadamiolandafinal/screens/login_screen.dart';
import 'package:instadamiolandafinal/providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificacions = true;
  bool _recordarSessio = true;

  @override
  void initState() {
    super.initState();
    _carregarPreferencies();
  }

  Future<void> _carregarPreferencies() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificacions = prefs.getBool('notificacions') ?? true;
      _recordarSessio = prefs.getBool('recordar_sessio') ?? true;
    });
  }

  Future<void> _guardarPreferencia(String clau, bool valor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(clau, valor);
  }

  void _tancarSessio() async {
    await FirebaseAuth.instance.signOut();

    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
      );
    }
  }

  Widget _switchTile({
    required String title,
    required IconData icon,
    required bool valor,
    required Function(bool) onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      secondary: Icon(icon, color: Theme.of(context).colorScheme.primary),
      value: valor,
      onChanged: (value) => onChanged(value),
      activeColor: const Color(0xFF962FBF),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gradient = const LinearGradient(
      colors: [Color(0xFFFEDA75), Color(0xFFD62976), Color(0xFF4F5BD5)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return ListView(
      children: [
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Preferències',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const Divider(),
        _switchTile(
          title: 'Mode fosc',
          icon: Icons.dark_mode,
          valor: isDarkMode,
          onChanged: (value) {
            themeProvider.toggleTheme(value);
          },
        ),
        _switchTile(
          title: 'Rebre notificacions',
          icon: Icons.notifications_active,
          valor: _notificacions,
          onChanged: (value) {
            setState(() {
              _notificacions = value;
              _guardarPreferencia('notificacions', value);
            });
          },
        ),
        _switchTile(
          title: 'Recordar sessió',
          icon: Icons.verified_user,
          valor: _recordarSessio,
          onChanged: (value) {
            setState(() {
              _recordarSessio = value;
              _guardarPreferencia('recordar_sessio', value);
            });
          },
        ),
        const SizedBox(height: 24),
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ShaderMask(
            shaderCallback: (bounds) => gradient.createShader(
              Rect.fromLTWH(0, 0, bounds.width, bounds.height),
            ),
            blendMode: BlendMode.srcIn,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _tancarSessio,
              icon: const Icon(Icons.logout),
              label: const Text(
                'Tancar sessió',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
