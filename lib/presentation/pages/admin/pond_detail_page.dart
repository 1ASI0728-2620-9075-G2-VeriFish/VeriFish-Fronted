import 'package:flutter/material.dart' hide Threshold;
import '../../../config/theme.dart';
import '../../../domain/pond.dart';
import '../../../infrastructure/pond_service.dart';
import '../../../domain/equipment.dart';
import '../../../infrastructure/equipment_service.dart';
import '../../../domain/threshold.dart';
import '../../../infrastructure/threshold_service.dart';
import '../../widgets/dashboard_layout.dart';

class PondDetailPage extends StatefulWidget {
  final int pondId;
  const PondDetailPage({super.key, required this.pondId});
  @override
  State<PondDetailPage> createState() => _PondDetailPageState();
}

class _PondDetailPageState extends State<PondDetailPage> {
  Pond? _pond;
  List<SensorReading> _telemetry = [];
  List<Map<String, dynamic>> _operators = [];
  List<Equipment> _pondEquipment = [];
  Threshold? _threshold;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final pondRes = await getPond(widget.pondId);
      final results = await Future.wait([
        getTelemetryStatus(widget.pondId),
        getOperators(),
        getEquipment(farmId: pondRes.farmId),
      ]);
      final threshold = await getThresholds(pondRes.species);
      if (mounted) {
        setState(() {
          _pond = pondRes;
          _telemetry = results[0] as List<SensorReading>;
          _operators = results[1] as List<Map<String, dynamic>>;
          _pondEquipment = (results[2] as List<Equipment>).where((e) => e.pondId == widget.pondId).toList();
          _threshold = threshold;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  SensorReading? _reading(String type) => _telemetry.cast<SensorReading?>().firstWhere(
        (r) => r!.sensorType.toUpperCase().contains(type),
        orElse: () => null,
      );

  Map<String, dynamic>? get _assignedOperator {
    final id = _pond?.assignedOperatorId;
    if (id == null) return null;
    return _operators.cast<Map<String, dynamic>?>().firstWhere(
      (o) => (o!['id'] as num?)?.toInt() == id,
      orElse: () => null,
    );
  }

  Future<void> _showAssignDialog() async {
    String? selected;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Asignar Operador', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Operador disponible', style: TextStyle(fontSize: 13, color: kTextSecondary)),
              const SizedBox(height: 8),
              if (_operators.isEmpty)
                const Text('No hay operadores registrados.', style: TextStyle(fontSize: 13, color: kTextSecondary))
              else
                DropdownButtonFormField<String>(
                  value: selected,
                  hint: const Text('Seleccionar operador...'),
                  items: _operators.map((op) {
                    final name = '${op['firstName'] ?? ''} ${op['lastName'] ?? ''}'.trim();
                    return DropdownMenuItem(value: op['id'].toString(), child: Text(name));
                  }).toList(),
                  onChanged: (v) => setS(() => selected = v),
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: selected == null ? null : () async {
                Navigator.pop(ctx);
                try {
                  await assignOperatorToPond(widget.pondId, int.parse(selected!));
                  _load();
                } catch (_) {}
              },
              child: const Text('Asignar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deassign() async {
    final op = _assignedOperator;
    if (op == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desasignar Operador'),
        content: Text('¿Desasignar a ${op['firstName']} ${op['lastName']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kError),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Desasignar'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await deassignOperatorFromPond(widget.pondId, (op['id'] as num).toInt());
        _load();
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      currentRoute: '/estanques/${widget.pondId}',
      child: _loading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : _pond == null
              ? const Center(child: Text('Estanque no encontrado'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      _PondHeader(pond: _pond!),
                      const SizedBox(height: 24),
                      const Text('Telemetría en Tiempo Real',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kNavy)),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: _TelemetryCard(
                          label: 'TEMPERATURA',
                          reading: _reading('TEMP'),
                          unit: '°C',
                          okMin: _threshold?.minTemperature ?? 20,
                          okMax: _threshold?.maxTemperature ?? 30,
                        )),

                        const SizedBox(width: 12),
                        Expanded(child: _TelemetryCard(
                          label: 'TURBIDEZ',
                          reading: _reading('TURBIDITY'),
                          unit: '%',
                          okMin: _threshold?.minTurbidity ?? 0,
                          okMax: _threshold?.maxTurbidity ?? 5,
                        )),
                      ]),
                      const SizedBox(height: 24),
                      _OperatorSection(
                        assignedOperator: _assignedOperator,
                        onAssign: _showAssignDialog,
                        onDeassign: _deassign,
                      ),
                      const SizedBox(height: 24),
                      _EquipmentSection(equipmentList: _pondEquipment),
                    ],
                  ),
                ),
    );
  }
}

class _PondHeader extends StatelessWidget {
  final Pond pond;
  const _PondHeader({required this.pond});
  @override
  Widget build(BuildContext context) {
    final isActive = pond.status != 'INACTIVE';
    return Row(
      children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(pond.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kNavy)),
            const SizedBox(height: 4),
            Text('ID: POND-${pond.id}  •  ${pond.species}  •  ${pond.volume.toStringAsFixed(0)}L',
                style: const TextStyle(fontSize: 13, color: kTextSecondary)),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            isActive ? 'ACTIVO' : 'INACTIVO',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isActive ? kPrimary : kError),
          ),
        ),
      ],
    );
  }
}

class _TelemetryCard extends StatelessWidget {
  final String label;
  final SensorReading? reading;
  final String unit;
  final double okMin, okMax;
  const _TelemetryCard({required this.label, required this.reading, required this.unit, required this.okMin, required this.okMax});

  @override
  Widget build(BuildContext context) {
    final value = reading?.value ?? 0;
    final isOk = value >= okMin && value <= okMax;
    final statusLabel = label.contains('TEMP') ? (isOk ? 'ÓPTIMO' : 'ALERTA') : (isOk ? 'SALUDABLE' : 'ALERTA');
    final color = isOk ? kPrimary : kError;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: kTextSecondary, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        Text('${value.toStringAsFixed(2)}$unit', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(statusLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        const SizedBox(height: 8),
        Text('Rango: $okMin - $okMax', style: const TextStyle(fontSize: 10, color: kTextSecondary)),
      ]),
    );
  }
}

class _OperatorSection extends StatelessWidget {
  final Map<String, dynamic>? assignedOperator;
  final VoidCallback onAssign;
  final VoidCallback onDeassign;
  const _OperatorSection({required this.assignedOperator, required this.onAssign, required this.onDeassign});

  @override
  Widget build(BuildContext context) {
    final op = assignedOperator;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Operador', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kNavy)),
          if (op == null)
            GestureDetector(
              onTap: onAssign,
              child: const Text('+ Asignar', style: TextStyle(fontSize: 13, color: kPrimary, fontWeight: FontWeight.w600)),
            )
          else
            GestureDetector(
              onTap: onDeassign,
              child: const Text('Desasignar', style: TextStyle(fontSize: 13, color: kError, fontWeight: FontWeight.w600)),
            ),
        ]),
        const SizedBox(height: 12),
        if (op == null)
          const Text('Sin operador asignado', style: TextStyle(fontSize: 13, color: kTextSecondary))
        else
          Row(children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: kPrimary,
              child: Text(
                '${op['firstName']?.toString().characters.first ?? '?'}'.toUpperCase(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${op['firstName']} ${op['lastName']}'.trim(),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kNavy)),
              Text(op['email']?.toString() ?? '', style: const TextStyle(fontSize: 12, color: kTextSecondary)),
            ]),
          ]),
      ]),
    );
  }
}

class _EquipmentSection extends StatelessWidget {
  final List<Equipment> equipmentList;
  const _EquipmentSection({required this.equipmentList});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Equipos Asignados', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kNavy)),
        const SizedBox(height: 12),
        if (equipmentList.isEmpty)
          const Text('No hay equipos asignados a este estanque.', style: TextStyle(fontSize: 13, color: kTextSecondary))
        else
          Column(
            children: equipmentList.map((eq) {
              final isLast = eq == equipmentList.last;
              return Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: eq.isSensor ? kPrimary.withValues(alpha: 0.1) : const Color(0xFF7C3AED).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: Icon(eq.isSensor ? Icons.sensors : Icons.settings_remote, color: eq.isSensor ? kPrimary : const Color(0xFF7C3AED), size: 20),
                    ),
                    title: Text(eq.name, style: const TextStyle(fontWeight: FontWeight.w600, color: kTextPrimary)),
                    subtitle: Text('${eq.type} · ${eq.physicalCode}', style: const TextStyle(fontSize: 12, color: kTextSecondary)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: kSuccess.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                      child: Text(eq.status, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kSuccess)),
                    ),
                  ),
                  if (!isLast) const Divider(height: 1),
                ],
              );
            }).toList(),
          ),
      ]),
    );
  }
}
