import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import 'dashboard_screen.dart';
import 'valores_screen.dart';
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
  String _currentSection = 'dashboard';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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

  void _showSection(String section) {
    if (section == 'admin' && !_dbService.isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🚫 No tienes permisos de administrador'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _currentSection = section);
    if (_scaffoldKey.currentState?.isDrawerOpen == true) {
      Navigator.of(context).pop();
    }
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
    switch (_currentSection) {
      case 'valores':
        return ValoresScreen(dbService: _dbService);
      case 'admin':
        return AdminScreen(dbService: _dbService);
      default:
        return DashboardScreen(dbService: _dbService);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = _dbService.userData?['displayName']?.toString().isNotEmpty == true
        ? _dbService.userData!['displayName'].toString()
        : user?.email?.split('@')[0] ?? 'Usuario';

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFEEF2F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: const IconThemeData(color: Color(0xFF333333)),
        titleSpacing: 0,
        title: GestureDetector(
          onTap: _openProfile,
          child: Row(
            children: [
              Container(
                width: 30, height: 30,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
                ),
                child: Center(
                  child: Text(displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(displayName,
                    style: const TextStyle(color: Color(0xFF333333), fontSize: 14, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: _dbService.notifications.isNotEmpty,
              label: Text('${_dbService.notifications.length}', style: const TextStyle(fontSize: 9)),
              child: const Icon(Icons.notifications_outlined, size: 22),
            ),
            onPressed: _showNotificationsSheet,
          ),
          GestureDetector(
            onTap: _logout,
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFF093FB), Color(0xFFF5576C)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text('Salir', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
            ),
          ),
        ],
      ),

      // Bottom navigation for mobile
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentSection == 'dashboard' ? 0 : _currentSection == 'valores' ? 1 : 2,
        onTap: (i) {
          if (i == 0) _showSection('dashboard');
          if (i == 1) _showSection('valores');
          if (i == 2) {
            if (_dbService.isAdmin) {
              _showSection('admin');
            } else {
              _openProfile();
            }
          }
        },
        selectedItemColor: const Color(0xFF667EEA),
        unselectedItemColor: Colors.grey,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          const BottomNavigationBarItem(icon: Icon(Icons.sensors), label: 'En Vivo'),
          if (_dbService.isAdmin)
            const BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: 'Admin')
          else
            const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),

      // Drawer
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.9)),
                      child: Center(
                        child: Text(displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                            style: const TextStyle(color: Color(0xFF667EEA), fontWeight: FontWeight.bold, fontSize: 22)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(displayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(user?.email ?? '', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Mi Perfil'),
                onTap: () {
                  Navigator.pop(context);
                  _openProfile();
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _logout();
                },
              ),
            ],
          ),
        ),
      ),

      body: _buildCurrentSection(),
    );
  }

  void _showNotificationsSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(15))),
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxHeight: 400),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('🔔 Notificaciones', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () { _dbService.notifications.clear(); _dbService.notifyListeners(); Navigator.pop(context); },
                  child: const Text('Limpiar'),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: _dbService.notifications.isEmpty
                  ? const Center(child: Text('Sin notificaciones', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: _dbService.notifications.length,
                      itemBuilder: (_, i) {
                        final n = _dbService.notifications[i];
                        return ListTile(
                          dense: true,
                          title: Text(n.message, style: const TextStyle(fontSize: 13)),
                          subtitle: Text('${n.time.hour}:${n.time.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}