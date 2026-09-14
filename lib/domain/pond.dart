class Pond {
  final int id;
  final int farmId;
  final String name;
  final String species;
  final double volume;
  final String status;
  final int? assignedOperatorId;

  const Pond({required this.id, required this.farmId, required this.name, required this.species, required this.volume, required this.status, this.assignedOperatorId});

  factory Pond.fromJson(Map<String, dynamic> j) => Pond(
    id: j['id'] as int,
    farmId: j['farmId'] as int? ?? 0,
    name: j['name']?.toString() ?? '',
    species: j['species']?.toString() ?? '',
    volume: (j['volume'] as num?)?.toDouble() ?? 0,
    status: j['status']?.toString() ?? 'ACTIVE',
    assignedOperatorId: (j['assignedOperatorId'] as num?)?.toInt(),
  );
}

class SensorReading {
  final String sensorType;
  final double value;
  final String unit;
  final String timestamp;

  const SensorReading({required this.sensorType, required this.value, required this.unit, required this.timestamp});

  factory SensorReading.fromJson(Map<String, dynamic> j) {
    final m = j['measurement'] as Map<String, dynamic>? ?? {};
    return SensorReading(
      sensorType: j['sensorType']?.toString() ?? '',
      value: (m['value'] as num?)?.toDouble() ?? 0,
      unit: m['unit']?.toString() ?? '',
      timestamp: j['timestamp']?.toString() ?? '',
    );
  }
}

class HistoricalReading {
  final String sensorType;
  final double avgValue;
  final String periodStart;

  const HistoricalReading({required this.sensorType, required this.avgValue, required this.periodStart});

  factory HistoricalReading.fromJson(Map<String, dynamic> j) => HistoricalReading(
    sensorType: j['sensorType']?.toString() ?? '',
    avgValue: (j['averageValue'] as num?)?.toDouble() ?? 0,
    periodStart: j['periodStart']?.toString() ?? '',
  );
}
