import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme.dart';
import '../../../infrastructure/auth_provider.dart';
import '../../../infrastructure/farm_service.dart';
import '../../../infrastructure/pond_service.dart';
import '../../../infrastructure/threshold_service.dart';
import '../../../domain/pond.dart';
import '../../../domain/threshold.dart' as domain;
import '../../widgets/operator_layout.dart';

class OperatorHomePage extends StatefulWidget {
  const OperatorHomePage({super.key});
  @override
  State<OperatorHomePage> createState() => _OperatorHomePageState();
}

class _OperatorHomePageState extends State<OperatorHomePage> {
  Farm? _farm;
  List<Pond> _ponds = [];
  Map<int, List<SensorReading>> _telemetry = {};
  Map<String, domain.Threshold?> _thresholds = {};
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
        getPondsByOperator(userId),
      ]);
      final farm = results[0] as Farm?;
      final ponds = results[1] as List<Pond>;
      final Map<int, List<SensorReading>> telem = {};
      await Future.wait(ponds.map((p) async {
        telem[p.id] = await getTelemetryStatus(p.id);
      }));
      final species = ponds.map((p) => p.species).toSet();
      final Map<String, domain.Threshold?> thresholds = {};
      await Future.wait(species.map((s) async {
        thresholds[s] = await getThresholds(s);
      }));
      if (mounted) {
        setState(() {
          _farm = farm;
          _ponds = ponds;
          _telemetry = telem;
          _thresholds = thresholds;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return OperatorLayout(
      currentRoute: '/op/home',
      child: SafeArea(
        child: Column(children: [
          _OpHeader(firstName: user?.firstName ?? '', onAlerts: () => context.go('/op/alerts')),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: kPrimary))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                      children: [
                        const Text('Mis Estanques',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kNavy)),
                        const SizedBox(height: 4),
                        if (_farm != null)
                          Text(
                            'Estado actual de la Finca ${_farm!.name}',
                            style: const TextStyle(fontSize: 14, color: kTextSecondary),
                          ),
                        const SizedBox(height: 16),
                        if (_ponds.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: Text('No hay estanques asignados',
                                  style: TextStyle(color: kTextSecondary)),
                            ),
                          )
                        else
                          ..._ponds.map((p) => _PondCard(
                                pond: p,
                                readings: _telemetry[p.id] ?? [],
                                threshold: _thresholds[p.species],
                                onTap: () => context.go('/op/pond/${p.id}'),
                              )),
                      ],
                    ),
                  ),
          ),
        ]),
      ),
    );
  }
}

class _OpHeader extends StatelessWidget {
  final String firstName;
  final VoidCallback onAlerts;
  const _OpHeader({required this.firstName, required this.onAlerts});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kSurface,
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
      child: Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('YakuControl',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kNavy)),
          Text('Hola, $firstName',
              style: const TextStyle(fontSize: 14, color: kTextSecondary)),
        ]),
        const Spacer(),
        Stack(clipBehavior: Clip.none, children: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: kNavy, size: 26),
            onPressed: onAlerts,
          ),
          Positioned(
            right: 10, top: 10,
            child: Container(
              width: 9, height: 9,
              decoration: const BoxDecoration(color: kError, shape: BoxShape.circle),
            ),
          ),
        ]),
      ]),
    );
  }
}

class _PondCard extends StatelessWidget {
  final Pond pond;
  final List<SensorReading> readings;
  final domain.Threshold? threshold;
  final VoidCallback onTap;
  const _PondCard({required this.pond, required this.readings, required this.threshold, required this.onTap});

  SensorReading? _get(String type) {
    try {
      return readings.firstWhere((r) => r.sensorType.toUpperCase().contains(type));
    } catch (_) {
      return null;
    }
  }

  bool get _tempAlert {
    final t = _get('TEMP');
    if (t == null) return false;
    final th = threshold;
    if (th != null) return t.value < th.minTemperature || t.value > th.maxTemperature;
    return t.value < 20 || t.value > 30;
  }


  bool get _turbAlert {
    final turb = _get('TURB');
    if (turb == null) return false;
    final th = threshold;
    if (th != null) return turb.value < th.minTurbidity || turb.value > th.maxTurbidity;
    return turb.value > 5;
  }

  bool get _isAlert => _tempAlert || _turbAlert;

  String get _ago {
    if (readings.isEmpty) return '';
    try {
      final times = readings
          .map((r) => DateTime.tryParse(r.timestamp))
          .whereType<DateTime>()
          .toList();
      if (times.isEmpty) return '';
      times.sort((a, b) => b.compareTo(a));
      final diff = DateTime.now().difference(times.first);
      if (diff.inMinutes < 1) return 'AHORA';
      if (diff.inMinutes < 60) return 'HACE ${diff.inMinutes} MINS';
      if (diff.inHours < 24) return 'HACE ${diff.inHours}H';
      return 'HACE ${diff.inDays}D';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final temp = _get('TEMP');
    final turb = _get('TURB');
    final alert = _isAlert;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(pond.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kNavy)),
                if (_ago.isNotEmpty)
                  Text(_ago,
                      style: const TextStyle(fontSize: 11, color: kTextSecondary, letterSpacing: 0.5)),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: alert ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(
                  alert ? Icons.warning_rounded : Icons.check_circle,
                  size: 14,
                  color: alert ? kError : kSuccess,
                ),
                const SizedBox(width: 4),
                Text(
                  alert ? 'ALERTA' : 'NORMAL',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: alert ? kError : kSuccess,
                    letterSpacing: 0.5,
                  ),
                ),
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            _STile(
              icon: Icons.thermostat_outlined,
              value: temp != null ? '${temp.value.toStringAsFixed(1)}°C' : '--',
              alert: _tempAlert,
            ),
            const SizedBox(width: 8),
            _STile(
              icon: Icons.water_outlined,
              value: turb != null ? '${turb.value.toStringAsFixed(1)} %' : '--',
              alert: _turbAlert,
            ),
          ]),
        ]),
      ),
    );
  }
}

class _STile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String? subLabel;
  final bool alert;
  const _STile({required this.icon, required this.value, this.subLabel, this.alert = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: alert ? const Color(0xFFFEE2E2) : kBackground,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(children: [
          Icon(icon, size: 18, color: alert ? kError : kTextSecondary),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: alert ? kError : kNavy,
            ),
            textAlign: TextAlign.center,
          ),
        ]),
      ),
    );
  }
}
