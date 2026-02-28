import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/notification_bell.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../auth/data/auth_provider.dart';

class DashboardShell extends ConsumerStatefulWidget {
  final Widget child;

  const DashboardShell({super.key, required this.child});

  @override
  ConsumerState<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends ConsumerState<DashboardShell> {
  static const _navItems = [
    _NavItem(icon: Icons.dashboard_rounded, label: 'Tableau de bord'),
    _NavItem(icon: Icons.people_rounded, label: 'Producteurs'),
    _NavItem(icon: Icons.map_rounded, label: 'Parcelles'),
    _NavItem(icon: Icons.water_drop_rounded, label: 'Forages'),
    _NavItem(icon: Icons.inventory_2_rounded, label: 'Kits'),
    _NavItem(icon: Icons.school_rounded, label: 'Formations'),
    _NavItem(icon: Icons.account_balance_wallet_rounded, label: 'Finances'),
    _NavItem(icon: Icons.handshake_rounded, label: 'Investisseurs'),
  ];

  static const _routes = [
    '/dashboard', '/producers', '/parcels', '/boreholes',
    '/kits', '/trainings', '/finances', '/investors',
  ];

  int _selectedIndexFromLocation(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    for (int i = _routes.length - 1; i >= 0; i--) {
      if (location.startsWith(_routes[i])) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= 1024;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    final user = ref.watch(authProvider).user;
    final selectedIndex = _selectedIndexFromLocation(context);

    if (isDesktop) {
      return _buildDesktopLayout(user, selectedIndex);
    } else if (isTablet) {
      return _buildTabletLayout(user, selectedIndex);
    } else {
      return _buildMobileLayout(user, selectedIndex);
    }
  }

  Widget _buildDesktopLayout(Map<String, dynamic>? user, int selectedIndex) {
    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            width: 260,
            child: _buildSidebar(user, selectedIndex, expanded: true),
          ),
          Expanded(
            child: Column(
              children: [
                const OfflineBanner(),
                Expanded(child: widget.child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(Map<String, dynamic>? user, int selectedIndex) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: _onItemTapped,
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Icon(
                Icons.agriculture_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
            destinations: _navItems
                .map(
                  (item) => NavigationRailDestination(
                    icon: Icon(item.icon),
                    label: Text(item.label, style: const TextStyle(fontSize: 11)),
                  ),
                )
                .toList(),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: widget.child),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(Map<String, dynamic>? user, int selectedIndex) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_navItems[selectedIndex].label),
        actions: [
          const OfflineIndicator(),
          const NotificationBell(),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex.clamp(0, 4),
        onTap: _onItemTapped,
        items: _navItems
            .take(5)
            .map(
              (item) => BottomNavigationBarItem(
                icon: Icon(item.icon),
                label: item.label,
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildSidebar(Map<String, dynamic>? user, int selectedIndex, {bool expanded = true}) {
    return Container(
      color: const Color(0xFF1B5E20),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Icon(
                  Icons.agriculture_rounded,
                  color: Colors.white,
                  size: 40,
                ),
                if (expanded) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'YOB K Business',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (user != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      user['full_name'] as String? ?? '',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      user['role'] as String? ?? '',
                      style: TextStyle(
                        color: Colors.green[200],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
          const Divider(color: Colors.white24, height: 1),

          // Nav items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final isSelected = index == selectedIndex;

                return ListTile(
                  leading: Icon(
                    item.icon,
                    color: isSelected ? Colors.amber[300] : Colors.white70,
                  ),
                  title: expanded
                      ? Text(
                          item.label,
                          style: TextStyle(
                            color:
                                isSelected ? Colors.amber[300] : Colors.white70,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            fontSize: 14,
                          ),
                        )
                      : null,
                  selected: isSelected,
                  selectedTileColor: Colors.white.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  onTap: () => _onItemTapped(index),
                );
              },
            ),
          ),

          // Logout
          const Divider(color: Colors.white24, height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.white70),
            title: expanded
                ? const Text(
                    'Déconnexion',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  )
                : null,
            onTap: () => ref.read(authProvider.notifier).logout(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    if (index >= 0 && index < _routes.length) {
      context.go(_routes[index]);
    }
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem({required this.icon, required this.label});
}
