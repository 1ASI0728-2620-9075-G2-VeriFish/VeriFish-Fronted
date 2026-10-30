import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../infrastructure/api_error.dart';
import '../../../domain/equipment.dart';
import '../../../domain/pond.dart';
import '../../../infrastructure/equipment_service.dart';
import '../../../infrastructure/pond_service.dart';

class CreateEquipmentModal extends StatelessWidget {
  final TextEditingController nameCtrl, codeCtrl;
  final String type;
  final ValueChanged<String> onTypeChanged;
  final bool loading;
  final String? error;
  final VoidCallback onConfirm, onCancel;
  const CreateEquipmentModal({
    super.key,
    required this.nameCtrl,
    required this.codeCtrl,
    required this.type,
    required this.onTypeChanged,
    required this.loading,
    this.error,
    required this.onConfirm,
    required this.onCancel,
  });
  @override
  Widget build(BuildContext context) => Container(
    color: Colors.black54,
    child: Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Registrar Equipo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: kTextPrimary,
                  ),
                ),
                IconButton(onPressed: onCancel, icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'TIPO',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
                color: kTextSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _TypeBtn(
                    'SENSOR',
                    type == 'SENSOR',
                    () => onTypeChanged('SENSOR'),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _TypeBtn(
                    'ACTUATOR',
                    type == 'ACTUATOR',
                    () => onTypeChanged('ACTUATOR'),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _TypeBtn(
                    'IOT NODE',
                    type == 'IOT_NODE',
                    () => onTypeChanged('IOT_NODE'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: codeCtrl,
              decoration: const InputDecoration(labelText: 'Código físico'),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(error!, style: const TextStyle(color: kError)),
              ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: loading ? null : onConfirm,
                    child: loading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Registrar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _TypeBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TypeBtn(this.label, this.selected, this.onTap);
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFF0F9FF) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: selected ? kPrimary : kBorder,
          width: selected ? 2 : 1,
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: selected ? kPrimaryDark : kTextSecondary,
          ),
        ),
      ),
    ),
  );
}

class EquipmentDetailsModal extends StatelessWidget {
  final Equipment equipment;
  final VoidCallback onClose;
  final VoidCallback onLinkTap;

  const EquipmentDetailsModal({
    super.key,
    required this.equipment,
    required this.onClose,
    required this.onLinkTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Detalles del Equipo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: kTextPrimary,
                    ),
                  ),
                  IconButton(onPressed: onClose, icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 16),
              _DetailRow('ID', equipment.id.toString()),
              _DetailRow('Nombre', equipment.name),
              _DetailRow('Tipo', equipment.type),
              _DetailRow('Código', equipment.physicalCode),
              _DetailRow('Estado', equipment.status),
              if (equipment.pondId != null)
                _DetailRow('ID Estanque', equipment.pondId.toString()),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onLinkTap,
                icon: const Icon(Icons.link, size: 18),
                label: const Text('Linkear con Estanque'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label, value;
  const _DetailRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: kTextSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: kTextPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

class LinkPondModal extends StatefulWidget {
  final int farmId;
  final int equipmentId;
  final VoidCallback onClose;
  final VoidCallback onLinked;

  const LinkPondModal({
    super.key,
    required this.farmId,
    required this.equipmentId,
    required this.onClose,
    required this.onLinked,
  });

  @override
  State<LinkPondModal> createState() => _LinkPondModalState();
}

class _LinkPondModalState extends State<LinkPondModal> {
  List<Pond> _ponds = [];
  bool _loading = true;
  bool _linking = false;
  String? _error;
  Pond? _selectedPond;

  @override
  void initState() {
    super.initState();
    _loadPonds();
  }

  Future<void> _loadPonds() async {
    try {
      final ponds = await getPondsByFarm(widget.farmId);
      if (!mounted) return;
      setState(() {
        _ponds = ponds;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = apiErrorMessage(
          error,
          fallback:
              'No se pudieron cargar los estanques. Cierra y vuelve a intentar.',
        );
      });
    }
  }

  Future<void> _link() async {
    if (_selectedPond == null) return;
    setState(() {
      _linking = true;
      _error = null;
    });
    try {
      await linkEquipment(widget.equipmentId, _selectedPond!.id);
      if (mounted) widget.onLinked();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _linking = false;
        _error = apiErrorMessage(
          error,
          fallback: 'No se pudo vincular el equipo. Intenta nuevamente.',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Seleccionar Estanque',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: kTextPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_loading)
                const Center(child: CircularProgressIndicator(color: kPrimary))
              else if (_ponds.isEmpty)
                const Text(
                  'No hay estanques disponibles.',
                  style: TextStyle(color: kTextSecondary),
                )
              else
                DropdownButtonFormField<Pond>(
                  value: _selectedPond,
                  hint: const Text('Elige un estanque'),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: _ponds
                      .map(
                        (p) => DropdownMenuItem(value: p, child: Text(p.name)),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedPond = v),
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(_error!, style: const TextStyle(color: kError)),
                ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onClose,
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _linking || _selectedPond == null
                          ? null
                          : _link,
                      child: _linking
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Linkear'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
