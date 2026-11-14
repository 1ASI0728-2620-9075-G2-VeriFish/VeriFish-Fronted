import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../infrastructure/api_error.dart';
import '../../components/request_error.dart';
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
  String? _loadError;
  bool _showCreateFarm = false;
  final _farmNameCtrl = TextEditingController();
  final _farmAddressCtrl = TextEditingController();
  bool _creatingFarm = false;
  String? _createError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    final auth = context.read<AuthProvider>();
    final userId = auth.user?.id ?? 0;
    try {
      final farm = await getOwnedFarm(userId);
      if (!mounted) return;
      if (farm == null) {
        setState(() {
          _showCreateFarm = true;
          _loading = false;
        });
        return;
      }
      final results = await Future.wait([
        getPondsByFarm(farm.id),
        getNotifications(userId),
      ]);
      if (!mounted) return;
      setState(() {
        _ponds = results[0] as List<Pond>;
        _notifications = results[1] as List<AppNotification>;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = apiErrorMessage(
          error,
          fallback: 'No se pudo cargar la información. Intenta nuevamente.',
        );
      });
    }
  }

  Future<void> _createFarm() async {
    if (_creatingFarm) return;
    if (_farmNameCtrl.text.trim().isEmpty) {
      setState(
        () => _createError = 'Ingresa el nombre de la granja.',
      );
      return;
    }
    setState(() {
      _creatingFarm = true;
      _createError = null;
    });
    try {
      await createFarm(
        name: _farmNameCtrl.text.trim(),
        address: _farmAddressCtrl.text.trim(),
      );
      if (!mounted) return;
      await context.read<AuthProvider>().logout();
      if (mounted) context.go('/login');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _creatingFarm = false;
        _createError = apiErrorMessage(
          error,
          fallback: 'No se pudo crear la granja.',
        );
      });
    }
  }

  @override
  void dispose() {
    _farmNameCtrl.dispose();
    _farmAddressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return DashboardLayout(
      currentRoute: '/dashboard',
      child: Stack(
        children: [
          _loading
              ? const Center(child: CircularProgressIndicator(color: kPrimary))
              : _loadError != null
              ? RequestError(message: _loadError!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bienvenido, ${user?.firstName ?? ""}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: kTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Resumen de tu sistema acuícola',
                          style: TextStyle(color: kTextSecondary, fontSize: 14),
                        ),
                        const SizedBox(height: 24),
                        StatsGrid(
                          activePonds: _ponds
                              .where((p) => p.status == 'ACTIVE')
                              .length,
                          totalPonds: _ponds.length,
                          unreadAlerts: _notifications.length,
                        ),
                        const SizedBox(height: 24),
                        RecentAlerts(
                          notifications: _notifications.take(5).toList(),
                        ),
                        const SizedBox(height: 24),
                        PondsPreview(ponds: _ponds),
                      ],
                    ),
                  ),
                ),
          if (_showCreateFarm)
            CreateFarmModal(
              nameCtrl: _farmNameCtrl,
              addressCtrl: _farmAddressCtrl,
              loading: _creatingFarm,
              error: _createError,
              onConfirm: _createFarm,
            ),
        ],
      ),
    );
  }
}
