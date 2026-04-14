import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../services/api_client.dart';
import '../../services/auth_state.dart';

/// Public tailor profile screen — shown when client taps a tailor card in Discover.
/// Fetches from GET /api/v1/tailors/:tailorId (public, no auth required for read).
class TailorDetailScreen extends ConsumerStatefulWidget {
  final String tailorId;
  const TailorDetailScreen({super.key, required this.tailorId});

  @override
  ConsumerState<TailorDetailScreen> createState() => _TailorDetailScreenState();
}

class _TailorDetailScreenState extends ConsumerState<TailorDetailScreen> {
  bool _loading = true;
  dynamic _tailor;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ref.read(apiClientProvider).get('/tailors/${widget.tailorId}');
      setState(() { _tailor = res.data; _loading = false; });
    } catch (e) {
      setState(() { _error = 'Could not load tailor profile'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = _tailor?['tailor_profile'] ?? {};
    final specs = (profile['specializations'] as List?) ?? [];
    final minPrice = profile['price_per_suit_min'];
    final maxPrice = profile['price_per_suit_max'];
    final used = (profile['current_active_orders'] as num?)?.toInt() ?? 0;
    final max  = (profile['max_active_orders']     as num?)?.toInt() ?? 10;
    final capacity = max > 0 ? used / max : 0.0;
    final isAvailable = profile['availability_status'] == 'ACTIVE';
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: AppTheme.primaryDeepNavy,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDeepNavy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => context.canPop() ? context.pop() : context.go('/client/portal'),
        ),
        title: Text('Tailor Profile', style: GoogleFonts.outfit(
          color: Colors.white, fontWeight: FontWeight.w600,
        )),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _buildProfile(profile, specs, minPrice, maxPrice, used, max, capacity, isAvailable, user),
    );
  }

  Widget _buildError() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.error_outline, color: Colors.white24, size: 52),
      const SizedBox(height: 16),
      Text(_error!, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 16)),
      const SizedBox(height: 20),
      ElevatedButton(
        onPressed: _load,
        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentGold),
        child: Text('Retry', style: GoogleFonts.outfit(color: Colors.black)),
      ),
    ]));
  }

  Widget _buildProfile(
    dynamic profile, List specs, dynamic minPrice, dynamic maxPrice,
    int used, int max, double capacity, bool isAvailable, AuthUser? user,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Hero Card ──────────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFF1A2535), Color(0xFF0D1F38)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.accentGold.withOpacity(0.3)),
          ),
          child: Row(children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: AppTheme.accentGold.withOpacity(0.15),
              child: Text(
                (profile['business_name'] ?? _tailor?['full_name'] ?? '?').toString()[0].toUpperCase(),
                style: GoogleFonts.outfit(color: AppTheme.accentGold, fontSize: 28, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                profile['business_name'] ?? _tailor?['full_name'] ?? 'Tailor',
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                _tailor?['readable_id'] ?? '',
                style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12, letterSpacing: 1),
              ),
              const SizedBox(height: 8),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isAvailable
                        ? AppTheme.successGreen.withOpacity(0.15)
                        : Colors.redAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isAvailable ? '● Available' : '● Fully Booked',
                    style: GoogleFonts.outfit(
                      color: isAvailable ? AppTheme.successGreen : Colors.redAccent,
                      fontSize: 11, fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ]),
            ])),
          ]),
        ),

        const SizedBox(height: 20),

        // ── Stats Row ──────────────────────────────────────────────────────────
        Row(children: [
          _statCard('Orders', '$used / $max', Icons.inbox_rounded),
          const SizedBox(width: 12),
          _statCard('Capacity', '${(capacity * 100).round()}%', Icons.speed_rounded),
          const SizedBox(width: 12),
          _statCard(
            'Completed',
            '${profile['total_completed_orders'] ?? 0}',
            Icons.check_circle_outline_rounded,
          ),
        ]),

        const SizedBox(height: 20),

        // ── Pricing ────────────────────────────────────────────────────────────
        if (minPrice != null || maxPrice != null) ...[
          _sectionTitle('Pricing'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Per Suit Range', style: GoogleFonts.outfit(color: Colors.white60, fontSize: 13)),
              Text(
                minPrice != null && maxPrice != null
                    ? 'PKR ${minPrice.toString()} – ${maxPrice.toString()}'
                    : 'Contact to inquire',
                style: GoogleFonts.outfit(color: AppTheme.accentGold, fontWeight: FontWeight.w700),
              ),
            ]),
          ),
          const SizedBox(height: 20),
        ],

        // ── Specializations ───────────────────────────────────────────────────
        if (specs.isNotEmpty) ...[
          _sectionTitle('Specializations'),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: specs.map((s) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.accentGold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.accentGold.withOpacity(0.3)),
            ),
            child: Text(s.toString(), style: GoogleFonts.outfit(
              color: AppTheme.accentGold, fontSize: 13, fontWeight: FontWeight.w600,
            )),
          )).toList()),
          const SizedBox(height: 24),
        ],

        // ── Location ──────────────────────────────────────────────────────────
        if (_tailor?['location_address'] != null) ...[
          _sectionTitle('Location'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              const Icon(Icons.location_on_outlined, color: Colors.white38, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(
                _tailor!['location_address'] as String,
                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14),
              )),
            ]),
          ),
          const SizedBox(height: 24),
        ],

        // ── Book Now Button ───────────────────────────────────────────────────
        if (user?.isClient == true) ...[
          SizedBox(
            width: double.infinity, height: 56,
            child: ElevatedButton.icon(
              onPressed: isAvailable ? () {
                // Navigate to booking screen — passes tailorId via route if implemented
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Booking flow coming in v1.1', style: GoogleFonts.outfit()),
                  backgroundColor: AppTheme.primaryDeepNavy,
                ));
              } : null,
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text(
                isAvailable ? 'Book This Tailor' : 'Fully Booked',
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isAvailable ? AppTheme.accentGold : Colors.grey.shade700,
                foregroundColor: isAvailable ? AppTheme.primaryDeepNavy : Colors.white38,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
      ]),
    );
  }

  Widget _sectionTitle(String title) => Text(title, style: GoogleFonts.outfit(
    color: Colors.white54, fontSize: 12, letterSpacing: 1.2, fontWeight: FontWeight.w600,
  ));

  Widget _statCard(String label, String value, IconData icon) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(children: [
        Icon(icon, color: AppTheme.accentGold, size: 20),
        const SizedBox(height: 6),
        Text(value, style: GoogleFonts.outfit(
          color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700,
        )),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11)),
      ]),
    ),
  );
}
