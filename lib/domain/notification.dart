class AppNotification {
  final int id;
  final String type;
  final String message;
  final String createdAt;
  final double? triggerTemperature;
  final double? triggerPh;
  final int? pondId;
  final String? pondName;

  const AppNotification({required this.id, required this.type, required this.message, required this.createdAt, this.triggerTemperature, this.triggerPh, this.pondId, this.pondName});

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
    id: j['id'] as int,
    type: j['type']?.toString() ?? '',
    message: j['message']?.toString() ?? '',
    createdAt: j['createdAt']?.toString() ?? '',
    triggerTemperature: (j['triggerTemperature'] as num?)?.toDouble(),
    triggerPh: (j['triggerPh'] as num?)?.toDouble(),
    pondId: (j['pondId'] as num?)?.toInt(),
    pondName: j['pondName']?.toString(),
  );

  String get relativeTime {
    try {
      final diff = DateTime.now().difference(DateTime.parse(createdAt));
      if (diff.inMinutes < 1) return 'Ahora';
      if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
      if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
      return 'Hace ${diff.inDays}d';
    } catch (_) { return ''; }
  }

  bool get isCritical => triggerTemperature != null || triggerPh != null;
}
