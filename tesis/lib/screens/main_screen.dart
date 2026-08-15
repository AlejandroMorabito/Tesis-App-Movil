import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/sismo_theme.dart';
import '../main.dart';
import 'dashboard_screen.dart';
import 'valores_screen.dart';
import 'eventos_screen.dart';
import 'admin_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final AuthService _authService = AuthService();
  final DatabaseService _dbService = DatabaseService();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _dbService.addListener(_onDataChanged);
    _dbService.initialize();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _dbService.removeListener(_onDataChanged);
    _dbService.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: SismoColors.red),
            child: const Text('Cerrar Sesión', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      _dbService.dispose();
      await _authService.signOut();
    }
  }

  void _openProfile() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(dbService: _dbService)));
  }

  Widget _buildCurrentSection() {
    switch (_currentIndex) {
      case 1: return ValoresScreen(dbService: _dbService);
      case 2: return EventosScreen(dbService: _dbService);
      case 3:
        if (_dbService.isAdmin) return AdminScreen(dbService: _dbService);
        return ProfileScreen(dbService: _dbService);
      default: return DashboardScreen(dbService: _dbService);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.sismo;
    final user = FirebaseAuth.instance.currentUser;
    final displayName = _dbService.userData?['displayName']?.toString().isNotEmpty == true
        ? _dbService.userData!['displayName'].toString()
        : user?.email?.split('@')[0] ?? 'Usuario';

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            // Logo
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: const LinearGradient(colors: [SismoColors.teal, SismoColors.blue]),
              ),
              child: const Icon(Icons.shield, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Text('SISMO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: s.textPrimary, letterSpacing: 0.5)),
          ],
        ),
        actions: [
          // Theme toggle
          GestureDetector(
            onTap: () => SismoApp.toggleTheme(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Icon(
                context.isDark ? Icons.wb_sunny_outlined : Icons.dark_mode_outlined,
                size: 20, color: s.textSecondary,
              ),
            ),
          ),
          // Status pill
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: s.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: s.borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 7, height: 7, decoration: const BoxDecoration(shape: BoxShape.circle, color: SismoColors.green, boxShadow: [BoxShadow(color: SismoColors.green, blurRadius: 4)])),
                const SizedBox(width: 5),
                Text('Activo', style: TextStyle(fontSize: 11, color: s.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 6),
          // User avatar
          GestureDetector(
            onTap: _openProfile,
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [SismoColors.teal, SismoColors.blue]),
              ),
              child: Center(
                child: Text(
                  displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ),
          // LOGOUT BUTTON — AGREGAR ESTO
          IconButton(
            icon: const Icon(Icons.logout, color: SismoColors.red, size: 20),
            onPressed: _logout,
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: _buildCurrentSection(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        indicatorColor: SismoColors.teal.withOpacity(0.15),
        surfaceTintColor: Colors.transparent,
        height: 65,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          const NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard, color: SismoColors.teal), label: 'Dashboard'),
          const NavigationDestination(icon: Icon(Icons.sensors_outlined), selectedIcon: Icon(Icons.sensors, color: SismoColors.teal), label: 'En Vivo'),
          const NavigationDestination(icon: Icon(Icons.history), selectedIcon: Icon(Icons.history, color: SismoColors.teal), label: 'Eventos'),
          if (_dbService.isAdmin)
            const NavigationDestination(icon: Icon(Icons.admin_panel_settings_outlined), selectedIcon: Icon(Icons.admin_panel_settings, color: SismoColors.teal), label: 'Admin')
          else
            const NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person, color: SismoColors.teal), label: 'Perfil'),
        ],
      ),
    );
  }
}