import 'package:flutter/material.dart';
import '../services/database_service.dart';

class AdminScreen extends StatefulWidget {
  final DatabaseService dbService;
  const AdminScreen({super.key, required this.dbService});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  Map<String, dynamic>? _adminData;
  bool _loading = true;
  String _searchQuery = '';
  final _webhookController = TextEditingController();
  String? _webhookMsg;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      _adminData = await widget.dbService.loadAdminData();
      final url = await widget.dbService.loadWebhookUrl();
      _webhookController.text = url;
    } catch (e) {
      debugPrint('Error loading admin data: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveWebhook() async {
    try {
      await widget.dbService.saveWebhookUrl(_webhookController.text.trim());
      setState(() => _webhookMsg = '✅ Webhook guardado correctamente');
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _webhookMsg = null);
      });
    } catch (e) {
      setState(() => _webhookMsg = '❌ Error al guardar: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 15),
            Text('Cargando datos de administración...', style: TextStyle(color: Color(0xFF666666))),
          ],
        ),
      );
    }

    final users = (_adminData?['users'] as List<Map<String, dynamic>>?) ?? [];
    final allChipIds = (_adminData?['allChipIds'] as List<String>?) ?? [];

    final totalUsers = users.length;
    final activeUsers = users.where((u) => u['status'] == 'active').length;
    final adminUsers = users.where((u) => u['role'] == 'admin').length;
    final totalDevices = allChipIds.length;

    final filtered = users.where((u) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return (u['email']?.toString().toLowerCase().contains(q) ?? false) ||
          (u['displayName']?.toString().toLowerCase().contains(q) ?? false);
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('👑 Panel de Administración',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
          const SizedBox(height: 20),

          // Stats
          Wrap(
            spacing: 15,
            runSpacing: 15,
            children: [
              _StatCard('👥 Usuarios', '$totalUsers', '$activeUsers activos', const Color(0xFF667EEA)),
              _StatCard('👑 Admins', '$adminUsers',
                  '${totalUsers > 0 ? (adminUsers / totalUsers * 100).round() : 0}%', const Color(0xFF667EEA)),
              _StatCard('📱 Dispositivos', '$totalDevices', 'Disponibles', const Color(0xFFFFC107)),
              _StatCard('🔐 Permisos', '${allChipIds.length}', 'Chips totales', const Color(0xFF6C757D)),
            ],
          ),
          const SizedBox(height: 20),

          // Webhook config
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF667EEA).withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text('🔔', style: TextStyle(fontSize: 24)),
                    SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Webhook de Notificaciones',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text('Make → Wasend (WhatsApp) + Correo',
                            style: TextStyle(fontSize: 12, color: Color(0xFFAAAAAA))),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _webhookController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'https://hook.make.com/...',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _saveWebhook,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        backgroundColor: Colors.transparent,
                      ).copyWith(
                        backgroundColor: WidgetStateProperty.all(Colors.transparent),
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          child: Text('💾 Guardar',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_webhookMsg != null) ...[
                  const SizedBox(height: 10),
                  Text(_webhookMsg!, style: TextStyle(
                    fontSize: 13,
                    color: _webhookMsg!.startsWith('✅') ? const Color(0xFF28A745) : const Color(0xFFDC3545),
                  )),
                ],
                const SizedBox(height: 10),
                Text('Cuando se active una alarma, se enviará la info del evento y los datos de los usuarios vinculados.',
                    style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.5))),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Search
          TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Buscar usuarios por email o nombre...',
              prefixIcon: const Padding(
                padding: EdgeInsets.only(left: 15, right: 10),
                child: Text('🔍', style: TextStyle(fontSize: 18)),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: const BorderSide(color: Color(0xFF667EEA), width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
          ),
          const SizedBox(height: 20),

          // Users table
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Expanded(flex: 3, child: Text('Usuario', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14))),
                      Expanded(flex: 1, child: Text('Rol', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14))),
                      Expanded(flex: 1, child: Text('Estado', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14))),
                      Expanded(flex: 1, child: Text('Chips', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14))),
                      SizedBox(width: 70),
                    ],
                  ),
                ),
                // Rows
                ...filtered.map((user) => _buildUserRow(user, allChipIds)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Notes
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('💡 Notas:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF666666))),
                SizedBox(height: 5),
                Text(
                  '1. Solo usuarios admin pueden ver esta sección\n'
                  '2. Los chips se sincronizan automáticamente\n'
                  '3. Los permisos se asignan por dispositivo individual',
                  style: TextStyle(fontSize: 12, color: Color(0xFF666666)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserRow(Map<String, dynamic> user, List<String> allChipIds) {
    final chips = (user['chips'] as Map?) ?? {};
    final chipsWithAccess = chips.values.where((v) => v == true).length;
    final totalUserChips = chips.length;
    final displayName = user['displayName']?.toString().isNotEmpty == true
        ? user['displayName']
        : user['email']?.toString().split('@')[0] ?? 'Usuario';
    final isActive = user['status'] == 'active';
    final isAdminUser = user['role'] == 'admin';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(user['email'] ?? 'Sin email', style: const TextStyle(fontSize: 11, color: Color(0xFF666666))),
                Text('ID: ${(user['uid'] ?? '').toString().substring(0, 8)}...',
                    style: const TextStyle(fontSize: 10, color: Color(0xFF888888))),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isAdminUser ? const Color(0xFFDC3545).withOpacity(0.1) : const Color(0xFF28A745).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isAdminUser ? '👑 ADMIN' : '👤 USER',
                style: TextStyle(
                  color: isAdminUser ? const Color(0xFFDC3545) : const Color(0xFF28A745),
                  fontSize: 12, fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF28A745).withOpacity(0.1) : const Color(0xFF6C757D).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isActive ? '🟢 ACTIVO' : '🔴 INACTIVO',
                style: TextStyle(
                  color: isActive ? const Color(0xFF28A745) : const Color(0xFF6C757D),
                  fontSize: 12, fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Text('$chipsWithAccess/$totalUserChips',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('${totalUserChips > 0 ? (chipsWithAccess / totalUserChips * 100).round() : 0}%',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF666666))),
              ],
            ),
          ),
          SizedBox(
            width: 70,
            child: ElevatedButton(
              onPressed: () => _editUser(user, allChipIds),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3498DB),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
              ),
              child: const Text('✏️ Editar', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _editUser(Map<String, dynamic> user, List<String> allChipIds) {
    final uid = user['uid'];
    final chips = Map<String, bool>.from(
      (user['chips'] as Map? ?? {}).map((k, v) => MapEntry(k.toString(), v == true)),
    );
    final nameCtrl = TextEditingController(text: user['displayName'] ?? '');
    final phoneCtrl = TextEditingController(text: user['phone'] ?? '');
    String role = user['role'] ?? 'user';
    String status = user['status'] ?? 'active';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('👤 Editar Usuario'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Email: ${user['email']}', style: const TextStyle(fontSize: 13, color: Color(0xFF666666))),
                const SizedBox(height: 15),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Teléfono', border: OutlineInputBorder()),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: role,
                  decoration: const InputDecoration(labelText: 'Rol', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'user', child: Text('👤 Usuario')),
                    DropdownMenuItem(value: 'admin', child: Text('👑 Administrador')),
                  ],
                  onChanged: (v) => setDialogState(() => role = v!),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(labelText: 'Estado', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('🟢 Activo')),
                    DropdownMenuItem(value: 'inactive', child: Text('🔴 Inactivo')),
                  ],
                  onChanged: (v) => setDialogState(() => status = v!),
                ),
                const SizedBox(height: 15),
                const Text('Permisos de Chips:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...allChipIds.map((chipId) => SwitchListTile(
                  dense: true,
                  title: Text(chipId, style: const TextStyle(fontSize: 13)),
                  value: chips[chipId] ?? false,
                  activeColor: const Color(0xFF28A745),
                  onChanged: (v) => setDialogState(() => chips[chipId] = v),
                )),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                await widget.dbService.updateUser(uid, {
                  'displayName': nameCtrl.text.trim(),
                  'phone': phoneCtrl.text.trim(),
                  'role': role,
                  'status': status,
                  'chips': chips,
                });
                if (ctx.mounted) Navigator.pop(ctx);
                _loadData();
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF28A745)),
              child: const Text('💾 Guardar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _webhookController.dispose();
    super.dispose();
  }
}

class _StatCard extends StatelessWidget {
  final String label, value, subtitle;
  final Color borderColor;

  const _StatCard(this.label, this.value, this.subtitle, this.borderColor);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
        border: Border(top: BorderSide(color: borderColor, width: 4)),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF666666), letterSpacing: 1)),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
          const SizedBox(height: 5),
          Text(subtitle, style: TextStyle(fontSize: 11, color: borderColor)),
        ],
      ),
    );
  }
}
