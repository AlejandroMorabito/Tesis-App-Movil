import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/sismo_feedback.dart';
import '../services/sismo_theme.dart';

class AdminScreen extends StatefulWidget {
  final DatabaseService dbService;
  const AdminScreen({super.key, required this.dbService});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  Map<String, dynamic>? _adminData;
  List<Map<String, dynamic>> _nodes = [];
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
      _nodes = await widget.dbService.loadNodes();
      final url = await widget.dbService.loadWebhookUrl();
      _webhookController.text = url;
    } catch (e) {
      debugPrint('Error loading admin data: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveWebhook() async {
    SismoFeedback.show(context, 'Guardando webhook...', color: const Color(0xFF0EA5E9), icon: Icons.sync);
    try {
      await widget.dbService.saveWebhookUrl(_webhookController.text.trim());
      if (mounted) SismoFeedback.show(context, 'Webhook guardado', color: const Color(0xFF28A745), icon: Icons.check_circle);
      setState(() => _webhookMsg = 'Webhook guardado correctamente');
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _webhookMsg = null);
      });
    } catch (e) {
      setState(() => _webhookMsg = 'Error al guardar: $e');
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

    final s = context.sismo;
    final allUsers = (_adminData?['users'] as List<Map<String, dynamic>>?) ?? [];
    final allChipIds = (_adminData?['allChipIds'] as List<String>?) ?? [];
    // Ocultar cuentas eliminadas/bloqueadas
    final users = allUsers
        .where((u) => u['deleted'] != true && u['status'] != 'deleted')
        .toList();

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
          Row(
            children: [
              Icon(Icons.admin_panel_settings, color: s.textPrimary, size: 26),
              const SizedBox(width: 8),
              Text('Panel de Administración',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: s.textPrimary)),
            ],
          ),
          const SizedBox(height: 20),

          // Stats
          Wrap(
            spacing: 15,
            runSpacing: 15,
            children: [
              _StatCard(Icons.people, 'Usuarios', '$totalUsers', '$activeUsers activos', const Color(0xFF667EEA)),
              _StatCard(Icons.verified_user, 'Admins', '$adminUsers',
                  '${totalUsers > 0 ? (adminUsers / totalUsers * 100).round() : 0}%', const Color(0xFF667EEA)),
              _StatCard(Icons.router, 'Dispositivos', '$totalDevices', 'Disponibles', const Color(0xFFFFC107)),
              _StatCard(Icons.lock, 'Permisos', '${allChipIds.length}', 'Chips totales', const Color(0xFF6C757D)),
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
                    Icon(Icons.notifications_active, size: 24, color: Color(0xFFFFC107)),
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
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.save, color: Colors.white, size: 16),
                            SizedBox(width: 6),
                            Text('Guardar',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          ]),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_webhookMsg != null) ...[
                  const SizedBox(height: 10),
                  Text(_webhookMsg!, style: TextStyle(
                    fontSize: 13,
                    color: _webhookMsg!.startsWith('Error') ? const Color(0xFFDC3545) : const Color(0xFF28A745),
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
            style: TextStyle(color: s.textPrimary),
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Buscar usuarios por email o nombre...',
              hintStyle: TextStyle(color: s.textMuted, fontSize: 14),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 15, right: 10),
                child: Icon(Icons.search, size: 20, color: s.textMuted),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              filled: true,
              fillColor: s.bgInset,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide(color: s.borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide(color: s.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: const BorderSide(color: SismoColors.teal, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
          ),
          const SizedBox(height: 16),

          // Botón crear usuario
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () => _createUser(allChipIds),
              icon: const Icon(Icons.person_add, color: Colors.white, size: 18),
              label: const Text('Crear Usuario',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C9A7),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Users table
          Container(
            decoration: BoxDecoration(
              color: s.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: s.borderColor),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [SismoColors.teal, SismoColors.blue]),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Expanded(child: Text('Usuario', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13))),
                      SizedBox(width: 38, child: Text('Rol', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 11))),
                      SizedBox(width: 46, child: Text('Estado', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 11))),
                      SizedBox(width: 44, child: Text('Chips', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 11))),
                      SizedBox(width: 40),
                    ],
                  ),
                ),
                // Rows
                ...filtered.map((user) => _buildUserRow(user, allChipIds)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Gestión de Nodos
          _buildNodesSection(),
          const SizedBox(height: 20),

          // Notes
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: s.bgInset,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: s.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.lightbulb_outline, size: 14, color: s.textSecondary),
                  const SizedBox(width: 6),
                  Text('Notas:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: s.textSecondary)),
                ]),
                const SizedBox(height: 5),
                Text(
                  '1. Solo usuarios admin pueden ver esta sección\n'
                  '2. Los chips se sincronizan automáticamente\n'
                  '3. Los permisos se asignan por dispositivo individual',
                  style: TextStyle(fontSize: 12, color: s.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserRow(Map<String, dynamic> user, List<String> allChipIds) {
    final s = context.sismo;
    final chips = (user['chips'] as Map?) ?? {};
    final chipsWithAccess = chips.values.where((v) => v == true).length;
    final totalUserChips = chips.length;
    final displayName = user['displayName']?.toString().isNotEmpty == true
        ? user['displayName']
        : user['email']?.toString().split('@')[0] ?? 'Usuario';
    final isActive = user['status'] == 'active';
    final isAdminUser = user['role'] == 'admin';
    final roleColor = isAdminUser ? SismoColors.red : SismoColors.green;
    final stateColor = isActive ? SismoColors.green : SismoColors.grayAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: s.borderColor)),
      ),
      child: Row(
        children: [
          // Usuario (nombre + email)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: s.textPrimary)),
                const SizedBox(height: 2),
                Text(user['email'] ?? 'Sin email',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: s.textMuted)),
              ],
            ),
          ),
          // Rol: solo icono (no cabe el texto en pantalla de telefono)
          SizedBox(
            width: 38,
            child: Tooltip(
              message: isAdminUser ? 'Administrador' : 'Usuario',
              child: Icon(isAdminUser ? Icons.verified_user : Icons.person, size: 18, color: roleColor),
            ),
          ),
          // Estado: solo punto de color
          SizedBox(
            width: 46,
            child: Tooltip(
              message: isActive ? 'Activo' : 'Inactivo',
              child: Icon(Icons.circle, size: 11, color: stateColor),
            ),
          ),
          // Chips autorizados
          SizedBox(
            width: 44,
            child: Text('$chipsWithAccess/$totalUserChips',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: s.textSecondary)),
          ),
          // Editar
          SizedBox(
            width: 40,
            child: IconButton(
              onPressed: () => _editUser(user, allChipIds),
              icon: const Icon(Icons.edit, size: 18),
              color: SismoColors.blue,
              tooltip: 'Editar usuario',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
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
          title: const Row(children: [Icon(Icons.manage_accounts, size: 20), SizedBox(width: 8), Text('Editar Usuario')]),
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
                    DropdownMenuItem(value: 'user', child: Row(children: [Icon(Icons.person, size: 16), SizedBox(width: 8), Text('Usuario')])),
                    DropdownMenuItem(value: 'admin', child: Row(children: [Icon(Icons.verified_user, size: 16), SizedBox(width: 8), Text('Administrador')])),
                  ],
                  onChanged: (v) => setDialogState(() => role = v!),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(labelText: 'Estado', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'active', child: Row(children: [Icon(Icons.circle, size: 12, color: Color(0xFF28A745)), SizedBox(width: 8), Text('Activo')])),
                    DropdownMenuItem(value: 'inactive', child: Row(children: [Icon(Icons.circle, size: 12, color: Color(0xFF6C757D)), SizedBox(width: 8), Text('Inactivo')])),
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
                SismoFeedback.show(context, 'Guardando cambios...', color: const Color(0xFF0EA5E9), icon: Icons.sync);
                await widget.dbService.updateUser(uid, {
                  'displayName': nameCtrl.text.trim(),
                  'phone': phoneCtrl.text.trim(),
                  'role': role,
                  'status': status,
                  'chips': chips,
                });
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) SismoFeedback.show(context, 'Usuario actualizado', color: const Color(0xFF28A745), icon: Icons.check_circle);
                _loadData();
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF28A745)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.save, size: 16, color: Colors.white),
                SizedBox(width: 6),
                Text('Guardar', style: TextStyle(color: Colors.white)),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  void _createUser(List<String> allChipIds) {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final pass2Ctrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String role = 'user';
    String status = 'active';
    final chips = <String, bool>{for (var c in allChipIds) c: false};
    String? errorMsg;
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Row(children: [Icon(Icons.person_add, size: 20), SizedBox(width: 8), Text('Crear Usuario')]),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Contraseña * (mín. 6)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: pass2Ctrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Confirmar contraseña *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Teléfono', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: role,
                  decoration: const InputDecoration(labelText: 'Rol', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'user', child: Row(children: [Icon(Icons.person, size: 16), SizedBox(width: 8), Text('Usuario')])),
                    DropdownMenuItem(value: 'admin', child: Row(children: [Icon(Icons.verified_user, size: 16), SizedBox(width: 8), Text('Administrador')])),
                  ],
                  onChanged: (v) => setDialogState(() => role = v!),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(labelText: 'Estado', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'active', child: Row(children: [Icon(Icons.circle, size: 12, color: Color(0xFF28A745)), SizedBox(width: 8), Text('Activo')])),
                    DropdownMenuItem(value: 'inactive', child: Row(children: [Icon(Icons.circle, size: 12, color: Color(0xFF6C757D)), SizedBox(width: 8), Text('Inactivo')])),
                  ],
                  onChanged: (v) => setDialogState(() => status = v!),
                ),
                const SizedBox(height: 15),
                const Text('Permisos de Chips:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (allChipIds.isEmpty)
                  const Text('No hay dispositivos en el sistema.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF888888)))
                else
                  ...allChipIds.map((chipId) => SwitchListTile(
                        dense: true,
                        title: Text(chipId, style: const TextStyle(fontSize: 13)),
                        value: chips[chipId] ?? false,
                        activeColor: const Color(0xFF28A745),
                        onChanged: (v) => setDialogState(() => chips[chipId] = v),
                      )),
                if (errorMsg != null) ...[
                  const SizedBox(height: 10),
                  Text(errorMsg!, style: const TextStyle(color: Color(0xFFDC3545), fontSize: 13)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      final email = emailCtrl.text.trim();
                      final pass = passCtrl.text;
                      final pass2 = pass2Ctrl.text;
                      if (email.isEmpty || pass.isEmpty) {
                        setDialogState(() => errorMsg = 'Completa email y contraseña.');
                        return;
                      }
                      if (pass.length < 6) {
                        setDialogState(() => errorMsg = 'La contraseña debe tener al menos 6 caracteres.');
                        return;
                      }
                      if (pass != pass2) {
                        setDialogState(() => errorMsg = 'Las contraseñas no coinciden.');
                        return;
                      }
                      setDialogState(() {
                        saving = true;
                        errorMsg = null;
                      });
                      SismoFeedback.show(context, 'Creando usuario...', color: const Color(0xFF0EA5E9), icon: Icons.sync);
                      try {
                        final result = await widget.dbService.createUser(
                          email: email,
                          password: pass,
                          displayName: nameCtrl.text.trim(),
                          phone: phoneCtrl.text.trim(),
                          role: role,
                          status: status,
                          chips: chips,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          SismoFeedback.show(
                            context,
                            result == 'reactivated'
                                ? 'Usuario reactivado: $email'
                                : 'Usuario creado: $email',
                            color: const Color(0xFF28A745),
                            icon: result == 'reactivated' ? Icons.restore : Icons.check_circle,
                          );
                        }
                        _loadData();
                      } on FirebaseAuthException catch (e) {
                        const map = {
                          'email-already-in-use': 'Ese email ya está registrado.',
                          'invalid-email': 'El email no es válido.',
                          'weak-password': 'La contraseña es demasiado débil (mínimo 6 caracteres).',
                          'operation-not-allowed': 'El registro con email/contraseña está deshabilitado en Firebase.',
                        };
                        final m = map[e.code] ?? (e.message ?? 'No se pudo crear el usuario.');
                        if (mounted) SismoFeedback.show(context, m, color: const Color(0xFFEF4444), icon: Icons.error_outline);
                        setDialogState(() => saving = false);
                      } catch (e) {
                        if (mounted) SismoFeedback.show(context, 'No se pudo crear el usuario: $e', color: const Color(0xFFEF4444), icon: Icons.error_outline);
                        setDialogState(() => saving = false);
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF28A745)),
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Crear', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNodesSection() {
    final s = context.sismo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Gestión de Nodos',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: s.textPrimary)),
        const SizedBox(height: 4),
        Text('Configura nombre, zonas y estado de cada dispositivo',
            style: TextStyle(fontSize: 12, color: s.textMuted)),
        const SizedBox(height: 12),
        if (_nodes.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: s.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: s.borderColor),
            ),
            child: Center(
              child: Text('No hay nodos registrados', style: TextStyle(color: s.textMuted)),
            ),
          )
        else
          ..._nodes.map(_nodeCard),
      ],
    );
  }

  Widget _nodeCard(Map<String, dynamic> node) {
    final s = context.sismo;
    final chipId = node['chipId'] as String;
    final name = node['name'] as String;
    final enabled = node['enabled'] == true;
    final zones = (node['zones'] as Map?) ?? {};
    int zonesActive = 0;
    for (var i = 1; i <= 5; i++) {
      final z = zones['c$i'] as Map?;
      if (z == null || z['enabled'] != false) zonesActive++;
    }
    final lastSeen = (node['lastSeen'] as int?) ?? 0;
    final connected = lastSeen != 0 && (DateTime.now().millisecondsSinceEpoch - lastSeen) < 300000;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: s.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: s.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF00C9A7), Color(0xFF0EA5E9)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.router, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(name,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: s.textPrimary)),
                    ),
                    if (!enabled) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C757D).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Deshabilitado',
                            style: TextStyle(fontSize: 10, color: Color(0xFF6C757D), fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text('ID: $chipId',
                    style: TextStyle(fontSize: 11, color: s.textMuted, fontFamily: 'monospace')),
                const SizedBox(height: 2),
                Text('$zonesActive/5 zonas activas · ${connected ? "Online" : "Offline"}',
                    style: TextStyle(fontSize: 11, color: connected ? SismoColors.green : s.textMuted)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _editNode(node),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C9A7),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.settings, color: Colors.white, size: 14),
              SizedBox(width: 4),
              Text('Configurar', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ]),
          ),
        ],
      ),
    );
  }

  void _editNode(Map<String, dynamic> node) {
    final chipId = node['chipId'] as String;
    final nameCtrl = TextEditingController(text: node['name'] as String);
    bool enabled = node['enabled'] == true;
    final rawZones = (node['zones'] as Map?) ?? {};
    final zoneNameCtrls = <String, TextEditingController>{};
    final zoneEnabled = <String, bool>{};
    for (var i = 1; i <= 5; i++) {
      final zId = 'c$i';
      final z = rawZones[zId] as Map?;
      zoneNameCtrls[zId] = TextEditingController(text: (z?['name'] ?? 'Zona $i').toString());
      zoneEnabled[zId] = z == null ? true : (z['enabled'] != false);
    }
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Row(children: [Icon(Icons.router, size: 20), SizedBox(width: 8), Text('Configurar Nodo')]),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ID: $chipId',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF666666), fontFamily: 'monospace')),
                const SizedBox(height: 14),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre del dispositivo', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 6),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Dispositivo activo'),
                  value: enabled,
                  activeColor: const Color(0xFF28A745),
                  onChanged: (v) => setD(() => enabled = v),
                ),
                const Divider(),
                const Text('Zonas (cercos)', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...List.generate(5, (idx) {
                  final zId = 'c${idx + 1}';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: zoneNameCtrls[zId],
                            decoration: InputDecoration(
                              labelText: 'Zona ${idx + 1}',
                              border: const OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        Switch(
                          value: zoneEnabled[zId]!,
                          activeColor: const Color(0xFF28A745),
                          onChanged: (v) => setD(() => zoneEnabled[zId] = v),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      setD(() => saving = true);
                      SismoFeedback.show(context, 'Guardando configuración...', color: const Color(0xFF0EA5E9), icon: Icons.sync);
                      final zones = <String, dynamic>{};
                      for (var i = 1; i <= 5; i++) {
                        final zId = 'c$i';
                        final zn = zoneNameCtrls[zId]!.text.trim();
                        zones[zId] = {
                          'name': zn.isEmpty ? 'Zona $i' : zn,
                          'enabled': zoneEnabled[zId],
                        };
                      }
                      try {
                        await widget.dbService.saveNodeConfig(
                          chipId,
                          name: nameCtrl.text.trim().isEmpty ? chipId : nameCtrl.text.trim(),
                          enabled: enabled,
                          zones: zones,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) SismoFeedback.show(context, 'Nodo guardado', color: const Color(0xFF28A745), icon: Icons.check_circle);
                        _loadData();
                      } catch (e) {
                        if (mounted) {
                          SismoFeedback.show(context, 'No se pudo guardar: $e', color: const Color(0xFFEF4444), icon: Icons.error_outline);
                        }
                        setD(() => saving = false);
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF28A745)),
              child: saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Guardar', style: TextStyle(color: Colors.white)),
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
  final IconData icon;
  final String label, value, subtitle;
  final Color borderColor;

  const _StatCard(this.icon, this.label, this.value, this.subtitle, this.borderColor);

  @override
  Widget build(BuildContext context) {
    final s = context.sismo;
    return Container(
      width: 150,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: s.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          top: BorderSide(color: borderColor, width: 3),
          left: BorderSide(color: s.borderColor),
          right: BorderSide(color: s.borderColor),
          bottom: BorderSide(color: s.borderColor),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: s.textMuted),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 12, color: s.textMuted, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: s.textPrimary)),
          const SizedBox(height: 5),
          Text(subtitle, style: TextStyle(fontSize: 11, color: borderColor)),
        ],
      ),
    );
  }
}
