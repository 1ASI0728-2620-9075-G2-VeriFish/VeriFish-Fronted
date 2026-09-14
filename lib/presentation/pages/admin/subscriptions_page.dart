import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/theme.dart';
import '../../../domain/plan.dart';
import '../../../domain/subscription.dart';
import '../../../infrastructure/auth_provider.dart';
import '../../../infrastructure/subscription_service.dart';
import '../../widgets/dashboard_layout.dart';

class SubscriptionsPage extends StatefulWidget {
  const SubscriptionsPage({super.key});

  @override
  State<SubscriptionsPage> createState() => _SubscriptionsPageState();
}

class _SubscriptionsPageState extends State<SubscriptionsPage> {
  bool _loading = true;
  List<Plan> _plans = [];
  Subscription? _currentSubscription;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = context.read<AuthProvider>().user?.id ?? 0;
    try {
      final results = await Future.wait([
        getPlans(),
        getSubscription(userId),
      ]);
      if (mounted) {
        setState(() {
          _plans = results[0] as List<Plan>;
          _currentSubscription = results[1] as Subscription?;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _checkout(Plan plan) async {
    final userId = context.read<AuthProvider>().user?.id ?? 0;
    if (userId == 0) return;
    setState(() => _processing = true);
    try {
      final url = await checkoutSubscription(userId: userId, planId: plan.id);
      if (url.isNotEmpty) {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, webOnlyWindowName: '_blank');
        }
      }
    } catch (_) {
      // Ignorar errores
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      currentRoute: '/suscripciones',
      child: _loading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Planes y Suscripción', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: kTextPrimary)),
                  const Text('Mejora tu plan para gestionar más estanques', style: TextStyle(color: kTextSecondary, fontSize: 14)),
                  const SizedBox(height: 32),
                  if (_plans.isEmpty)
                    const Text('No hay planes disponibles', style: TextStyle(color: kTextSecondary))
                  else
                    Wrap(
                      spacing: 24,
                      runSpacing: 24,
                      children: _plans.map((plan) {
                        final isCurrent = _currentSubscription?.planId == plan.id && _currentSubscription?.isActive == true;
                        
                        return Container(
                          width: 320,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isCurrent ? kPrimary : kBorder, width: isCurrent ? 2 : 1),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isCurrent)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(color: kPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                                  child: const Text('TU PLAN ACTUAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: kPrimary)),
                                ),
                              Text(plan.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kNavy)),
                              const SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text('\$${plan.price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: kTextPrimary)),
                                  Text(' ${plan.currency}', style: const TextStyle(fontSize: 14, color: kTextSecondary, fontWeight: FontWeight.w600)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _FeatureRow(icon: Icons.water, text: 'Hasta ${plan.maxPonds} estanques'),
                              _FeatureRow(icon: Icons.calendar_month, text: 'Válido por ${plan.durationInDays} días'),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: (isCurrent || _processing) ? null : () => _checkout(plan),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isCurrent ? kBackground : kPrimary,
                                    foregroundColor: isCurrent ? kTextSecondary : Colors.white,
                                    elevation: isCurrent ? 0 : 2,
                                  ),
                                  child: _processing
                                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                      : Text(isCurrent ? 'Activo' : 'Elegir Plan'),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: kPrimary),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(color: kTextSecondary, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
