import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../infrastructure/equipment_service.dart';
import '../../../domain/equipment.dart';
import '../../widgets/operator_layout.dart';

class OperatorEquipmentPage extends StatefulWidget {
  const OperatorEquipmentPage({super.key});
  @override
  State<OperatorEquipmentPage> createState() => _State();
}

class _State extends State<OperatorEquipmentPage> {
  List<Equipment> _equipment = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final items = await getEquipment();
      if (mounted) setState(() { _equipment = items; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _loading = false; _error = 'No se pudo cargar el equipamiento'; });
    }
  }

  Future<void> _activateActuator(Equipment eq) async {
    try {
      await activateActuator(eq.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Actuador "${eq.name}" activado'),
          backgroundColor: kSuccess,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Error al activar el actuador (Revise conectividad)'),
          backgroundColor: kError,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sensors = _equipment.where((e) => e.isSensor).toList();
    final actuators = _equipment.where((e) => !e.isSensor).toList();

    return OperatorLayout(
      currentRoute: '/op/equipment',
      child: SafeArea(
        child: Column(children: [
          Container(
            color: kSurface,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Row(children: [
              const Text('Equipamiento',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kNavy)),
              const Spacer(),
              if (!_loading && _equipment.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${_equipment.length} equipos',
                      style: const TextStyle(fontSize: 12, color: kPrimary, fontWeight: FontWeight.w600)),
                ),
            ]),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: kPrimary))
                : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(color: kTextSecondary)))
                    : _equipment.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: Text('No hay equipamiento asignado',
                                  style: TextStyle(color: kTextSecondary)),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                              children: [
                                if (actuators.isNotEmpty) ...[
                                  _SectionHeader(label: 'Actuadores', count: actuators.length),
                                  const SizedBox(height: 8),
                                  ...actuators.map((e) => _ActuatorCard(
                                    equipment: e,
                                    onActivate: () => _activateActuator(e),
                                  )),
                                  const SizedBox(height: 16),
                                ],
                                if (sensors.isNotEmpty) ...[
                                  _SectionHeader(label: 'Sensores', count: sensors.length),
                                  const SizedBox(height: 8),
                                  ...sensors.map((e) => _SensorCard(equipment: e)),
                                ],
                              ],
                            ),
                          ),
          ),
        ]),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final int count;
  const _SectionHeader({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kNavy, letterSpacing: 0.3)),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: kBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder),
        ),
        child: Text('$count', style: const TextStyle(fontSize: 11, color: kTextSecondary, fontWeight: FontWeight.w600)),
      ),
    ]);
  }
}

class _ActuatorCard extends StatelessWidget {
  final Equipment equipment;
  final VoidCallback onActivate;
  const _ActuatorCard({required this.equipment, required this.onActivate});

  Color get _statusColor => equipment.isLinked ? kSuccess : kTextSecondary;
  String get _statusLabel => equipment.isLinked ? 'VINCULADO' : equipment.status;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.settings_remote_outlined, color: kPrimary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(equipment.name,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kNavy)),
              Text(equipment.physicalCode,
                  style: const TextStyle(fontSize: 12, color: kTextSecondary)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(_statusLabel,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                    color: _statusColor, letterSpacing: 0.5)),
          ),
        ]),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.bolt, size: 16, color: Colors.white),
            label: const Text('Activar Actuador',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: onActivate,
          ),
        ),
      ]),
    );
  }
}

class _SensorCard extends StatelessWidget {
  final Equipment equipment;
  const _SensorCard({required this.equipment});

  Color get _statusColor => equipment.isLinked ? kSuccess : kTextSecondary;
  String get _statusLabel => equipment.isLinked ? 'VINCULADO' : equipment.status;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: kSuccess.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.sensors, color: kSuccess, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(equipment.name,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kNavy)),
            Text(equipment.physicalCode,
                style: const TextStyle(fontSize: 12, color: kTextSecondary)),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(_statusLabel,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                  color: _statusColor, letterSpacing: 0.5)),
        ),
      ]),
    );
  }
}
