import 'plan.dart';

class Subscription {
  final int id;
  final int userId;
  final int planId;
  final String status;
  final DateTime? currentPeriodStart;
  final DateTime? currentPeriodEnd;

  const Subscription({
    required this.id,
    required this.userId,
    required this.planId,
    required this.status,
    this.currentPeriodStart,
    this.currentPeriodEnd,
  });

  factory Subscription.fromJson(Map<String, dynamic> j) => Subscription(
    id: j['id'] as int? ?? 0,
    userId: j['userId'] as int? ?? 0,
    planId: j['planId'] as int? ?? 0,
    status: j['status']?.toString() ?? '',
    currentPeriodStart: j['currentPeriodStart'] != null ? DateTime.tryParse(j['currentPeriodStart'].toString()) : null,
    currentPeriodEnd: j['currentPeriodEnd'] != null ? DateTime.tryParse(j['currentPeriodEnd'].toString()) : null,
  );

  bool get isActive => status == 'ACTIVE' || status == 'TRIALING';
}
