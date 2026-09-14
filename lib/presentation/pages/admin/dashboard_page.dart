import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../domain/notification.dart';
import '../../../domain/pond.dart';
import '../../../infrastructure/auth_provider.dart';
import '../../../infrastructure/farm_service.dart';
import '../../../infrastructure/notification_service.dart';
import '../../../infrastructure/pond_service.dart';
import '../../components/dashboard/dashboard_widgets.dart';
import '../../widgets/dashboard_layout.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<Pond> _ponds = [];
  List<AppNotification> _notifications = [];
  bool _loading = true;
  bool _showCreateFarm = false;
  final _farmNameCtrl = TextEditingController();
  final _farmAddressCtrl = TextEditingController();
  bool _creatingFarm = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    final userId = auth.user?.id ?? 0;
    try {
      final farm = await getUserFarm(userId);
      if (farm == null) {
        setState(() { _showCreateFarm = true; _loading = false; });
        return;
      }
      final results = await Future.wait([getPondsByFarm(farm.id), getNotifications(userId)]);
      setState(() {
        _ponds = results[0] as List<Pond>;
        _notifications = results[1] as List<AppNotification>;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _createFarm() async {
    if (_farmNameCtrl.text.trim().isEmpty) return;
    setState(() => _creatingFarm = true);
    try {
      await createFarm(name: _farmNameCtrl.text.trim(), address: _farmAddressCtrl.text.trim());
      setState(() { _showCreateFarm = false; _creatingFarm = false; });
      _load();
    } catch (_) { setState(() => _creatingFarm = false); }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return DashboardLayout(
      currentRoute: '/dashboard',
      child: Stack(children: [
        _loading
            ? const Center(child: CircularProgressIndicator(color: kPrimary))
            : RefreshIndicator(
                onRefresh: _load,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Bienvenido, ${user?.firstName ?? ""}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: kTextPrimary)),
                    const SizedBox(height: 4),
                    const Text('Resumen de tu sistema acuícola', style: TextStyle(color: kTextSecondary, fontSize: 14)),
                    const SizedBox(height: 24),
                    StatsGrid(activePonds: _ponds.where((p) => p.status == 'ACTIVE').length, totalPonds: _ponds.length, unreadAlerts: _notifications.length),
                    const SizedBox(height: 24),
                    RecentAlerts(notifications: _notifications.take(5).toList()),
                    const SizedBox(height: 24),
                    PondsPreview(ponds: _ponds),
                  ]),
                ),
              ),
        if (_showCreateFarm) CreateFarmModal(nameCtrl: _farmNameCtrl, addressCtrl: _farmAddressCtrl, loading: _creatingFarm, onConfirm: _createFarm),
      ]),
    );
  }
}
