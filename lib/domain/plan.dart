class Plan {
  final int id;
  final String name;
  final double price;
  final String currency;
  final int maxPonds;
  final int durationInDays;

  const Plan({
    required this.id,
    required this.name,
    required this.price,
    required this.currency,
    required this.maxPonds,
    required this.durationInDays,
  });

  factory Plan.fromJson(Map<String, dynamic> j) => Plan(
    id: j['id'] as int,
    name: j['name']?.toString() ?? '',
    price: (j['price'] as num?)?.toDouble() ?? 0.0,
    currency: j['currency']?.toString() ?? 'USD',
    maxPonds: j['maxPonds'] as int? ?? 1,
    durationInDays: j['durationInDays'] as int? ?? 30,
  );
}
