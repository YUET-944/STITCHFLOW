import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/api_client.dart';
import '../../services/auth_state.dart';
import '../../core/theme.dart';

class TailorProfileScreen extends ConsumerStatefulWidget {
  final ValueChanged<int>? onNavigateTab;
  const TailorProfileScreen({super.key, this.onNavigateTab});
  @override
  ConsumerState<TailorProfileScreen> createState() => _TailorProfileScreenState();
}

class _TailorProfileScreenState extends ConsumerState<TailorProfileScreen> {
  int _maxOrders = 10;
  String _availability = 'ACTIVE';
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: AppTheme.primaryDeepNavy,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDeepNavy,
        elevation: 0,
        title: Text('My Profile', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white54),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/');
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // ── ID Card ─────────────
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1F3550), Color(0xFF0E1E2F)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.accentGold.withOpacity(0.4)),
            ),
            child: Column(children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: AppTheme.accentGold.withOpacity(0.15),
                child: Text(
                  user?.fullName.isNotEmpty == true ? user!.fullName[0].toUpperCase() : 'T',
                  style: GoogleFonts.outfit(color: AppTheme.accentGold, fontSize: 28, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 12),
              Text(user?.fullName ?? 'Tailor', style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
              Text(user?.username ?? '', style: GoogleFonts.outfit(color: Colors.white60)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.accentGold.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.accentGold.withOpacity(0.4)),
                ),
                child: Text(user?.readableId ?? '—', style: GoogleFonts.outfit(
                  color: AppTheme.accentGold, fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: 2,
                )),
              ),
              const SizedBox(height: 16),
              if (user?.readableId.isNotEmpty == true)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                  child: QrImageView(data: user!.readableId, size: 100, version: QrVersions.auto),
                ),
            ]),
          ),
          const SizedBox(height: 24),
          // ── Capacity Settings ─────────────
          _sectionCard('Capacity Settings', [
            _label('Max Active Orders: $_maxOrders'),
            Slider(
              value: _maxOrders.toDouble(),
              min: 1, max: 50, divisions: 49,
              activeColor: AppTheme.accentGold,
              inactiveColor: Colors.white12,
              onChanged: (v) => setState(() => _maxOrders = v.round()),
              onChangeEnd: (v) => _saveCapacity(),
            ),
            _label('Availability'),
            const SizedBox(height: 8),
            Row(children: ['ACTIVE', 'ON_LEAVE', 'FULLY_BOOKED'].map((s) {
              final sel = _availability == s;
              return Expanded(child: GestureDetector(
                onTap: () { setState(() => _availability = s); _saveCapacity(); },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: sel ? AppTheme.accentGold.withOpacity(0.2) : Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: sel ? AppTheme.accentGold : Colors.white12),
                  ),
                  child: Text(s.split('_')[0], textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(color: sel ? AppTheme.accentGold : Colors.white54, fontSize: 12)),
                ),
              ));
            }).toList()),
          ]),
          const SizedBox(height: 12),
          // ── Quick Links ─────────────
          _profileTile(context, Icons.people_outline, 'Staff Management', 'Manage stitching masters',
              onTap: () { if (widget.onNavigateTab != null) widget.onNavigateTab!(2); }),
          _profileTile(context, Icons.photo_library_outlined, 'Portfolio Gallery', 'Manage your portfolio',
              onTap: () => context.push('/tailor/portfolio')),
          _profileTile(context, Icons.queue_outlined, 'Booking Queue', 'Approve incoming requests',
              onTap: () { if (widget.onNavigateTab != null) widget.onNavigateTab!(1); }),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/');
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.red.withOpacity(0.2)),
              ),
              child: Row(children: [
                const Icon(Icons.logout, color: Colors.redAccent, size: 20),
                const SizedBox(width: 12),
                Text('Sign Out', style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveCapacity() async {
    try {
      await ref.read(apiClientProvider).patch('/tailor/profile', data: {
        'max_active_orders': _maxOrders,
        'availability_status': _availability,
      });
    } catch (_) {}
  }

  Widget _sectionCard(String title, List<Widget> children) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.06),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withOpacity(0.07)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: GoogleFonts.outfit(color: Colors.white70, fontWeight: FontWeight.w600)),
      const SizedBox(height: 12),
      ...children,
    ]),
  );

  Widget _label(String text) => Text(text, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12));

  Widget _profileTile(BuildContext context, IconData icon, String title, String subtitle, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
        ),
        child: Row(children: [
          Icon(icon, color: Colors.white60, size: 22),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600)),
            Text(subtitle, style: GoogleFonts.outfit(color: const Color(0x66FFFFFF), fontSize: 12)),
          ])),
          const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
        ]),
      ),
    );
  }
}
