import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/sismo_theme.dart';
import '../main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();

    // Si un bloqueo dejó un mensaje pendiente (cuenta borrada), mostrarlo
    if (AuthService.pendingLoginError != null) {
      _errorMessage = AuthService.pendingLoginError;
      AuthService.pendingLoginError = null;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() { _errorMessage = 'Por favor completa todos los campos'; _successMessage = null; });
      return;
    }
    setState(() { _isLoading = true; _errorMessage = null; _successMessage = null; });
    try {
      await _authService.signIn(email, password);
    } catch (e) {
      String msg = 'Error de autenticación';
      final code = e.toString();
      if (code.contains('user-deleted')) { msg = 'Cuenta borrada. Contacta al administrador.'; AuthService.pendingLoginError = null; }
      else if (code.contains('user-not-found')) msg = 'Usuario no encontrado';
      else if (code.contains('wrong-password') || code.contains('invalid-credential')) msg = 'Contraseña incorrecta';
      else if (code.contains('invalid-email')) msg = 'Correo electrónico inválido';
      else if (code.contains('too-many-requests')) msg = 'Demasiados intentos. Intenta más tarde';
      if (mounted) setState(() { _errorMessage = msg; _passwordController.clear(); });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() { _errorMessage = 'Ingresa tu correo para recuperar contraseña'; _successMessage = null; });
      return;
    }
    try {
      await _authService.resetPassword(email);
      setState(() { _successMessage = 'Se envió un enlace de recuperación a $email'; _errorMessage = null; });
    } catch (e) {
      setState(() { _errorMessage = 'Error al enviar correo de recuperación'; _successMessage = null; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.sismo;
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1923) : const Color(0xFFF1F5F9),
      body: Stack(
        children: [
          // Theme toggle
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 16,
            child: _buildThemeToggle(context),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: s.bgCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: s.borderColor),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.1), blurRadius: 30, offset: const Offset(0, 10))],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo
                      Container(
                        width: 56, height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(colors: [SismoColors.teal, SismoColors.blue]),
                        ),
                        child: const Icon(Icons.shield, color: Colors.white, size: 28),
                      ),
                      const SizedBox(height: 16),
                      Text('SISMO', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: s.textPrimary, letterSpacing: 0.5)),
                      const SizedBox(height: 4),
                      Text('Security Dashboard — Acceso Seguro', style: TextStyle(fontSize: 13, color: s.textMuted)),
                      const SizedBox(height: 28),

                      // Email
                      Align(alignment: Alignment.centerLeft, child: Text('Correo Electrónico', style: TextStyle(fontWeight: FontWeight.w500, color: s.textPrimary, fontSize: 14))),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(color: s.textPrimary),
                        decoration: _inputDecoration(context, 'usuario@ejemplo.com'),
                      ),
                      const SizedBox(height: 18),

                      // Password
                      Align(alignment: Alignment.centerLeft, child: Text('Contraseña', style: TextStyle(fontWeight: FontWeight.w500, color: s.textPrimary, fontSize: 14))),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        onSubmitted: (_) => _login(),
                        style: TextStyle(color: s.textPrimary),
                        decoration: _inputDecoration(context, 'Ingresa tu contraseña').copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: s.textMuted, size: 20),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Login button
                      SizedBox(
                        width: double.infinity, height: 48,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [SismoColors.teal, SismoColors.blue]),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text(
                              _isLoading ? 'Autenticando...' : 'Iniciar Sesión',
                              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),

                      // Forgot password
                      const SizedBox(height: 14),
                      GestureDetector(
                        onTap: _resetPassword,
                        child: Text('¿Olvidaste tu contraseña?', style: TextStyle(color: SismoColors.teal, fontSize: 13)),
                      ),

                      // Messages
                      if (_successMessage != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: SismoColors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: SismoColors.green.withOpacity(0.2)),
                          ),
                          child: Text(_successMessage!, textAlign: TextAlign.center, style: const TextStyle(color: SismoColors.green, fontSize: 13)),
                        ),
                      ],
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: SismoColors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: SismoColors.red.withOpacity(0.2)),
                          ),
                          child: Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: SismoColors.red, fontSize: 13)),
                        ),
                      ],
                      const SizedBox(height: 18),
                      Text('Credenciales registradas en Firebase', style: TextStyle(fontSize: 11, color: s.textMuted)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeToggle(BuildContext context) {
    final isDark = context.isDark;
    return GestureDetector(
      onTap: () => SismoApp.toggleTheme(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: context.sismo.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.sismo.borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wb_sunny, size: 16, color: isDark ? context.sismo.textMuted : SismoColors.amber),
            const SizedBox(width: 6),
            Container(
              width: 36, height: 20,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: isDark ? const Color(0xFF334155) : SismoColors.blue,
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 16, height: 16, margin: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.dark_mode, size: 16, color: isDark ? SismoColors.blue : context.sismo.textMuted),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(BuildContext context, String hint) {
    final s = context.sismo;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: s.textMuted, fontSize: 14),
      filled: true,
      fillColor: s.bgInset,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: s.borderColor)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: s.borderColor)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: SismoColors.teal, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}