import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../domain/pond.dart';
import '../../../infrastructure/auth_provider.dart';
import '../../../infrastructure/farm_service.dart';
import '../../../infrastructure/pond_service.dart';
import '../../widgets/dashboard_layout.dart';

class PondsPage extends StatefulWidget {
  const PondsPage({super.key});
  @override
  State<PondsPage> createState() => _PondsPageState();
}

class _PondsPageState extends State<PondsPage> {
  List<Pond> _ponds = [];
  bool _loading = true;
  int? _farmId;
  bool _showCreate = false;
  final _nameCtrl = TextEditingController();
  final _speciesCtrl = TextEditingController();
  final _volumeCtrl = TextEditingController();
  bool _creating = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final userId = context.read<AuthProvider>().user?.id ?? 0;
    try {
      final farm = await getUserFarm(userId);
      if (farm == null) { setState(() => _loading = false); return; }
      _farmId = farm.id;
      final ponds = await getPondsByFarm(farm.id);
      setState(() { _ponds = ponds; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  Future<void> _createPond() async {
    if (_nameCtrl.text.trim().isEmpty || _farmId == null) return;
    setState(() => _creating = true);
    try {
      await createPond(farmId: _farmId!, name: _nameCtrl.text.trim(), species: _speciesCtrl.text.trim(), volume: double.tryParse(_volumeCtrl.text) ?? 0);
      _nameCtrl.clear(); _speciesCtrl.clear(); _volumeCtrl.clear();
      setState(() { _showCreate = false; _creating = false; });
      _load();
    } catch (_) { setState(() => _creating = false); }
  }

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      currentRoute: '/estanques',
      child: Stack(children: [
        _loading
            ? const Center(child: CircularProgressIndicator(color: kPrimary))
            : RefreshIndicator(
                onRefresh: _load,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Estanques', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: kTextPrimary)),
                        Text('Gestiona tus estanques acuícolas', style: TextStyle(color: kTextSecondary, fontSize: 14)),
                      ]),
                      ElevatedButton.icon(
                        onPressed: () => setState(() => _showCreate = true),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Nuevo Estanque'),
                      ),
                    ]),
                    const SizedBox(height: 24),
                    if (_ponds.isEmpty)
                      Card(child: Padding(padding: const EdgeInsets.all(40), child: Center(child: Column(children: [
                        Icon(Icons.water_outlined, size: 48, color: kTextSecondary.withValues(alpha: 0.5)),
                        const SizedBox(height: 16),
                        const Text('No tienes estanques aún', style: TextStyle(color: kTextSecondary, fontSize: 16)),
                      ]))))
                    else
                      ...(_ponds.map((p) => _PondCard(pond: p, onTap: () => context.go('/estanques/${p.id}')))),
                  ]),
                ),
              ),
        if (_showCreate) _CreatePondModal(nameCtrl: _nameCtrl, speciesCtrl: _speciesCtrl, volumeCtrl: _volumeCtrl, loading: _creating, onConfirm: _createPond, onCancel: () => setState(() => _showCreate = false)),
      ]),
    );
  }
}

class _PondCard extends StatelessWidget {
  final Pond pond;
  final VoidCallback onTap;
  const _PondCard({required this.pond, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final isActive = pond.status == 'ACTIVE';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(padding: const EdgeInsets.all(20), child: Row(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: kPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.water_outlined, color: kPrimary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(pond.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kTextPrimary)),
            const SizedBox(height: 4),
            Text('${pond.species} · ${pond.volume.toStringAsFixed(0)} m³', style: const TextStyle(fontSize: 13, color: kTextSecondary)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: isActive ? kSuccess.withValues(alpha: 0.1) : kTextSecondary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Text(pond.status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isActive ? kSuccess : kTextSecondary)),
            ),
            const SizedBox(height: 4),
            const Icon(Icons.chevron_right, size: 18, color: kTextSecondary),
          ]),
        ])),
      ),
    );
  }
}

class _CreatePondModal extends StatefulWidget {
  final TextEditingController nameCtrl, speciesCtrl, volumeCtrl;
  final bool loading;
  final VoidCallback onConfirm, onCancel;
  const _CreatePondModal({required this.nameCtrl, required this.speciesCtrl, required this.volumeCtrl, required this.loading, required this.onConfirm, required this.onCancel});
  @override
  State<_CreatePondModal> createState() => _CreatePondModalState();
}

class _CreatePondModalState extends State<_CreatePondModal> {
  static const _species = ['TRUCHA', 'PAICHE', 'TILAPIA', 'OTRO'];
  String _selected = 'TRUCHA';

  @override
  void initState() {
    super.initState();
    widget.speciesCtrl.text = _selected;
  }

  @override
  Widget build(BuildContext context) => Container(
    color: Colors.black54,
    child: Center(child: Container(
      margin: const EdgeInsets.all(24), padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      constraints: const BoxConstraints(maxWidth: 400),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Nuevo Estanque', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kTextPrimary)),
          IconButton(onPressed: widget.onCancel, icon: const Icon(Icons.close)),
        ]),
        const SizedBox(height: 16),
        TextField(controller: widget.nameCtrl, decoration: const InputDecoration(labelText: 'Nombre')),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _selected,
          decoration: const InputDecoration(labelText: 'Especie'),
          items: _species.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: (v) {
            if (v == null) return;
            setState(() => _selected = v);
            widget.speciesCtrl.text = v;
          },
        ),
        const SizedBox(height: 12),
        TextField(controller: widget.volumeCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Volumen (m³)')),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: widget.onCancel, child: const Text('Cancelar'))),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(
            onPressed: widget.loading ? null : widget.onConfirm,
            child: widget.loading ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Crear'),
          )),
        ]),
      ]),
    )),
  );
}
