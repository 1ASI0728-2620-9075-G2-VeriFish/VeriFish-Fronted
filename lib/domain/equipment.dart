class Equipment {
  final int id;
  final int farmId;
  final int? pondId;
  final String type;
  final String status;
  final String name;
  final String physicalCode;

  const Equipment({required this.id, required this.farmId, this.pondId, required this.type, required this.status, required this.name, required this.physicalCode});

  factory Equipment.fromJson(Map<String, dynamic> j) => Equipment(
    id: j['id'] as int,
    farmId: j['farmId'] as int? ?? 0,
    pondId: j['pondId'] as int?,
    type: j['type']?.toString() ?? '',
    status: j['status']?.toString() ?? '',
    name: j['name']?.toString() ?? '',
    physicalCode: j['physicalCode']?.toString() ?? '',
  );

  bool get isLinked => status == 'LINKED';
  bool get isSensor => type == 'SENSOR';
}
