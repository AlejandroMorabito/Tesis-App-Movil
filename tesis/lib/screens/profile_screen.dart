import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';

class ProfileScreen extends StatefulWidget {
  final DatabaseService dbService;
  const ProfileScreen({super.key, required this.dbService});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  bool _isEditing = false;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();
  String? _passMsg;
  Color _passMsgColor = Colors.red;
  Map<String, dynamic>? _userData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    _userData = await widget.dbService.getUserData(uid);
    _nameController.text = _userData?['displayName'] ?? '';
    _phoneController.text = _userData?['phone'] ?? '';
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveProfile() async {
    await widget.dbService.updateProfile(
      displayName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
    );
    setState(() => _isEditing = false);
    _loadProfile();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Perfil actualizado'), backgroundColor: Color(0xFF28A745)),
      );
    }
  }

  Future<void> _changePassword() async {
    final newPass = _newPassController.text;
    final confirm = _confirmPassController.text;

    if (newPass.isEmpty || confirm.isEmpty) {
      setState(() { _passMsg = 'Completa ambos campos'; _passMsgColor = Colors.red; });
      return;
    }
    if (newPass != confirm) {
      setState(() { _passMsg = 'Las contraseñas no coinciden'; _passMsgColor = Colors.red; });
      return;
    }
    if (newPass.length < 6) {
      setState(() { _passMsg = 'La contraseña debe tener al menos 6 caracteres'; _passMsgColor = Colors.red; });
      return;
    }

    try {
      await _authService.changePassword(newPass);
      setState(() {
        _passMsg = '✅ Contraseña actualizada correctamente';
        _passMsgColor = const Color(0xFF28A745);
      });
      _newPassController.clear();
      _confirmPassController.clear();
    } catch (e) {
      final code = e.toString();
      if (code.contains('requires-recent-login')) {
        setState(() {
          _passMsg = 'Sesión expirada. Cierra sesión, vuelve a entrar e intenta de nuevo';
          _passMsgColor = Colors.red;
        });
      } else {
        setState(() { _passMsg = 'Error: $e'; _passMsgColor = Colors.red; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = FirebaseAuth.instance.currentUser!;
    final displayName = _userData?['displayName']?.toString().isNotEmpty == true
        ? _userData!['displayName'] : user.email!.split('@')[0];
    final initial = displayName.toString()[0].toUpperCase();
    final role = _userData?['role'] ?? 'user';
    final phone = _userData?['phone'] ?? 'No registrado';
    final status = _userData?['status'] ?? 'active';
    final chips = (_userData?['chips'] as Map?) ?? {};
    final chipsWithAccess = chips.values.where((v) => v == true).length;

    return Scaffold(
      backgroundColor: const Color(0xFF0F3460),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Perfil de Usuario', style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with gradient
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(30),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
              ),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.9),
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 25, offset: const Offset(0, 8))],
                    ),
                    child: Center(
                      child: Text(initial,
                          style: const TextStyle(color: Color(0xFF667EEA), fontWeight: FontWeight.bold, fontSize: 32)),
                    ),
                  ),
                  const SizedBox(height: 15),
                  if (_isEditing)
                    SizedBox(
                      width: 200,
                      child: TextField(
                        controller: _nameController,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.2),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        ),
                      ),
                    )
                  else
                    Text(displayName.toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 5),
                  Text(user.email!, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                    decoration: BoxDecoration(
                      color: role == 'admin' ? const Color(0xFFDC3545).withOpacity(0.9) : const Color(0xFF28A745).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      role == 'admin' ? '👑 ADMINISTRADOR' : '👤 USUARIO',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isEditing) ...[
                        ElevatedButton.icon(
                          onPressed: _saveProfile,
                          icon: const Text('💾'),
                          label: const Text('Guardar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF28A745),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton.icon(
                          onPressed: () => setState(() => _isEditing = false),
                          icon: const Text('❌'),
                          label: const Text('Cancelar', style: TextStyle(color: Colors.white)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                      ] else
                        ElevatedButton.icon(
                          onPressed: () => setState(() => _isEditing = true),
                          icon: const Text('✏️'),
                          label: const Text('Editar Perfil'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3498DB),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                children: [
                  // Personal info
                  _SectionCard(
                    icon: '👤',
                    title: 'Información Personal',
                    children: [
                      _InfoItem('📧 Correo', user.email!),
                      if (_isEditing)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: TextField(
                            controller: _phoneController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: '📱 Teléfono',
                              labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.1),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                        )
                      else
                        _InfoItem('📱 Teléfono', phone),
                      _InfoItem('🔰 Rol', role == 'admin' ? 'Administrador' : 'Usuario'),
                      _InfoItem('📊 Estado', status == 'active' ? '🟢 Activo' : '🔴 Inactivo'),
                      _InfoItem('📱 Dispositivos', '$chipsWithAccess/${chips.length} autorizados'),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Change password
                  _SectionCard(
                    icon: '🔑',
                    title: 'Cambiar Contraseña',
                    children: [
                      TextField(
                        controller: _newPassController,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Nueva contraseña',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _confirmPassController,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Confirmar contraseña',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        ),
                      ),
                      if (_passMsg != null) ...[
                        const SizedBox(height: 10),
                        Text(_passMsg!, style: TextStyle(color: _passMsgColor, fontSize: 13)),
                      ],
                      const SizedBox(height: 15),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _changePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFC107),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('🔐 Actualizar Contraseña',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }
}

class _SectionCard extends StatelessWidget {
  final String icon, title;
  final List<Widget> children;

  const _SectionCard({required this.icon, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF4CD964), Color(0xFF28A745)]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(child: Text(icon, style: const TextStyle(fontSize: 16))),
              ),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
          const Divider(color: Colors.white10, height: 30),
          ...children,
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label, value;
  const _InfoItem(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14)),
        ],
      ),
    );
  }
}
