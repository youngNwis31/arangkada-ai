import 'package:flutter/material.dart';
import '../config/theme/malate_colors.dart';
import '../config/theme/malate_typography.dart';
import 'home_screen.dart';
import 'dashboard_screen.dart';
import 'earnings_screen.dart';
import 'settings_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  static const _screens = <Widget>[
    HomeScreen(),
    DashboardScreen(),
    EarningsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final c = MalateColors.of(context);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: c.asphalt,
          border: Border(
            top: BorderSide(color: c.sidewalk, width: 0.5),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(0, Icons.map_outlined, Icons.map, 'Map'),
                _navItem(
                    1, Icons.dashboard_outlined, Icons.dashboard, 'Dashboard'),
                _navItem(2, Icons.account_balance_wallet_outlined,
                    Icons.account_balance_wallet, 'Earnings'),
                _navItem(3, Icons.settings_outlined, Icons.settings, 'Settings'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(
      int index, IconData icon, IconData activeIcon, String label) {
    final isActive = _currentIndex == index;
    final color = isActive ? MalateColors.neonMint : MalateColors.of(context).textMuted;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isActive ? 48 : 0,
              height: 3,
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: MalateColors.neonMint,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Icon(
              isActive ? activeIcon : icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: MalateTypography.labelSmall.copyWith(
                color: color,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
