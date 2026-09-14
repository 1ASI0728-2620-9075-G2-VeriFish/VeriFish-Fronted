import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../infrastructure/auth_provider.dart';

class DashboardLayout extends StatelessWidget {
  final Widget child;
  final String currentRoute;

  const DashboardLayout({super.key, required this.child, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    return isMobile ? _MobileLayout(child: child, currentRoute: currentRoute) : _DesktopLayout(child: child, currentRoute: currentRoute);
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final String route;
  const _NavItem(this.label, this.icon, this.route);
}

const _navItems = [
  _NavItem('Dashboard', Icons.dashboard_outlined, '/dashboard'),
  _NavItem('Estanques', Icons.water_outlined, '/estanques'),
  _NavItem('Equipos', Icons.devices_outlined, '/equipos'),
  _NavItem('Operadores', Icons.people_outlined, '/operadores'),
  _NavItem('Suscripciones', Icons.workspace_premium_outlined, '/suscripciones'),
  _NavItem('Notificaciones', Icons.notifications_outlined, '/notificaciones'),
  _NavItem('Parámetros', Icons.tune_outlined, '/parametros'),
  _NavItem('Configuración', Icons.settings_outlined, '/configuracion'),
];

class _DesktopLayout extends StatelessWidget {
  final Widget child;
  final String currentRoute;
  const _DesktopLayout({required this.child, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 220,
            color: kNavy,
            child: Column(
              children: [
                const SizedBox(height: 24),
                Image.asset('assets/images/yaku-logo.png', height: 64),
                const SizedBox(height: 32),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: _navItems.map((item) {
                      final selected = currentRoute.startsWith(item.route);
                      return _SidebarItem(item: item, selected: selected);
                    }).toList(),
                  ),
                ),
                if (user != null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: kPrimary,
                          radius: 18,
                          child: Text(
                            user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : '?',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.fullName, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                              Text(user.role, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout, color: Color(0xFF94A3B8), size: 18),
                          onPressed: () async {
                            await auth.logout();
                            if (context.mounted) context.go('/login');
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  const _SidebarItem({required this.item, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: selected ? kPrimary.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(item.icon, color: selected ? kPrimary : const Color(0xFF94A3B8), size: 20),
        title: Text(
          item.label,
          style: TextStyle(
            color: selected ? kPrimary : const Color(0xFF94A3B8),
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: () => context.go(item.route),
      ),
    );
  }
}



class _MobileLayout extends StatelessWidget {
  final Widget child;
  final String currentRoute;
  const _MobileLayout({required this.child, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final currentIndex = _navItems.indexWhere((i) => currentRoute.startsWith(i.route));
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex < 0 ? 0 : currentIndex,
        selectedItemColor: kPrimary,
        unselectedItemColor: const Color(0xFF94A3B8),
        type: BottomNavigationBarType.fixed,
        items: _navItems.map((i) => BottomNavigationBarItem(icon: Icon(i.icon), label: i.label)).toList(),
        onTap: (i) => context.go(_navItems[i].route),
      ),
    );
  }
}
