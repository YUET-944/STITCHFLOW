import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/auth_state.dart';
import '../../core/theme.dart';

class ClientProfileScreen extends ConsumerWidget {
  final ValueChanged<int>? onNavigateTab;
  
  const ClientProfileScreen({super.key, this.onNavigateTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1923),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1923),
        elevation: 0,
        title: Text('Profile', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600)),
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
          // ── ID Card ────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF1E3A5F), const Color(0xFF0F2849)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF2DD4BF).withOpacity(0.4)),
            ),
            child: Column(children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: const Color(0xFF2DD4BF).withOpacity(0.2),
                child: Text(
                  user?.fullName.isNotEmpty == true ? user!.fullName[0].toUpperCase() : '?',
                  style: GoogleFonts.outfit(color: const Color(0xFF2DD4BF), fontSize: 28, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 12),
              Text(user?.fullName ?? 'Client', style: GoogleFonts.outfit(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700,
              )),
              const SizedBox(height: 4),
              Text(user?.username ?? '', style: GoogleFonts.outfit(color: Colors.white60)),
              const SizedBox(height: 16),
              // Readable ID badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2DD4BF).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF2DD4BF).withOpacity(0.4)),
                ),
                child: Text(user?.readableId ?? '—', style: GoogleFonts.outfit(
                  color: const Color(0xFF2DD4BF), fontWeight: FontWeight.w700, fontSize: 18, letterSpacing: 2,
                )),
              ),
              const SizedBox(height: 16),
              // QR Code
              if (user?.readableId.isNotEmpty == true)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: QrImageView(
                    data: user!.readableId,
                    version: QrVersions.auto,
                    size: 120,
                  ),
                ),
              const SizedBox(height: 8),
              Text('Share your QR for easy lookup', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12)),
            ]),
          ),
          const SizedBox(height: 24),
          // ── Actions ────────────────────────────────────────────────────
          _profileTile(context, Icons.straighten, 'Measurement Vault', 'View & export your body measurements',
              onTap: () { if (onNavigateTab != null) onNavigateTab!(2); }),
          _profileTile(context, Icons.receipt_long_outlined, 'My Orders', 'Full order history',
              onTap: () { if (onNavigateTab != null) onNavigateTab!(1); }),
          _profileTile(context, Icons.explore_outlined, 'Discover Tailors', 'Find tailors near you',
              onTap: () { if (onNavigateTab != null) onNavigateTab!(3); }),
          const SizedBox(height: 16),
          _profileTile(context, Icons.send_outlined, 'Request Measurement Update',
              'Ask your tailor to update your vault', onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Request sent to your primary tailor', style: GoogleFonts.outfit()),
              backgroundColor: AppTheme.primaryDeepNavy,
            ));
          }),
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

  Widget _profileTile(BuildContext context, IconData icon, String title, String subtitle, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white70, size: 20),
          ),
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
