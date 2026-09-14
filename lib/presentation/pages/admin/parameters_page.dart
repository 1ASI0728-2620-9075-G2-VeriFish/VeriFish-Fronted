import 'package:flutter/material.dart' hide Threshold;
import '../../../config/theme.dart';
import '../../../domain/threshold.dart';
import '../../../infrastructure/threshold_service.dart';
import '../../widgets/dashboard_layout.dart';

class ParametersPage extends StatefulWidget {
  const ParametersPage({super.key});
  @override
  State<ParametersPage> createState() => _ParametersPageState();
}

class _ParametersPageState extends State<ParametersPage> {
  static const _species = ['TRUCHA', 'PAICHE', 'TILAPIA', 'OTRO'];
  String _selected = 'TRUCHA';
  Threshold? _threshold;
  bool _loading = true;
  bool _saving = false;
  String? _successMsg;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _load(_selected);
  }

  Future<void> _load(String species) async {
    setState(() { _loading = true; _successMsg = null; _errorMsg = null; });
    final t = await getThresholds(species);
    if (mounted) setState(() { _threshold = t; _loading = false; });
  }

  Future<void> _save(Threshold updated) async {
    setState(() { _saving = true; _successMsg = null; _errorMsg = null; });
    try {
      final saved = await saveThresholds(updated);
      if (mounted) setState(() { _threshold = saved; _saving = false; _successMsg = 'Parámetros guardados correctamente'; });
    } catch (_) {
      if (mounted) setState(() { _saving = false; _errorMsg = 'Error al guardar los parámetros'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      currentRoute: '/parametros',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Parámetros', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: kTextPrimary)),
          const Text('Configura los umbrales por especie', style: TextStyle(color: kTextSecondary, fontSize: 14)),
          const SizedBox(height: 24),
          _SpeciesSelector(
            species: _species,
            selected: _selected,
            onSelect: (s) { setState(() => _selected = s); _load(s); },
          ),
          const SizedBox(height: 24),
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator(color: kPrimary)))
          else
            _ThresholdForm(
              species: _selected,
              threshold: _threshold,
              saving: _saving,
              successMsg: _successMsg,
              errorMsg: _errorMsg,
              onSave: _save,
              readOnly: _selected != 'OTRO',
            ),
        ]),
      ),
    );
  }
}

class _SpeciesSelector extends StatelessWidget {
  final List<String> species;
  final String selected;
  final ValueChanged<String> onSelect;
  const _SpeciesSelector({required this.species, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: species.map((s) {
        final isSelected = s == selected;
        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: GestureDetector(
            onTap: () => onSelect(s),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? kPrimary : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isSelected ? kPrimary : kBorder),
                boxShadow: isSelected ? [BoxShadow(color: kPrimary.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2))] : [],
              ),
              child: Text(s, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: isSelected ? Colors.white : kTextSecondary)),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ThresholdForm extends StatefulWidget {
  final String species;
  final Threshold? threshold;
  final bool saving;
  final String? successMsg;
  final String? errorMsg;
  final void Function(Threshold) onSave;
  final bool readOnly;

  const _ThresholdForm({
    required this.species,
    required this.threshold,
    required this.saving,
    required this.successMsg,
    required this.errorMsg,
    required this.onSave,
    this.readOnly = false,
  });

  @override
  State<_ThresholdForm> createState() => _ThresholdFormState();
}

class _ThresholdFormState extends State<_ThresholdForm> {
  late _RangeController _temp;
  late _RangeController _turb;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  @override
  void didUpdateWidget(_ThresholdForm old) {
    super.didUpdateWidget(old);
    if (old.species != widget.species || old.threshold != widget.threshold) {
      _disposeControllers();
      _initControllers();
    }
  }

  void _initControllers() {
    final t = widget.threshold;
    _temp = _RangeController(min: t?.minTemperature ?? 10, max: t?.maxTemperature ?? 20);
    _turb = _RangeController(min: t?.minTurbidity ?? 0, max: t?.maxTurbidity ?? 50);
  }

  void _disposeControllers() {
    _temp.dispose();
    _turb.dispose();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  bool get _isValid => _temp.isValid && _turb.isValid;

  double get _calculatedIca {
    final maxTemp = _temp.maxVal;
    final minTemp = _temp.minVal;
    final maxDev = (maxTemp - 25.0).abs();
    final minDev = (minTemp - 25.0).abs();
    final tempDev = maxDev > minDev ? maxDev : minDev;

    final tempScore = (100.0 - tempDev * 10.0).clamp(0.0, 100.0);
    // Turbidity voltage limit always scores 100.0 directly on the edge.
    final turbScore = 100.0;

    final ica = (tempScore * 0.40) + (turbScore * 0.60);
    return ica.clamp(0.0, 100.0);
  }

  void _submit() {
    if (!_isValid) return;
    final updated = Threshold(
      id: widget.threshold?.id ?? 0,
      species: widget.species,
      minTemperature: _temp.minVal,
      maxTemperature: _temp.maxVal,
      minTurbidity: _turb.minVal,
      maxTurbidity: _turb.maxVal,
    );
    widget.onSave(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: _ParamCard(
          icon: Icons.thermostat_outlined,
          label: 'Temperatura',
          unit: '°C',
          color: const Color(0xFFEF4444),
          controller: _temp,
          readOnly: widget.readOnly,
          onChanged: () => setState(() {}),
        )),
        const SizedBox(width: 16),
        Expanded(child: _ParamCard(
          icon: Icons.water_drop_outlined,
          label: 'Turbidez',
          unit: '%',
          color: const Color(0xFF0EA5E9),
          controller: _turb,
          readOnly: widget.readOnly,
          onChanged: () => setState(() {}),
        )),
      ]),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3))),
        child: Row(children: [
          const Icon(Icons.analytics_outlined, color: Color(0xFF10B981)),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Rango de ICA Aceptable (Estimado)', style: TextStyle(fontSize: 12, color: kTextSecondary)),
            Text('${_calculatedIca.toStringAsFixed(1)} - 100.0 pts', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
            const SizedBox(height: 4),
            const Text('Si sale de los límites, el puntaje bajará gradualmente.', style: TextStyle(fontSize: 11, color: kTextSecondary)),
          ]),
        ]),
      ),
      const SizedBox(height: 24),
      if (widget.successMsg != null)
        _Banner(message: widget.successMsg!, isError: false),
      if (widget.errorMsg != null)
        _Banner(message: widget.errorMsg!, isError: true),
      if (widget.successMsg != null || widget.errorMsg != null) const SizedBox(height: 12),
      if (!widget.readOnly)
        Row(children: [
          ElevatedButton.icon(
            onPressed: (widget.saving || !_isValid) ? null : _submit,
            icon: widget.saving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save_outlined, size: 18),
            label: Text(widget.saving ? 'Guardando...' : 'Guardar parámetros'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
          ),
          if (!_isValid) ...[
            const SizedBox(width: 12),
            const Text('El mínimo no puede ser mayor que el máximo', style: TextStyle(color: kError, fontSize: 12)),
          ],
        ]),
    ]);
  }
}

class _ParamCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String unit;
  final Color color;
  final _RangeController controller;
  final VoidCallback onChanged;
  final bool readOnly;

  const _ParamCard({
    required this.icon,
    required this.label,
    required this.unit,
    required this.color,
    required this.controller,
    required this.onChanged,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kTextPrimary)),
              Text('en $unit', style: const TextStyle(fontSize: 11, color: kTextSecondary)),
            ]),
          ]),
          const SizedBox(height: 20),
          _RangeField(
            label: 'Mínimo',
            controller: controller.minCtrl,
            hasError: !controller.isValid,
            readOnly: readOnly,
            onChanged: (_) => onChanged(),
          ),
          const SizedBox(height: 12),
          _RangeField(
            label: 'Máximo',
            controller: controller.maxCtrl,
            hasError: !controller.isValid,
            readOnly: readOnly,
            onChanged: (_) => onChanged(),
          ),
          if (!controller.isValid) ...[
            const SizedBox(height: 8),
            Text('Min debe ser menor que Max', style: TextStyle(fontSize: 11, color: kError)),
          ],
        ]),
      ),
    );
  }
}

class _RangeField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool hasError;
  final ValueChanged<String> onChanged;
  final bool readOnly;

  const _RangeField({required this.label, required this.controller, required this.hasError, required this.onChanged, this.readOnly = false});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kTextSecondary, letterSpacing: 0.5)),
      const SizedBox(height: 4),
      TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: onChanged,
        readOnly: readOnly,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: hasError ? kError : kBorder)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: hasError ? kError : kBorder)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: hasError ? kError : kPrimary)),
        ),
      ),
    ]);
  }
}

class _Banner extends StatelessWidget {
  final String message;
  final bool isError;
  const _Banner({required this.message, required this.isError});

  @override
  Widget build(BuildContext context) {
    final color = isError ? kError : kSuccess;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Row(children: [
        Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: color, size: 18),
        const SizedBox(width: 10),
        Text(message, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
      ]),
    );
  }
}

class _RangeController {
  final TextEditingController minCtrl;
  final TextEditingController maxCtrl;

  _RangeController({required double min, required double max})
      : minCtrl = TextEditingController(text: min.toString()),
        maxCtrl = TextEditingController(text: max.toString());

  double get minVal => double.tryParse(minCtrl.text) ?? 0;
  double get maxVal => double.tryParse(maxCtrl.text) ?? 0;
  bool get isValid => minVal <= maxVal;

  void dispose() {
    minCtrl.dispose();
    maxCtrl.dispose();
  }
}
