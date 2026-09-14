class Threshold {
  final int id;
  final String species;
  final double minTemperature;
  final double maxTemperature;
  final double minTurbidity;
  final double maxTurbidity;
  final double? ica;

  const Threshold({
    required this.id,
    required this.species,
    required this.minTemperature,
    required this.maxTemperature,
    required this.minTurbidity,
    required this.maxTurbidity,
    this.ica,
  });

  factory Threshold.fromJson(Map<String, dynamic> json) {
    return Threshold(
      id: json['id'],
      species: json['species'],
      minTemperature: (json['minTemperature'] as num).toDouble(),
      maxTemperature: (json['maxTemperature'] as num).toDouble(),
      minTurbidity: (json['minTurbidity'] as num).toDouble(),
      maxTurbidity: (json['maxTurbidity'] as num).toDouble(),
      ica: json['ica'] != null ? (json['ica'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'species': species,
      'minTemperature': minTemperature,
      'maxTemperature': maxTemperature,
      'minTurbidity': minTurbidity,
      'maxTurbidity': maxTurbidity,
      'ica': ica,
    };
  }

  Threshold copyWith({
    String? species,
    double? minTemperature,
    double? maxTemperature,
    double? minTurbidity,
    double? maxTurbidity,
    double? ica,
  }) => Threshold(
    id: id,
    species: species ?? this.species,
    minTemperature: minTemperature ?? this.minTemperature,
    maxTemperature: maxTemperature ?? this.maxTemperature,
    minTurbidity: minTurbidity ?? this.minTurbidity,
    maxTurbidity: maxTurbidity ?? this.maxTurbidity,
    ica: ica ?? this.ica,
  );
}
