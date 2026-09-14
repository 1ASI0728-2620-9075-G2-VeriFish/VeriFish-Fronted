import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../domain/pond.dart';
import '../../infrastructure/pond_service.dart';

class PondsAverageStats extends StatefulWidget {
  final List<Pond> ponds;

  const PondsAverageStats({super.key, required this.ponds});

  @override
  State<PondsAverageStats> createState() => _PondsAverageStatsState();
}

class _PondsAverageStatsState extends State<PondsAverageStats> {
  bool _loading = true;
  final Map<String, double> _averages = {};
  final Map<String, String> _units = {};

  @override
  void initState() {
    super.initState();
    _calculateAverages();
  }

  @override
  void didUpdateWidget(covariant PondsAverageStats oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ponds != widget.ponds) {
      _calculateAverages();
    }
  }

  Future<void> _calculateAverages() async {
    if (widget.ponds.isEmpty) {
      setState(() {
        _loading = false;
        _averages.clear();
      });
      return;
    }

    setState(() => _loading = true);

    try {
      final futures = widget.ponds.map((p) => getTelemetryStatus(p.id));
      final results = await Future.wait(futures);

      final Map<String, List<double>> groupedStats = {};

      for (var readings in results) {
        for (var reading in readings) {
          if (!groupedStats.containsKey(reading.sensorType)) {
            groupedStats[reading.sensorType] = [];
          }
          groupedStats[reading.sensorType]!.add(reading.value);
        }
      }

      final Map<String, double> newAverages = {};
      groupedStats.forEach((key, values) {
        if (values.isNotEmpty) {
          newAverages[key] = values.reduce((a, b) => a + b) / values.length;
        }
      });

      setState(() {
        _averages.clear();
        _averages.addAll(newAverages);
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  IconData _getIconForType(String type) {
    if (type.toUpperCase().contains('TEMP')) return Icons.thermostat_outlined;
    if (type.toUpperCase().contains('PH')) return Icons.science_outlined;
    if (type.toUpperCase().contains('OXY')) return Icons.air_outlined;
    return Icons.sensors_outlined;
  }

  Color _getColorForType(String type) {
    if (type.toUpperCase().contains('TEMP')) return const Color(0xFFEF4444);
    if (type.toUpperCase().contains('PH')) return const Color(0xFF8B5CF6);
    if (type.toUpperCase().contains('OXY')) return const Color(0xFF3B82F6);
    return kPrimary;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator(color: kPrimary)),
        ),
      );
    }

    if (_averages.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text('No hay datos de telemetría disponibles', style: TextStyle(color: kTextSecondary)),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Promedio Global de Sensores', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kTextPrimary)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: _averages.entries.map((e) {
                final color = _getColorForType(e.key);
                
                // Definir un valor máximo aproximado para calcular el porcentaje
                double maxVal = 100;
                if (e.key.toUpperCase().contains('TEMP')) maxVal = 40; // Max 40 grados
                if (e.key.toUpperCase().contains('PH')) maxVal = 14;   // Max 14 pH
                if (e.key.toUpperCase().contains('OXY')) maxVal = 20;  // Max 20 mg/L
                final percentage = (e.value / maxVal).clamp(0.0, 1.0);

                return Container(
                  width: 140,
                  height: 160,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                    border: Border.all(color: kBorder),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_getIconForType(e.key), color: color, size: 16),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              e.key,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kTextSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: 70,
                        height: 70,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CircularProgressIndicator(
                              value: 1.0,
                              strokeWidth: 8,
                              valueColor: AlwaysStoppedAnimation(color.withValues(alpha: 0.1)),
                            ),
                            TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0.0, end: percentage),
                              duration: const Duration(milliseconds: 1500),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, _) => CircularProgressIndicator(
                                value: value,
                                strokeWidth: 8,
                                backgroundColor: Colors.transparent,
                                valueColor: AlwaysStoppedAnimation(color),
                                strokeCap: StrokeCap.round,
                              ),
                            ),
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    e.value.toStringAsFixed(1),
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kTextPrimary),
                                  ),
                                  if (!e.key.toUpperCase().contains('PH'))
                                    Text(
                                      _units[e.key] ?? "",
                                      style: const TextStyle(fontSize: 10, color: kTextSecondary, fontWeight: FontWeight.w600),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
