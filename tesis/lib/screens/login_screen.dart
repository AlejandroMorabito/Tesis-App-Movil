import 'package:flutter/material.dart';
import '../services/auth_service.dart';

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
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
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
      setState(() {
        _errorMessage = 'Por favor completa todos los campos';
        _successMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await _authService.signIn(email, password);
      // Navigation is handled by AuthWrapper
    } catch (e) {
      String msg = 'Error de autenticación';
      final code = e.toString();
      if (code.contains('user-not-found')) {
        msg = 'Usuario no encontrado';
      } else if (code.contains('wrong-password') || code.contains('invalid-credential')) {
        msg = 'Contraseña incorrecta';
      } else if (code.contains('invalid-email')) {
        msg = 'Correo electrónico inválido';
      } else if (code.contains('user-disabled')) {
        msg = 'Cuenta deshabilitada';
      } else if (code.contains('too-many-requests')) {
        msg = 'Demasiados intentos. Intenta más tarde';
      }
      setState(() {
        _errorMessage = msg;
        _passwordController.clear();
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Ingresa tu correo electrónico para recuperar la contraseña';
        _successMessage = null;
      });
      return;
    }

    try {
      await _authService.resetPassword(email);
      setState(() {
        _successMessage = '📧 Se envió un enlace de recuperación a $email. Revisa tu bandeja de entrada (y spam).';
        _errorMessage = null;
      });
    } catch (e) {
      String msg = 'Error al enviar correo de recuperación';
      final code = e.toString();
      if (code.contains('user-not-found')) {
        msg = 'No existe una cuenta con ese correo electrónico';
      } else if (code.contains('invalid-email')) {
        msg = 'El correo electrónico no es válido';
      } else if (code.contains('too-many-requests')) {
        msg = 'Demasiados intentos. Espera unos minutos e intenta de nuevo';
      }
      setState(() {
        _errorMessage = msg;
        _successMessage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -0.05),
                  end: Offset.zero,
                ).animate(_fadeAnim),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 40,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🔐', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 10),
                      const Text(
                        'Dashboard de Alarmas',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Acceso con Firebase Authentication',
                        style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
                      ),
                      const SizedBox(height: 30),

                      // Email
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Correo Electrónico',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[800])),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'usuario@ejemplo.com',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFF667EEA), width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Password
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Contraseña',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[800])),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        onSubmitted: (_) => _login(),
                        decoration: InputDecoration(
                          hintText: 'Ingresa tu contraseña',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFF667EEA), width: 2),
                          ),
                          suffixIcon: IconButton(
                            icon: Text(_obscurePassword ? '👁️' : '🙈', style: const TextStyle(fontSize: 20)),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),

                      // Login button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ).copyWith(
                            backgroundColor: WidgetStateProperty.resolveWith((states) {
                              if (states.contains(WidgetState.disabled)) {
                                return const Color(0xFF667EEA).withOpacity(0.7);
                              }
                              return null;
                            }),
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              child: Text(
                                _isLoading ? '⏳ Autenticando...' : '🔑 Iniciar Sesión',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Reset password
                      const SizedBox(height: 15),
                      GestureDetector(
                        onTap: _resetPassword,
                        child: const Text(
                          '🔓 ¿Olvidaste tu contraseña?',
                          style: TextStyle(color: Color(0xFF667EEA), fontSize: 14),
                        ),
                      ),

                      // Success message
                      if (_successMessage != null) ...[
                        const SizedBox(height: 15),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4EDDA),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: const Color(0xFFC3E6CB)),
                          ),
                          child: Text(
                            _successMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Color(0xFF155724), fontSize: 14),
                          ),
                        ),
                      ],

                      // Error message
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 15),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEEEE),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: const Color(0xFFFFCCCC)),
                          ),
                          child: Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Color(0xFFDC3545), fontSize: 14),
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),
                      const Text(
                        'Usa las credenciales registradas en Firebase Authentication',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Color(0xFF666666)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
