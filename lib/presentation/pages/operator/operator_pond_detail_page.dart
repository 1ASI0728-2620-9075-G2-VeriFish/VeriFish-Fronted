import 'package:flutter/material.dart' hide Threshold;
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../config/theme.dart';
import '../../../infrastructure/pond_service.dart';
import '../../../infrastructure/equipment_service.dart';
import '../../../domain/pond.dart';
import '../../../domain/equipment.dart';
import '../../../domain/threshold.dart';
import '../../../infrastructure/threshold_service.dart';
import '../../widgets/operator_layout.dart';

class OperatorPondDetailPage extends StatefulWidget {
  final int pondId;
  const OperatorPondDetailPage({super.key, required this.pondId});
  @override
  State<OperatorPondDetailPage> createState() => _State();
}

class _State extends State<OperatorPondDetailPage> {
  Pond? _pond;
  List<SensorReading> _status = [];
  List<HistoricalReading> _historical = [];
  List<Equipment> _equipment = [];
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
      final pond = await getPond(widget.pondId);
      final results = await Future.wait([
        getTelemetryStatus(widget.pondId),
        getTelemetryHistorical(widget.pondId),
        getEquipment(),
        getThresholds(pond.species),
      ]);
      if (mounted) {
        setState(() {
          _pond = pond;
          _status = results[0] as List<SensorReading>;
          _historical = results[1] as List<HistoricalReading>;
          _equipment = (results[2] as List<Equipment>)
              .where((e) => e.pondId == widget.pondId)
              .toList();
          _threshold = results[3] as Threshold?;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  SensorReading? _get(String type) {
    try {
      return _status.firstWhere((r) => r.sensorType.toUpperCase().contains(type));
    } catch (_) {
      return null;
    }
  }

  List<double> _bars(String type) {
    var vals = _historical
        .where((h) => h.sensorType.toUpperCase().contains(type))
        .map((h) => h.avgValue)
        .toList();

    if (vals.isEmpty) {
      vals = _status
          .where((r) => r.sensorType.toUpperCase().contains(type))
          .map((r) => r.value)
          .toList()
          .reversed
          .toList();
    }

    return vals;
  }

  @override
  Widget build(BuildContext context) {
    return OperatorLayout(
      currentRoute: '/op/home',
      child: SafeArea(
        child: Column(children: [
          Container(
            color: kSurface,
            padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
            child: Row(children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: kNavy, size: 20),
                onPressed: () => context.go('/op/home'),
              ),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    _pond?.name ?? 'Estanque',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kNavy),
                  ),
                  Row(children: [
                    Container(
                      width: 8, height: 8,
                      margin: const EdgeInsets.only(right: 5),
                      decoration: const BoxDecoration(color: kSuccess, shape: BoxShape.circle),
                    ),
                    const Text('EN VIVO',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700,
                            color: kSuccess, letterSpacing: 0.8)),
                  ]),
                ]),
              ),
            ]),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: kPrimary))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _MetricCard(
                          label: 'TEMPERATURA',
                          reading: _get('TEMP'),
                          unit: '°C',
                          bars: _bars('TEMP'),
                          okMin: _threshold?.minTemperature ?? 20,
                          okMax: _threshold?.maxTemperature ?? 30,
                          featured: true,
                        ),
                        const SizedBox(height: 12),

                        _MetricCard(
                          label: 'TURBIDEZ',
                          reading: _get('TURB'),
                          unit: '%',
                          bars: _bars('TURB'),
                          okMin: _threshold?.minTurbidity ?? 0,
                          okMax: _threshold?.maxTurbidity ?? 5,
                        ),
                        const SizedBox(height: 12),
                        _MetricCard(
                          label: 'ICA (CALIDAD DEL AGUA)',
                          reading: _get('ICA'),
                          unit: 'pts',
                          bars: _bars('ICA'),
                          okMin: _threshold?.ica ?? 40.0,
                          okMax: 100.0,
                        ),
                        const SizedBox(height: 24),
                        const Text('Sensores en este estanque',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kNavy)),
                        const SizedBox(height: 12),
                        if (_equipment.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: kSurface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: kBorder),
                            ),
                            child: const Text('No hay equipos vinculados',
                                style: TextStyle(color: kTextSecondary)),
                          )
                        else
                          ..._equipment.map((e) => _EquipRow(eq: e)),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.bar_chart, size: 18),
                            label: const Text('Ver historial completo'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kNavy,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () => context.go('/op/history/${widget.pondId}'),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
          ),
        ]),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final SensorReading? reading;
  final String unit;
  final List<double> bars;
  final double okMin;
  final double okMax;
  final bool featured;

  const _MetricCard({
    required this.label,
    required this.reading,
    required this.unit,
    required this.bars,
    required this.okMin,
    required this.okMax,
    this.featured = false,
  });

  String get _value {
    if (reading == null) return '--';
    return reading!.value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final bg = featured ? kNavy : kSurface;
    final textPrimary = featured ? Colors.white : kNavy;
    final textSub = featured ? const Color(0xFF94A3B8) : kTextSecondary;

    final val = reading?.value ?? 0;
    final isOk = reading == null || (val >= okMin && val <= okMax);
    final statusColor = isOk ? kSuccess : kError;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: featured ? null : Border.all(color: kBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600,
                  color: textSub, letterSpacing: 1)),
          const Spacer(),
          if (bars.isNotEmpty)
            Text('${bars.length} lecturas', style: TextStyle(fontSize: 10, color: textSub, fontStyle: FontStyle.italic)),
          const SizedBox(width: 8),
          const Spacer(),
          if (reading != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isOk ? 'ESTABLE' : 'ALERTA',
                style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.bold,
                    color: statusColor),
              ),
            ),
        ]),
        const SizedBox(height: 8),
        Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
          Text(_value, style: TextStyle(fontSize: 38, fontWeight: FontWeight.bold, color: textPrimary)),
          if (unit.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(unit, style: TextStyle(fontSize: 16, color: textSub, fontWeight: FontWeight.w500)),
          ],
        ]),
        const SizedBox(height: 12),
        _MiniBarChart(
          values: bars.length > 10 ? bars.sublist(bars.length - 10) : bars,
          featured: featured,
          okMax: okMax,
        ),
      ]),
    );
  }
}

class _MiniBarChart extends StatelessWidget {
  final List<double> values;
  final bool featured;
  final double okMax;
  const _MiniBarChart({required this.values, this.featured = false, required this.okMax});

  @override
  Widget build(BuildContext context) {
    final chartValues = values.isEmpty ? [0.0, 0.0, 0.0, 0.0, 0.0] : values;

    final lineColor = featured ? const Color(0xFF22D3EE) : kPrimary;
    final gradientTop = featured
        ? const Color(0xFF22D3EE).withOpacity(0.4)
        : kPrimary.withOpacity(0.3);
    final gradientBottom = featured
        ? const Color(0xFF22D3EE).withOpacity(0.0)
        : kPrimary.withOpacity(0.0);

    final spots = chartValues.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

    final minY = chartValues.reduce((a, b) => a < b ? a : b);
    final maxYData = chartValues.reduce((a, b) => a > b ? a : b);
    final maxY = maxYData > okMax ? maxYData : okMax;
    final padding = (maxY - minY).abs() * 0.2;

    return SizedBox(
      height: 52,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          minY: minY - padding,
          maxY: maxY + padding,
          lineTouchData: const LineTouchData(enabled: false),
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: okMax,
                color: kError.withOpacity(0.8),
                strokeWidth: 1.5,
                dashArray: [4, 4],
              ),
            ],
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.35,
              color: lineColor,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [gradientTop, gradientBottom],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EquipRow extends StatelessWidget {
  final Equipment eq;
  const _EquipRow({required this.eq});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorder),
      ),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(color: kNavy, borderRadius: BorderRadius.circular(8)),
          child: Icon(
            eq.isSensor ? Icons.sensors : Icons.wifi_tethering,
            color: Colors.white, size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(eq.name,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kNavy)),
          Text(eq.type,
              style: const TextStyle(fontSize: 12, color: kTextSecondary)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: kPrimary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'ACTIVO',
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700,
                color: kPrimaryDark),
          ),
        ),
      ]),
    );
  }
}
