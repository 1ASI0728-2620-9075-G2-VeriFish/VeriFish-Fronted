import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../infrastructure/auth_provider.dart';
import '../../../infrastructure/fcm_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _usernameCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _farmTokenCtrl = TextEditingController();
  bool _showPassword = false;
  late String _role;
  late bool _isMobile;

  @override
  void initState() {
    super.initState();
    _isMobile = !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);
    _role = _isMobile ? 'OPERATOR' : 'ADMIN';
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _farmTokenCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.register(
      username: _usernameCtrl.text.trim(),
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      role: _role,
      farmToken: _role == 'OPERATOR' ? _farmTokenCtrl.text.trim() : null,
    );
    if (ok && mounted) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        FcmService.initializeAndSendToken(user.id);
      }
      context.go(user?.role == 'OPERATOR' ? '/op/home' : '/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: kBackground,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(36),
            decoration: BoxDecoration(
              color: kSurface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 24, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: Image.asset('assets/images/yaku-logo.png', height: 100)),
                const SizedBox(height: 20),
                _Label('USERNAME'),
                const SizedBox(height: 6),
                TextField(
                  controller: _usernameCtrl,
                  decoration: const InputDecoration(
                    hintText: 'User123',
                    prefixIcon: Icon(Icons.person_outline, size: 18, color: Color(0xFF94A3B8)),
                  ),
                ),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _Label('FIRSTNAME'),
                    const SizedBox(height: 6),
                    TextField(controller: _firstNameCtrl, decoration: const InputDecoration(hintText: 'Carlos')),
                  ])),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _Label('LASTNAME'),
                    const SizedBox(height: 6),
                    TextField(controller: _lastNameCtrl, decoration: const InputDecoration(hintText: 'Rodriguez')),
                  ])),
                ]),
                const SizedBox(height: 14),
                _Label('EMAIL'),
                const SizedBox(height: 6),
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'usuario@empresa.pe',
                    prefixIcon: Icon(Icons.email_outlined, size: 18, color: Color(0xFF94A3B8)),
                  ),
                ),
                const SizedBox(height: 14),
                _Label('CONTRASEÑA'),
                const SizedBox(height: 6),
                TextField(
                  controller: _passwordCtrl,
                  obscureText: !_showPassword,
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    prefixIcon: const Icon(Icons.lock_outline, size: 18, color: Color(0xFF94A3B8)),
                    suffixIcon: IconButton(
                      icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: const Color(0xFF94A3B8)),
                      onPressed: () => setState(() => _showPassword = !_showPassword),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _Label('ROL ASIGNADO'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: kPrimary.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(_isMobile ? Icons.engineering_outlined : Icons.admin_panel_settings_outlined, color: kPrimary),
                      const SizedBox(width: 10),
                      Text(
                        _role == 'OPERATOR' ? 'Operador (App Móvil)' : 'Administrador (Web/PC)',
                        style: const TextStyle(color: kPrimaryDark, fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                if (_role == 'OPERATOR') ...[
                  const SizedBox(height: 14),
                  _Label('TOKEN DE GRANJA'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _farmTokenCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Ingresa el token de la granja',
                      prefixIcon: Icon(Icons.key_outlined, size: 18, color: Color(0xFF94A3B8)),
                    ),
                  ),
                ],
                if (auth.error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFFECACA))),
                    child: Row(children: [
                      const Icon(Icons.error_outline, color: kError, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(auth.error!, style: const TextStyle(color: kError, fontSize: 13))),
                    ]),
                  ),
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: auth.loading ? null : _submit,
                  child: auth.loading
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Registrarse'),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('¿Ya tienes cuenta? ', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                    GestureDetector(
                      onTap: () => context.go('/login'),
                      child: const Text('Iniciar Sesión', style: TextStyle(color: kPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  final String label, value;
  final bool selected;
  final VoidCallback onTap;
  const _RoleButton({required this.label, required this.value, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF0F9FF) : kSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? kPrimary : kBorder, width: selected ? 2 : 1),
        ),
        child: Center(child: Text(label, style: TextStyle(color: selected ? kPrimaryDark : const Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 13))),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.0, color: Color(0xFF64748B)));
}
