import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../domain/equipment.dart';
import '../../../domain/pond.dart';
import '../../../infrastructure/auth_provider.dart';
import '../../../infrastructure/equipment_service.dart';
import '../../../infrastructure/farm_service.dart';
import '../../../infrastructure/pond_service.dart';
import '../../components/equipment/equipment_widgets.dart';
import '../../widgets/dashboard_layout.dart';

class EquipmentPage extends StatefulWidget {
  const EquipmentPage({super.key});
  @override
  State<EquipmentPage> createState() => _EquipmentPageState();
}

class _EquipmentPageState extends State<EquipmentPage> {
  List<Equipment> _equipment = [];
  bool _loading = true;
  int? _farmId;
  bool _showCreate = false;
  Equipment? _selectedEquipment;
  bool _showLinkPond = false;
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  String _type = 'SENSOR';
  bool _creating = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final userId = context.read<AuthProvider>().user?.id ?? 0;
    try {
      final farm = await getUserFarm(userId);
      if (farm == null) { setState(() => _loading = false); return; }
      _farmId = farm.id;
      final eq = await getEquipment(farmId: _farmId);
      setState(() { _equipment = eq; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  Future<void> _create() async {
    if (_nameCtrl.text.trim().isEmpty || _codeCtrl.text.trim().isEmpty || _farmId == null) return;
    setState(() => _creating = true);
    try {
      if (_type == 'IOT_NODE') {
        await createIoTDevice(farmId: _farmId!, name: _nameCtrl.text.trim(), physicalCode: _codeCtrl.text.trim());
      } else {
        await createEquipment(farmId: _farmId!, type: _type, name: _nameCtrl.text.trim(), physicalCode: _codeCtrl.text.trim());
      }
      _nameCtrl.clear(); _codeCtrl.clear();
      setState(() { _showCreate = false; _creating = false; });
      _load();
    } catch (_) { setState(() => _creating = false); }
  }

  Future<void> _delete(int id) async {
    final confirm = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Eliminar equipo'),
      content: const Text('¿Estás seguro de que deseas eliminar este equipo?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
        ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: kError), child: const Text('Eliminar')),
      ],
    ));
    if (confirm == true) { await deleteEquipment(id); _load(); }
  }

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      currentRoute: '/equipos',
      child: Stack(children: [
        _loading
            ? const Center(child: CircularProgressIndicator(color: kPrimary))
            : RefreshIndicator(
                onRefresh: _load,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Equipos', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: kTextPrimary)),
                        Text('Gestiona tus sensores y actuadores', style: TextStyle(color: kTextSecondary, fontSize: 14)),
                      ]),
                      ElevatedButton.icon(onPressed: () => setState(() => _showCreate = true), icon: const Icon(Icons.add, size: 18), label: const Text('Registrar Equipo')),
                    ]),
                    const SizedBox(height: 24),
                    if (_equipment.isEmpty)
                      Card(child: Padding(padding: const EdgeInsets.all(40), child: Center(child: Column(children: [
                        Icon(Icons.devices_outlined, size: 48, color: kTextSecondary.withValues(alpha: 0.5)),
                        const SizedBox(height: 16),
                        const Text('No tienes equipos registrados', style: TextStyle(color: kTextSecondary)),
                      ]))))
                    else
                      Card(child: Column(children: _equipment.asMap().entries.map((e) {
                        final eq = e.value;
                        final isLast = e.key == _equipment.length - 1;
                        return Column(children: [
                          ListTile(
                            onTap: () => setState(() => _selectedEquipment = eq),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: eq.isSensor ? kPrimary.withValues(alpha: 0.1) : const Color(0xFF7C3AED).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                              child: Icon(eq.isSensor ? Icons.sensors : Icons.settings_remote, color: eq.isSensor ? kPrimary : const Color(0xFF7C3AED), size: 20),
                            ),
                            title: Text(eq.name, style: const TextStyle(fontWeight: FontWeight.w600, color: kTextPrimary)),
                            subtitle: Text('${eq.type} · ${eq.physicalCode}', style: const TextStyle(fontSize: 12, color: kTextSecondary)),
                            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: eq.isLinked ? kSuccess.withValues(alpha: 0.1) : kWarning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                                child: Text(eq.status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: eq.isLinked ? kSuccess : kWarning)),
                              ),
                              IconButton(icon: const Icon(Icons.delete_outline, color: kError, size: 20), onPressed: () => _delete(eq.id)),
                            ]),
                          ),
                          if (!isLast) const Divider(height: 1),
                        ]);
                      }).toList())),
                  ]),
                ),
              ),
        if (_showCreate) CreateEquipmentModal(nameCtrl: _nameCtrl, codeCtrl: _codeCtrl, type: _type, onTypeChanged: (t) => setState(() => _type = t), loading: _creating, onConfirm: _create, onCancel: () => setState(() => _showCreate = false)),
        if (_selectedEquipment != null && !_showLinkPond)
          EquipmentDetailsModal(
            equipment: _selectedEquipment!,
            onClose: () => setState(() => _selectedEquipment = null),
            onLinkTap: () => setState(() => _showLinkPond = true),
          ),
        if (_showLinkPond && _selectedEquipment != null)
          LinkPondModal(
            farmId: _farmId!,
            equipmentId: _selectedEquipment!.id,
            onClose: () => setState(() { _showLinkPond = false; _selectedEquipment = null; }),
            onLinked: () {
              setState(() { _showLinkPond = false; _selectedEquipment = null; });
              _load();
            },
          ),
      ]),
    );
  }
}
