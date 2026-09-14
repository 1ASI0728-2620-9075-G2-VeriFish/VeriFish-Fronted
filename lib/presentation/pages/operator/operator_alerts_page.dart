import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../infrastructure/auth_provider.dart';
import '../../../infrastructure/notification_service.dart';
import '../../../domain/notification.dart';
import '../../widgets/operator_layout.dart';

class OperatorAlertsPage extends StatefulWidget {
  const OperatorAlertsPage({super.key});
  @override
  State<OperatorAlertsPage> createState() => _State();
}

class _State extends State<OperatorAlertsPage> {
  List<AppNotification> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = context.read<AuthProvider>().user?.id ?? 0;
    setState(() => _loading = true);
    try {
      final notifs = await getNotifications(userId);
      if (mounted) setState(() { _notifications = notifs; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markAllRead() async {
    final userId = context.read<AuthProvider>().user?.id ?? 0;
    await markAllRead(userId);
    _load();
  }

  bool _isToday(String timestamp) {
    try {
      final dt = DateTime.parse(timestamp).toLocal();
      final now = DateTime.now();
      return dt.year == now.year && dt.month == now.month && dt.day == now.day;
    } catch (_) {
      return false;
    }
  }

  bool _isYesterday(String timestamp) {
    try {
      final dt = DateTime.parse(timestamp).toLocal();
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      return dt.year == yesterday.year && dt.month == yesterday.month && dt.day == yesterday.day;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final todayNotifs = _notifications.where((n) => _isToday(n.createdAt)).toList();
    final yesterdayNotifs = _notifications.where((n) => _isYesterday(n.createdAt)).toList();
    final olderNotifs = _notifications
        .where((n) => !_isToday(n.createdAt) && !_isYesterday(n.createdAt))
        .toList();

    return OperatorLayout(
      currentRoute: '/op/alerts',
      child: SafeArea(
        child: Column(children: [
          Container(
            color: kSurface,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('YakuControl',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kNavy)),
              Text('Hola, ${user?.firstName ?? ''}',
                  style: const TextStyle(fontSize: 14, color: kTextSecondary)),
            ]),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: kPrimary))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _notifications.isEmpty
                        ? const Center(
                            child: Text('Sin alertas por ahora',
                                style: TextStyle(color: kTextSecondary)))
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                            children: [
                              if (todayNotifs.isNotEmpty) ...[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('HOY',
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: kTextSecondary,
                                            letterSpacing: 1)),
                                    GestureDetector(
                                      onTap: _markAllRead,
                                      child: const Text('Marcar todas como leídas',
                                          style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: kSuccess)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ...todayNotifs.map((n) => _AlertCard(notif: n)),
                              ],
                              if (yesterdayNotifs.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                const Text('AYER',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: kTextSecondary,
                                        letterSpacing: 1)),
                                const SizedBox(height: 12),
                                ...yesterdayNotifs.map((n) => _AlertCard(notif: n)),
                              ],
                              if (olderNotifs.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                const Text('ANTERIOR',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: kTextSecondary,
                                        letterSpacing: 1)),
                                const SizedBox(height: 12),
                                ...olderNotifs.map((n) => _AlertCard(notif: n)),
                              ],
                            ],
                          ),
                  ),
          ),
        ]),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final AppNotification notif;
  const _AlertCard({required this.notif});

  _AlertStyle get _style {
    final t = notif.type.toUpperCase();
    if (t.contains('TURB')) {
      return _AlertStyle(
        barColor: kError,
        bgColor: const Color(0xFFFEF2F2),
        iconBg: const Color(0xFFFEE2E2),
        icon: Icons.warning_rounded,
        iconColor: kError,
        title: 'Turbidez Crítica',
        priority: 'Prioridad Alta',
        priorityColor: kError,
        priorityBg: const Color(0xFFFEE2E2),
      );
    }
    if (t.contains('TEMP')) {
      return _AlertStyle(
        barColor: kWarning,
        bgColor: const Color(0xFFFFFBEB),
        iconBg: const Color(0xFFFEF3C7),
        icon: Icons.thermostat_outlined,
        iconColor: kWarning,
        title: 'Temperatura Elevada',
        priority: 'Advertencia',
        priorityColor: kWarning,
        priorityBg: const Color(0xFFFEF3C7),
      );
    }

    return _AlertStyle(
      barColor: const Color(0xFFCBD5E1),
      bgColor: kSurface,
      iconBg: kBackground,
      icon: Icons.check_circle_outline,
      iconColor: kTextSecondary,
      title: _alertTitle,
      priority: null,
      priorityColor: null,
      priorityBg: null,
    );
  }

  String get _alertTitle {
    final t = notif.type.toUpperCase();
    if (t.contains('MAINT')) return 'Mantenimiento Completado';
    if (t.contains('SENSOR')) return 'Sensor Desconectado';
    return notif.type;
  }

  String get _formattedTime {
    try {
      final dt = DateTime.parse(notif.createdAt).toLocal();
      final m = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour < 12 ? 'AM' : 'PM';
      return '${dt.hour % 12 == 0 ? 12 : dt.hour % 12}:$m $period';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _style;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: s.bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            width: 4,
            decoration: BoxDecoration(
              color: s.barColor,
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(color: s.iconBg, borderRadius: BorderRadius.circular(10)),
                  child: Icon(s.icon, color: s.iconColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(
                        child: Text(s.title,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold, color: kNavy)),
                      ),
                      Text(_formattedTime,
                          style: const TextStyle(fontSize: 11, color: kTextSecondary)),
                      if (notif.isCritical)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Container(
                            width: 8, height: 8,
                            decoration: const BoxDecoration(color: kError, shape: BoxShape.circle),
                          ),
                        ),
                    ]),
                    const SizedBox(height: 4),
                    Text(notif.message,
                        style: const TextStyle(fontSize: 13, color: kTextSecondary, height: 1.4)),
                    const SizedBox(height: 8),
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: kNavy,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(notif.pondName ?? (notif.pondId != null ? 'Estanque #${notif.pondId}' : 'Estanque'),
                            style: const TextStyle(fontSize: 11, color: Colors.white,
                                fontWeight: FontWeight.w600)),
                      ),
                      if (s.priority != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: s.priorityBg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(s.priority!,
                              style: TextStyle(fontSize: 11, color: s.priorityColor,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ]),
                  ]),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

class _AlertStyle {
  final Color barColor;
  final Color bgColor;
  final Color iconBg;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? priority;
  final Color? priorityColor;
  final Color? priorityBg;

  const _AlertStyle({
    required this.barColor,
    required this.bgColor,
    required this.iconBg,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.priority,
    required this.priorityColor,
    required this.priorityBg,
  });
}
