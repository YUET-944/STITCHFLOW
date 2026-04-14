import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_client.dart';
import '../../services/auth_state.dart';
import '../../core/theme.dart';
import '../../core/mock_data.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});
  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  List<dynamic> _tailors = [];
  bool _loading = true;
  String _spec = '';
  final _cityCtrl = TextEditingController();

  static const _specs = ['All', 'Suits', 'Shalwar Kameez', 'Sherwani', 'Bridal', 'Alterations', 'Ladies', 'Gents'];

  @override
  void initState() { super.initState(); _search(); }

  Future<void> _search() async {
    setState(() => _loading = true);
    final isDemo = ref.read(authProvider.notifier).isDemoMode;
    if (isDemo) {
      await Future.delayed(const Duration(milliseconds: 500));
      var results = List<dynamic>.from(MockData.demoTailors);
      if (_spec.isNotEmpty && _spec != 'All') {
        results = results.where((t) {
          final specs = (t['tailor_profile']?['specializations'] as List?) ?? [];
          return specs.any((s) => s.toString().contains(_spec));
        }).toList();
      }
      setState(() { _tailors = results; _loading = false; });
      return;
    }
    try {
      final api = ref.read(apiClientProvider);
      final params = <String, dynamic>{};
      if (_cityCtrl.text.isNotEmpty) params['city'] = _cityCtrl.text;
      if (_spec.isNotEmpty && _spec != 'All') params['specialization'] = _spec;
      final res = await api.get('/search/tailors', params: params);
      setState(() { _tailors = List.from(res.data); _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1923),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1923),
        elevation: 0,
        title: Text('Discover Tailors', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: Column(children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: TextField(
                  controller: _cityCtrl,
                  style: GoogleFonts.outfit(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search by city...',
                    hintStyle: GoogleFonts.outfit(color: Colors.white38),
                    prefixIcon: const Icon(Icons.search, color: Colors.white38),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onSubmitted: (_) => _search(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.tune, color: Colors.white70),
              onPressed: _search,
            ),
          ]),
        ),
        // Spec chips
        SizedBox(
          height: 52,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemCount: _specs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (ctx, i) {
              final s = _specs[i];
              final sel = _spec == s || (s == 'All' && _spec.isEmpty);
              return GestureDetector(
                onTap: () { setState(() => _spec = s == 'All' ? '' : s); _search(); },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: sel ? AppTheme.accentGold : Colors.white.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: sel ? AppTheme.accentGold : Colors.white.withOpacity(0.15)),
                  ),
                  child: Text(s, style: GoogleFonts.outfit(
                    color: sel ? AppTheme.primaryDeepNavy : Colors.white70,
                    fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                    fontSize: 13,
                  )),
                ),
              );
            },
          ),
        ),
        // Results
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _tailors.isEmpty
                  ? Center(child: Text('No tailors found', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 16)))
                  : RefreshIndicator(
                      onRefresh: _search,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                        itemCount: _tailors.length,
                        itemBuilder: (ctx, i) => _TailorCard(tailor: _tailors[i]),
                      ),
                    ),
        ),
      ]),
    );
  }
}

class _TailorCard extends StatelessWidget {
  final dynamic tailor;
  const _TailorCard({required this.tailor});

  @override
  Widget build(BuildContext context) {
    final profile = tailor['tailor_profile'] ?? {};
    final specs = (profile['specializations'] as List?) ?? [];
    final used = profile['current_active_orders'] ?? 0;
    final max = profile['max_active_orders'] ?? 10;
    final capacity = max > 0 ? used / max : 0.0;

    return GestureDetector(
      onTap: () => context.push('/client/tailor/${tailor['id']}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppTheme.accentGold.withOpacity(0.15),
            child: Text(
              (profile['business_name'] ?? tailor['full_name'] ?? '?').toString()[0].toUpperCase(),
              style: GoogleFonts.outfit(color: AppTheme.accentGold, fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(profile['business_name'] ?? tailor['full_name'] ?? 'Tailor',
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(tailor['location_address'] ?? 'Location not set',
                style: GoogleFonts.outfit(color: const Color(0x66FFFFFF), fontSize: 12)),
            const SizedBox(height: 6),
            Wrap(spacing: 6, children: specs.take(3).map((s) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.accentGold.withOpacity(0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(s.toString(), style: GoogleFonts.outfit(color: AppTheme.accentGold, fontSize: 11)),
            )).toList()),
          ])),
          Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            SizedBox(
              width: 40, height: 40,
              child: CircularProgressIndicator(
                value: capacity.toDouble(),
                color: capacity > 0.85 ? Colors.redAccent : AppTheme.successGreen,
                backgroundColor: Colors.white.withOpacity(0.1),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 4),
            Text('$used/$max', style: GoogleFonts.outfit(color: Colors.white60, fontSize: 11)),
          ]),
        ]),
      ),
    );
  }
}
