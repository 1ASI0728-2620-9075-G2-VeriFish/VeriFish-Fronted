import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme.dart';
import '../../../infrastructure/auth_provider.dart';
import '../../../infrastructure/auth_service.dart' as svc;
import '../../../infrastructure/farm_service.dart';
import '../../../infrastructure/notification_service.dart';
import '../../widgets/operator_layout.dart';

class OperatorProfilePage extends StatefulWidget {
  const OperatorProfilePage({super.key});
  @override
  State<OperatorProfilePage> createState() => _State();
}

class _State extends State<OperatorProfilePage> {
  Farm? _farm;
  int _alertCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = context.read<AuthProvider>().user?.id ?? 0;
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        getUserFarm(userId),
        getNotifications(userId),
      ]);
      if (mounted) {
        setState(() {
          _farm = results[0] as Farm?;
          final notifs = results[1] as List;
          _alertCount = notifs.length;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openChangePassword() {
    final userId = context.read<AuthProvider>().user?.id ?? 0;
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    String? error;
    bool saving = false;
    bool success = false;
    bool showCurrent = false;
    bool showNew = false;
    bool showConfirm = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setModal) {
          Future<void> submit() async {
            final current = currentCtrl.text.trim();
            final nw = newCtrl.text.trim();
            final confirm = confirmCtrl.text.trim();
            if (current.isEmpty || nw.isEmpty || confirm.isEmpty) {
              setModal(() => error = 'Completa todos los campos');
              return;
            }
            if (nw.length < 6) {
              setModal(() => error = 'La contraseña debe tener al menos 6 caracteres');
              return;
            }
            if (nw != confirm) {
              setModal(() => error = 'Las contraseñas nuevas no coinciden');
              return;
            }
            setModal(() { saving = true; error = null; });
            try {
              await svc.changePassword(
                userId: userId,
                currentPassword: current,
                newPassword: nw,
              );
              setModal(() { saving = false; success = true; });
              await Future.delayed(const Duration(seconds: 1));
              if (ctx.mounted) Navigator.pop(ctx);
            } catch (_) {
              setModal(() {
                saving = false;
                error = 'Contraseña actual incorrecta o error en el servidor';
              });
            }
          }

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Text('Cambiar Contraseña',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: kNavy)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: kTextSecondary),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ]),
                const SizedBox(height: 16),
                _PwField(
                  label: 'Contraseña actual',
                  controller: currentCtrl,
                  obscure: !showCurrent,
                  onToggle: () => setModal(() => showCurrent = !showCurrent),
                ),
                const SizedBox(height: 12),
                _PwField(
                  label: 'Nueva contraseña',
                  controller: newCtrl,
                  obscure: !showNew,
                  onToggle: () => setModal(() => showNew = !showNew),
                ),
                const SizedBox(height: 12),
                _PwField(
                  label: 'Confirmar nueva contraseña',
                  controller: confirmCtrl,
                  obscure: !showConfirm,
                  onToggle: () => setModal(() => showConfirm = !showConfirm),
                ),
                if (error != null) ...[
                  const SizedBox(height: 10),
                  Text(error!, style: const TextStyle(color: kError, fontSize: 13)),
                ],
                if (success) ...[
                  const SizedBox(height: 10),
                  const Text('Contraseña actualizada exitosamente',
                      style: TextStyle(color: kSuccess, fontSize: 13, fontWeight: FontWeight.w600)),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: saving ? null : submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: saving
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Actualizar contraseña',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
              ]),
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final initials = user != null && user.firstName.isNotEmpty
        ? '${user.firstName[0]}${user.lastName.isNotEmpty ? user.lastName[0] : ''}'.toUpperCase()
        : '?';
    return OperatorLayout(
      currentRoute: '/op/profile',
      child: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: kPrimary))
            : ListView(
                children: [
                  Container(
                    color: kSurface,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Mi Perfil',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kNavy)),
                        if (_farm != null)
                          Row(children: [
                            Text(_farm!.name,
                                style: const TextStyle(fontSize: 13, color: kTextSecondary)),
                            const SizedBox(width: 4),
                            const Icon(Icons.location_on_outlined, size: 16, color: kTextSecondary),
                          ]),
                      ],
                    ),
                  ),
                  Container(
                    color: kSurface,
                    child: Column(children: [
                      Container(height: 100, color: kNavy),
                      Transform.translate(
                        offset: const Offset(0, -40),
                        child: Column(children: [
                          Stack(alignment: Alignment.bottomRight, children: [
                            Container(
                              width: 90, height: 90,
                              decoration: BoxDecoration(
                                color: kPrimary,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: kSurface, width: 3),
                              ),
                              child: Center(
                                child: Text(initials,
                                    style: const TextStyle(
                                        fontSize: 32, fontWeight: FontWeight.bold,
                                        color: Colors.white)),
                              ),
                            ),
                            Container(
                              width: 28, height: 28,
                              decoration: BoxDecoration(
                                color: kPrimary,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: kSurface, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt_outlined,
                                  size: 14, color: Colors.white),
                            ),
                          ]),
                          const SizedBox(height: 8),
                          Text(
                            user != null ? '${user.firstName} ${user.lastName}' : '',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold, color: kNavy),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: kSuccess.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.verified_outlined, size: 14, color: kSuccess),
                              const SizedBox(width: 5),
                              const Text('OPERATOR',
                                  style: TextStyle(
                                      fontSize: 12, fontWeight: FontWeight.w700,
                                      color: kSuccess, letterSpacing: 0.5)),
                            ]),
                          ),
                        ]),
                      ),
                      Transform.translate(
                        offset: const Offset(0, -24),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(children: [
                            _InfoRow(
                              icon: Icons.email_outlined,
                              label: 'CORREO ELECTRÓNICO',
                              value: user?.email ?? '--',
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: kBackground,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(children: [
                                Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(
                                    color: kPrimary.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.notifications_outlined, size: 20, color: kPrimary),
                                ),
                                const SizedBox(width: 12),
                                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  const Text('ALERTAS RECIBIDAS',
                                      style: TextStyle(fontSize: 10, color: kTextSecondary,
                                          letterSpacing: 0.8, fontWeight: FontWeight.w600)),
                                  Text(_alertCount.toString().padLeft(2, '0'),
                                      style: const TextStyle(fontSize: 20,
                                          fontWeight: FontWeight.bold, color: kNavy)),
                                ]),
                              ]),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.lock_outline, size: 18, color: Colors.white),
                                label: const Text('Cambiar Contraseña',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kPrimary,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: _openChangePassword,
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: TextButton.icon(
                                icon: const Icon(Icons.logout, size: 16, color: kError),
                                label: const Text('Cerrar sesión',
                                    style: TextStyle(color: kError, fontWeight: FontWeight.w600)),
                                style: TextButton.styleFrom(
                                  backgroundColor: const Color(0xFFFEF2F2),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () async {
                                  await context.read<AuthProvider>().logout();
                                  if (context.mounted) context.go('/login');
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                          ]),
                        ),
                      ),
                    ]),
                  ),
                ],
              ),
      ),
    );
  }
}

class _PwField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;
  const _PwField({required this.label, required this.controller, required this.obscure, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 12, color: kTextSecondary, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          filled: true,
          fillColor: kBackground,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kBorder)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kBorder)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kPrimary)),
          suffixIcon: IconButton(
            icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                size: 18, color: kTextSecondary),
            onPressed: onToggle,
          ),
        ),
      ),
    ]);
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: kBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 18, color: kTextSecondary),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(fontSize: 10, color: kTextSecondary,
                  letterSpacing: 0.8, fontWeight: FontWeight.w600)),
          Text(value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kNavy)),
        ]),
      ]),
    );
  }
}
