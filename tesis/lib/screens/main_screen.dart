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
      _showSnackbar('🚫 No tienes permisos de administrador', Colors.red);
      return;
    }
    setState(() => _currentSection = section);
    Navigator.of(context).pop(); // close drawer on mobile
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(dbService: _dbService),
      ),
    );
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

  Widget _buildSidebarContent() {
    return Column(
      children: [
        const SizedBox(height: 20),
        _SidebarButton(
          icon: '📊',
          label: 'Dashboard',
          isActive: _currentSection == 'dashboard',
          onTap: () => _showSection('dashboard'),
        ),
        _SidebarButton(
          icon: '📈',
          label: 'Valores en Vivo',
          isActive: _currentSection == 'valores',
          onTap: () => _showSection('valores'),
        ),
        if (_dbService.isAdmin)
          _SidebarButton(
            icon: '👑',
            label: 'Administración',
            isActive: _currentSection == 'admin',
            onTap: () => _showSection('admin'),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = _dbService.userData?['displayName'] ?? user?.email?.split('@')[0] ?? 'Usuario';
    final isWide = MediaQuery.of(context).size.width > 768;

    return Scaffold(
      key: _scaffoldKey,
      // Top bar
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        leading: isWide
            ? null
            : IconButton(
                icon: const Icon(Icons.menu, color: Color(0xFF333333)),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
        automaticallyImplyLeading: false,
        title: GestureDetector(
          onTap: _openProfile,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFDEE2E6)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF667EEA).withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      displayName.toString().isNotEmpty
                          ? displayName.toString()[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayName.toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      user?.email ?? '',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: Color(0xFF667EEA), size: 18),
              ],
            ),
          ),
        ),
        actions: [
          // Notification badge
          if (_dbService.notifications.isNotEmpty)
            IconButton(
              icon: Badge(
                label: Text('${_dbService.notifications.length}'),
                child: const Icon(Icons.notifications_outlined, color: Color(0xFF333333)),
              ),
              onPressed: () => _showNotificationsSheet(),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _LogoutButton(onTap: _logout),
          ),
        ],
      ),

      // Drawer for mobile
      drawer: isWide
          ? null
          : Drawer(
              child: Container(
                color: Colors.white,
                child: _buildSidebarContent(),
              ),
            ),

      body: Row(
        children: [
          // Fixed sidebar for wide screens
          if (isWide)
            Container(
              width: 250,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(2, 0),
                  ),
                ],
              ),
              child: _buildSidebarContent(),
            ),
          // Main content
          Expanded(
            child: _buildCurrentSection(),
          ),
        ],
      ),
    );
  }

  void _showNotificationsSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxHeight: 400),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('🔔 Notificaciones',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () {
                    _dbService.notifications.clear();
                    _dbService.notifyListeners();
                    Navigator.pop(context);
                  },
                  child: const Text('Limpiar'),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: _dbService.notifications.length,
                itemBuilder: (_, i) {
                  final n = _dbService.notifications[i];
                  return ListTile(
                    dense: true,
                    title: Text(n.message, style: const TextStyle(fontSize: 13)),
                    subtitle: Text(
                      '${n.time.hour}:${n.time.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
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

class _SidebarButton extends StatelessWidget {
  final String icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _SidebarButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Material(
        color: isActive ? const Color(0xFF007BFF) : Colors.transparent,
        borderRadius: BorderRadius.circular(5),
        child: InkWell(
          borderRadius: BorderRadius.circular(5),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.white : const Color(0xFF333333),
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

class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;
  const _LogoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF093FB), Color(0xFFF5576C)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🚪', style: TextStyle(fontSize: 14)),
            SizedBox(width: 5),
            Text(
              'Cerrar Sesión',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
