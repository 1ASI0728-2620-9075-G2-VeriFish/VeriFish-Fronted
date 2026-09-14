import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../infrastructure/auth_provider.dart';
import '../../../infrastructure/farm_service.dart';
import '../../../infrastructure/http_client.dart';
import '../../../config/api_config.dart';
import '../../widgets/dashboard_layout.dart';

class _Operator {
  final int id;
  final String username, firstName, lastName, email;
  const _Operator({required this.id, required this.username, required this.firstName, required this.lastName, required this.email});
  String get fullName => '$firstName $lastName'.trim();
  factory _Operator.fromJson(Map<String, dynamic> j) => _Operator(id: j['id'] as int, username: j['username']?.toString() ?? '', firstName: j['firstName']?.toString() ?? '', lastName: j['lastName']?.toString() ?? '', email: j['email']?.toString() ?? '');
}

class OperatorsPage extends StatefulWidget {
  const OperatorsPage({super.key});
  @override
  State<OperatorsPage> createState() => _OperatorsPageState();
}

class _OperatorsPageState extends State<OperatorsPage> {
  List<_Operator> _operators = [];
  bool _loading = true;
  int? _farmId;
  String _farmToken = '';
  bool _generatingToken = false;
  bool _copied = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final userId = context.read<AuthProvider>().user?.id ?? 0;
    try {
      final farm = await getUserFarm(userId);
      if (farm == null) { setState(() => _loading = false); return; }
      _farmId = farm.id;
      final res = await httpClient.get(ApiEndpoints.usersByFarm(farm.id));
      final list = res.data as List? ?? [];
      final operators = list
          .map((e) => e as Map<String, dynamic>)
          .where((u) => (u['roles'] as List? ?? []).contains('OPERATOR'))
          .map((u) => _Operator.fromJson(u))
          .toList();
      setState(() { _operators = operators; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  Future<void> _generateToken() async {
    if (_farmId == null) return;
    setState(() => _generatingToken = true);
    try {
      final token = await generateFarmToken(_farmId!);
      setState(() { _farmToken = token; _generatingToken = false; });
    } catch (_) { setState(() => _generatingToken = false); }
  }

  Future<void> _copyToken() async {
    if (_farmToken.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _farmToken));
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      currentRoute: '/operadores',
      child: _loading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Gestión de Operadores', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: kTextPrimary)),
                      Text('Administra los permisos del personal de campo', style: TextStyle(color: kTextSecondary, fontSize: 14)),
                    ]),
                    ElevatedButton.icon(
                      onPressed: _generatingToken ? null : _generateToken,
                      icon: _generatingToken ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.refresh, size: 18),
                      label: const Text('Actualizar Token'),
                    ),
                  ]),
                  const SizedBox(height: 24),
                  Card(child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
                    Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: kPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.people_outline, color: kPrimary, size: 24)),
                    const SizedBox(width: 16),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('TOTAL OPERADORES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: kTextSecondary)),
                      Text('${_operators.length}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: kTextPrimary)),
                    ]),
                  ]))),
                  const SizedBox(height: 16),
                  Card(child: Column(children: [
                    if (_operators.isEmpty)
                      const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('No hay operadores registrados', style: TextStyle(color: kTextSecondary))))
                    else ..._operators.asMap().entries.map((e) {
                      final op = e.value;
                      final isLast = e.key == _operators.length - 1;
                      final colors = [const Color(0xFF06B6D4), kNavyMid, const Color(0xFF0D9488), const Color(0xFF7C3AED)];
                      final color = colors[op.id % colors.length];
                      return Column(children: [
                        ListTile(
                          leading: CircleAvatar(backgroundColor: color, child: Text(op.firstName.isNotEmpty ? op.firstName[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                          title: Text(op.fullName, style: const TextStyle(fontWeight: FontWeight.w600, color: kTextPrimary)),
                          subtitle: Text(op.email, style: const TextStyle(fontSize: 12, color: kTextSecondary)),
                          trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: kNavy, borderRadius: BorderRadius.circular(12)), child: const Text('OPERATOR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white))),
                        ),
                        if (!isLast) const Divider(height: 1),
                      ]);
                    }),
                  ])),
                  const SizedBox(height: 24),
                  Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      const Icon(Icons.key, color: kPrimary, size: 20),
                      const SizedBox(width: 8),
                      const Text('SEGURIDAD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1, color: kTextSecondary)),
                    ]),
                    const SizedBox(height: 12),
                    const Text('Token de Granja', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kTextPrimary)),
                    const SizedBox(height: 4),
                    const Text('Usa este código para que nuevos operadores se registren.', style: TextStyle(color: kTextSecondary, fontSize: 13)),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: kBackground, borderRadius: BorderRadius.circular(8), border: Border.all(color: kBorder)),
                      child: Row(children: [
                        Expanded(child: Text(
                          _farmToken.isEmpty ? 'Presiona "Actualizar Token" para generar' : _farmToken,
                          style: TextStyle(fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.w700, color: _farmToken.isEmpty ? kTextSecondary : kTextPrimary),
                        )),
                        if (_farmToken.isNotEmpty)
                          IconButton(
                            onPressed: _copyToken,
                            icon: Icon(_copied ? Icons.check : Icons.copy, size: 18, color: _copied ? kSuccess : kTextSecondary),
                          ),
                      ]),
                    ),
                  ]))),
                ]),
              ),
            ),
    );
  }
}
