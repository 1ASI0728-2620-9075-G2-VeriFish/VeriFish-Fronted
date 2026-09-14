import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../domain/notification.dart';
import '../../../infrastructure/auth_provider.dart';
import '../../../infrastructure/notification_service.dart';
import '../../widgets/dashboard_layout.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});
  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<AppNotification> _notifications = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final userId = context.read<AuthProvider>().user?.id ?? 0;
    try {
      final ns = await getNotifications(userId);
      setState(() { _notifications = ns; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  Future<void> _markAllRead() async {
    final userId = context.read<AuthProvider>().user?.id ?? 0;
    await markAllRead(userId);
    _load();
  }

  IconData _icon(String type) {
    final t = type.toUpperCase();
    if (t.contains('TEMP')) return Icons.thermostat_outlined;
    if (t.contains('PH')) return Icons.science_outlined;
    if (t.contains('HARDWARE') || t.contains('MAINT')) return Icons.build_outlined;
    if (t.contains('OPERATOR') || t.contains('USER')) return Icons.person_outline;
    return Icons.warning_amber_outlined;
  }

  Color _color(AppNotification n) => n.isCritical ? kError : n.type.toUpperCase().contains('OPERATOR') ? kPrimary : kWarning;

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      currentRoute: '/notificaciones',
      child: _loading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Notificaciones', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: kTextPrimary)),
                      Text('Alertas y eventos del sistema', style: TextStyle(color: kTextSecondary, fontSize: 14)),
                    ]),
                    if (_notifications.isNotEmpty)
                      TextButton.icon(onPressed: _markAllRead, icon: const Icon(Icons.done_all, size: 18), label: const Text('Marcar todas leídas')),
                  ]),
                  const SizedBox(height: 24),
                  if (_notifications.isEmpty)
                    Card(child: Padding(padding: const EdgeInsets.all(40), child: Center(child: Column(children: [
                      Icon(Icons.notifications_none, size: 48, color: kTextSecondary.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      const Text('Sin notificaciones', style: TextStyle(color: kTextSecondary, fontSize: 16)),
                    ]))))
                  else
                    Card(child: Column(children: _notifications.asMap().entries.map((e) {
                      final n = e.value;
                      final isLast = e.key == _notifications.length - 1;
                      final color = _color(n);
                      return Column(children: [
                        Padding(padding: const EdgeInsets.all(16), child: Row(children: [
                          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(_icon(n.type), color: color, size: 20)),
                          const SizedBox(width: 14),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(n.type, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kTextPrimary)),
                            const SizedBox(height: 2),
                            Text(n.message, style: const TextStyle(fontSize: 13, color: kTextSecondary)),
                            const SizedBox(height: 4),
                            Text(n.relativeTime, style: const TextStyle(fontSize: 11, color: kTextSecondary)),
                          ])),
                          if (n.isCritical)
                            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: kError.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: const Text('CRÍTICA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: kError))),
                        ])),
                        if (!isLast) const Divider(height: 1),
                      ]);
                    }).toList())),
                ]),
              ),
            ),
    );
  }
}
