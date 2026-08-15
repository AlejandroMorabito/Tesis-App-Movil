import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'services/auth_service.dart';
import 'services/sismo_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    // Ya inicializado
  }
  runApp(const SismoApp());
}

class SismoApp extends StatefulWidget {
  const SismoApp({super.key});

  static void toggleTheme(BuildContext context) {
    final state = context.findAncestorStateOfType<_SismoAppState>();
    state?._toggleTheme();
  }

  static bool isDark(BuildContext context) {
    final state = context.findAncestorStateOfType<_SismoAppState>();
    return state?._isDark ?? true;
  }

  @override
  State<SismoApp> createState() => _SismoAppState();
}

class _SismoAppState extends State<SismoApp> {
  bool _isDark = true;

  void _toggleTheme() {
    setState(() => _isDark = !_isDark);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SISMO',
      debugShowCheckedModeBanner: false,
      theme: sismoLightTheme,
      darkTheme: sismoDarkTheme,
      themeMode: _isDark ? ThemeMode.dark : ThemeMode.light,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        colors: [SismoColors.teal, SismoColors.blue],
                      ),
                    ),
                    child: const Icon(Icons.shield, color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 20),
                  const CircularProgressIndicator(color: SismoColors.teal),
                ],
              ),
            ),
          );
        }
        if (snapshot.hasData) return const MainScreen();
        return const LoginScreen();
      },
    );
  }
}