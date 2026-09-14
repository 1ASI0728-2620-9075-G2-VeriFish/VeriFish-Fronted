import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';

class OperatorLayout extends StatelessWidget {
  final Widget child;
  final String currentRoute;
  const OperatorLayout({super.key, required this.child, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    const tabs = [
      _Tab('Inicio', Icons.home_outlined, Icons.home, '/op/home'),
      _Tab('Alertas', Icons.notifications_outlined, Icons.notifications, '/op/alerts'),
      _Tab('Equipos', Icons.build_outlined, Icons.build, '/op/equipment'),
      _Tab('Perfil', Icons.person_outline, Icons.person, '/op/profile'),
    ];
    final idx = tabs.indexWhere((t) => currentRoute.startsWith(t.route));
    final currentIndex = idx < 0 ? 0 : idx;

    return Scaffold(
      backgroundColor: kBackground,
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: kNavy,
          border: Border(top: BorderSide(color: Color(0xFF1E293B))),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 68,
            child: Row(
              children: List.generate(tabs.length, (i) {
                final tab = tabs[i];
                final selected = i == currentIndex;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => context.go(tab.route),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (selected)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                            decoration: BoxDecoration(
                              color: kSuccess,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(tab.activeIcon, color: Colors.white, size: 20),
                          )
                        else
                          Icon(tab.icon, color: const Color(0xFF94A3B8), size: 22),
                        const SizedBox(height: 4),
                        Text(
                          tab.label,
                          style: TextStyle(
                            color: selected ? Colors.white : const Color(0xFF94A3B8),
                            fontSize: 11,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;
  const _Tab(this.label, this.icon, this.activeIcon, this.route);
}
