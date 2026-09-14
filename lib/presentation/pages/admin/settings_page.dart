import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../domain/user.dart';
import '../../../infrastructure/auth_provider.dart';
import '../../../infrastructure/auth_service.dart';
import '../../../infrastructure/http_client.dart';
import '../../../config/api_config.dart';
import '../../widgets/dashboard_layout.dart';
import 'package:go_router/go_router.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _currentPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _savingPass = false;
  String? _passError;
  String? _passSuccess;
  bool _showCurrent = false, _showNew = false, _showConfirm = false;
  User? _liveUser;
  bool _loadingUser = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadUser());
  }

  Future<void> _loadUser() async {
    final userId = context.read<AuthProvider>().user?.id ?? 0;
    if (userId == 0) {
      setState(() => _loadingUser = false);
      return;
    }
    try {
      final u = await getUserById(userId);
      setState(() { _liveUser = u; _loadingUser = false; });
    } catch (_) {
      setState(() => _loadingUser = false);
    }
  }

  Future<void> _changePassword() async {
    setState(() { _passError = null; _passSuccess = null; });
    if (_currentPassCtrl.text.isEmpty || _newPassCtrl.text.isEmpty) {
      setState(() => _passError = 'Todos los campos son requeridos'); return;
    }
    if (_newPassCtrl.text != _confirmPassCtrl.text) {
      setState(() => _passError = 'Las contraseñas no coinciden'); return;
    }
    final userId = context.read<AuthProvider>().user?.id ?? 0;
    setState(() => _savingPass = true);
    try {
      await httpClient.patch(ApiEndpoints.changePassword(userId), data: {'currentPassword': _currentPassCtrl.text, 'newPassword': _newPassCtrl.text});
      _currentPassCtrl.clear(); _newPassCtrl.clear(); _confirmPassCtrl.clear();
      setState(() { _passSuccess = 'Contraseña actualizada correctamente'; _savingPass = false; });
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) setState(() => _passSuccess = null);
    } catch (_) {
      setState(() { _passError = 'Contraseña actual incorrecta'; _savingPass = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = _liveUser ?? auth.user;
    return DashboardLayout(
      currentRoute: '/configuracion',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Configuración', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: kTextPrimary)),
          const SizedBox(height: 4),
          const Text('Gestiona tu perfil y preferencias', style: TextStyle(color: kTextSecondary, fontSize: 14)),
          const SizedBox(height: 24),
          Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Perfil', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kTextPrimary)),
            const SizedBox(height: 16),
            Row(children: [
              if (_loadingUser)
                const CircleAvatar(backgroundColor: kPrimary, radius: 28, child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
              else
                CircleAvatar(backgroundColor: kPrimary, radius: 28, child: Text(user?.firstName.isNotEmpty == true ? user!.firstName[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold))),
              const SizedBox(width: 16),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(user?.fullName ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kTextPrimary)),
                Text(user?.email ?? '', style: const TextStyle(fontSize: 14, color: kTextSecondary)),
                const SizedBox(height: 4),
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: kNavy, borderRadius: BorderRadius.circular(12)), child: Text(user?.role ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white))),
              ]),
            ]),
          ]))),
          const SizedBox(height: 16),
          Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Cambiar Contraseña', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kTextPrimary)),
            const SizedBox(height: 16),
            _PassField(label: 'Contraseña actual', ctrl: _currentPassCtrl, show: _showCurrent, onToggle: () => setState(() => _showCurrent = !_showCurrent)),
            const SizedBox(height: 12),
            _PassField(label: 'Nueva contraseña', ctrl: _newPassCtrl, show: _showNew, onToggle: () => setState(() => _showNew = !_showNew)),
            const SizedBox(height: 12),
            _PassField(label: 'Confirmar contraseña', ctrl: _confirmPassCtrl, show: _showConfirm, onToggle: () => setState(() => _showConfirm = !_showConfirm)),
            if (_passError != null) ...[
              const SizedBox(height: 12),
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFFECACA))),
                child: Row(children: [const Icon(Icons.error_outline, color: kError, size: 16), const SizedBox(width: 8), Expanded(child: Text(_passError!, style: const TextStyle(color: kError, fontSize: 13)))]),
              ),
            ],
            if (_passSuccess != null) ...[
              const SizedBox(height: 12),
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFBBF7D0))),
                child: Row(children: [const Icon(Icons.check_circle_outline, color: kSuccess, size: 16), const SizedBox(width: 8), Expanded(child: Text(_passSuccess!, style: const TextStyle(color: kSuccess, fontSize: 13)))]),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: _savingPass ? null : _changePassword,
              child: _savingPass ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Guardar Contraseña'),
            )),
          ]))),
          const SizedBox(height: 16),
          Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Sesión', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kTextPrimary)),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: OutlinedButton.icon(
              onPressed: () async { await auth.logout(); if (context.mounted) context.go('/login'); },
              icon: const Icon(Icons.logout, color: kError),
              label: const Text('Cerrar sesión', style: TextStyle(color: kError)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: kError)),
            )),
          ]))),
        ]),
      ),
    );
  }
}

class _PassField extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final bool show;
  final VoidCallback onToggle;
  const _PassField({required this.label, required this.ctrl, required this.show, required this.onToggle});
  @override
  Widget build(BuildContext context) => TextField(
    controller: ctrl,
    obscureText: !show,
    decoration: InputDecoration(
      labelText: label,
      suffixIcon: IconButton(icon: Icon(show ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: kTextSecondary), onPressed: onToggle),
    ),
  );
}
