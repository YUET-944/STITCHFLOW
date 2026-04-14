import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../services/auth_state.dart';

import 'dashboard_screen.dart' show TailorDashboardScreen;
import 'booking_queue_screen.dart';
import 'staff_screen.dart';
import 'tailor_profile_screen.dart';

// ── Tailor App Shell with Bottom Navigation ──────────────────────────────────
// Tabs: Dashboard | Queue | Staff | Profile

class TailorShellScreen extends ConsumerStatefulWidget {
  const TailorShellScreen({super.key});
  @override
  ConsumerState<TailorShellScreen> createState() => _TailorShellScreenState();
}

class _TailorShellScreenState extends ConsumerState<TailorShellScreen> {
  int _tab = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const TailorDashboardScreen(),
      const BookingQueueScreen(),
      const StaffManagementScreen(),
      TailorProfileScreen(onNavigateTab: (index) => setState(() => _tab = index)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: IndexedStack(index: _tab, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.primaryDeepNavy,
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, -2)),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: Row(children: [
              _TailorNavItem(icon: Icons.dashboard_outlined,  activeIcon: Icons.dashboard_rounded,   label: 'Dashboard', index: 0, current: _tab, onTap: (i) => setState(() => _tab = i)),
              _TailorNavItem(icon: Icons.inbox_outlined,      activeIcon: Icons.inbox_rounded,        label: 'Queue',     index: 1, current: _tab, onTap: (i) => setState(() => _tab = i), badge: true),
              _TailorNavItem(icon: Icons.groups_outlined,     activeIcon: Icons.groups_rounded,       label: 'Staff',     index: 2, current: _tab, onTap: (i) => setState(() => _tab = i)),
              _TailorNavItem(icon: Icons.person_outline,      activeIcon: Icons.person_rounded,       label: 'Profile',   index: 3, current: _tab, onTap: (i) => setState(() => _tab = i)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _TailorNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int current;
  final void Function(int) onTap;
  final bool badge;

  const _TailorNavItem({
    required this.icon, required this.activeIcon, required this.label,
    required this.index, required this.current, required this.onTap,
    this.badge = false,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == current;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(index),
        child: Stack(alignment: Alignment.center, children: [
          Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(
              isActive ? activeIcon : icon,
              size: 22,
              color: isActive ? AppTheme.accentGold : Colors.white38,
            ),
            const SizedBox(height: 4),
            Text(label, style: GoogleFonts.outfit(
              fontSize: 10,
              color: isActive ? AppTheme.accentGold : Colors.white38,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
            )),
          ]),
          if (badge)
            Positioned(
              top: 8, right: 20,
              child: Container(
                width: 8, height: 8,
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ]),
      ),
    );
  }
}
