import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../services/auth_state.dart';

// ── Client Portal Shell with Bottom Navigation ───────────────────────────────
// Tabs: Home | Orders | Vault | Discover | Profile

import 'orders_screen.dart';
import 'vault_screen.dart';
import 'discover_screen.dart';
import 'profile_screen.dart';

class ClientPortalScreen extends ConsumerStatefulWidget {
  const ClientPortalScreen({super.key});
  @override
  ConsumerState<ClientPortalScreen> createState() => _ClientPortalScreenState();
}

class _ClientPortalScreenState extends ConsumerState<ClientPortalScreen> {
  int _tab = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      _ClientHomeTab(onNavigateTab: (index) => setState(() => _tab = index)),
      const OrdersHistoryScreen(),
      const MeasurementVaultScreen(),
      DiscoverScreen(),
      ClientProfileScreen(onNavigateTab: (index) => setState(() => _tab = index)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1923),
      body: IndexedStack(index: _tab, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF131E2E),
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: Row(
              children: [
                _NavItem(icon: Icons.home_outlined,       activeIcon: Icons.home_rounded,       label: 'Home',     index: 0, current: _tab, onTap: (i) => setState(() => _tab = i)),
                _NavItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long_rounded, label: 'Orders',   index: 1, current: _tab, onTap: (i) => setState(() => _tab = i)),
                _NavItem(icon: Icons.straighten_outlined, activeIcon: Icons.straighten_rounded,  label: 'Vault',    index: 2, current: _tab, onTap: (i) => setState(() => _tab = i)),
                _NavItem(icon: Icons.explore_outlined,    activeIcon: Icons.explore_rounded,     label: 'Discover', index: 3, current: _tab, onTap: (i) => setState(() => _tab = i)),
                _NavItem(icon: Icons.person_outline,      activeIcon: Icons.person_rounded,      label: 'Profile',  index: 4, current: _tab, onTap: (i) => setState(() => _tab = i)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Client Home Tab ──────────────────────────────────────────────────────────

class _ClientHomeTab extends ConsumerWidget {
  final ValueChanged<int> onNavigateTab;
  const _ClientHomeTab({required this.onNavigateTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1923),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // ── Header ──────────────────────────────────────────────────────
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Welcome back,', style: GoogleFonts.outfit(
                  color: Colors.white54, fontSize: 14,
                )),
                Text(user?.fullName ?? 'Client', style: GoogleFonts.outfit(
                  color: Colors.white, fontSize: 24,
                  fontWeight: FontWeight.w800, letterSpacing: -0.5,
                )),
              ])),
              GestureDetector(
                onTap: () async {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) context.go('/');
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.logout_rounded, color: Colors.white54, size: 20),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF2DD4BF).withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('ID: ${user?.readableId ?? '—'}', style: GoogleFonts.outfit(
                color: const Color(0xFF2DD4BF), fontWeight: FontWeight.w600, fontSize: 12,
              )),
            ),
            const SizedBox(height: 32),

            // ── Anonymous Track Bar ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A2B3C), Color(0xFF162233)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF2DD4BF), size: 20),
                  const SizedBox(width: 8),
                  Text('Track Any Order', style: GoogleFonts.outfit(
                    color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15,
                  )),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: TextField(
                      style: GoogleFonts.outfit(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Enter Order ID (e.g. CL-KHAN)',
                        hintStyle: GoogleFonts.outfit(color: Colors.white30, fontSize: 13),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.06),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      onSubmitted: (val) {
                        if (val.trim().isNotEmpty) {
                          context.push('/client/track?id=${val.trim()}');
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () => context.push('/client/track?id=CL-KHAN'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2DD4BF),
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Icon(Icons.arrow_forward_rounded, size: 18),
                  ),
                ]),
              ]),
            ),
            const SizedBox(height: 28),

            // ── Quick Actions ────────────────────────────────────────────────
            Text('Quick Actions', style: GoogleFonts.outfit(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16,
            )),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.6,
              children: [
                _QuickAction(
                  icon: Icons.receipt_long_rounded,
                  label: 'My Orders',
                  color: const Color(0xFF6366F1),
                  onTap: () => onNavigateTab(1),
                ),
                _QuickAction(
                  icon: Icons.straighten_rounded,
                  label: 'Vault',
                  color: AppTheme.accentGold,
                  onTap: () => onNavigateTab(2),
                ),
                _QuickAction(
                  icon: Icons.explore_rounded,
                  label: 'Find Tailor',
                  color: const Color(0xFF2DD4BF),
                  onTap: () => onNavigateTab(3),
                ),
                _QuickAction(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Chat',
                  color: AppTheme.successGreen,
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Chat coming in v1.1', style: GoogleFonts.outfit())),
                  ),
                ),
              ],
            ),
          ]),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon, required this.label,
    required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 22),
          const Spacer(),
          Text(label, style: GoogleFonts.outfit(
            color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13,
          )),
        ]),
      ),
    );
  }
}

// ── Bottom Nav Item ──────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int current;
  final void Function(int) onTap;

  const _NavItem({
    required this.icon, required this.activeIcon, required this.label,
    required this.index, required this.current, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == current;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(index),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(
            isActive ? activeIcon : icon,
            size: 22,
            color: isActive ? const Color(0xFF2DD4BF) : Colors.white38,
          ),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.outfit(
            fontSize: 10,
            color: isActive ? const Color(0xFF2DD4BF) : Colors.white38,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
          )),
        ]),
      ),
    );
  }
}
