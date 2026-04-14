import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_client.dart';
import '../../services/auth_state.dart';
import '../../core/theme.dart';
import '../../core/mock_data.dart';

class MeasurementVaultScreen extends ConsumerStatefulWidget {
  const MeasurementVaultScreen({super.key});
  @override
  ConsumerState<MeasurementVaultScreen> createState() => _MeasurementVaultScreenState();
}

class _MeasurementVaultScreenState extends ConsumerState<MeasurementVaultScreen> {
  List<dynamic> _records = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _loadVault(); }

  Future<void> _loadVault() async {
    final user = ref.read(authProvider).user;
    if (user == null) return;
    final isDemo = ref.read(authProvider.notifier).isDemoMode;
    if (isDemo) {
      await Future.delayed(const Duration(milliseconds: 400));
      // Add version and is_current to demo records
      final records = MockData.demoMeasurements.asMap().entries.map((e) {
        return { ...e.value, 'version': e.key + 1, 'is_current': e.key == 0 };
      }).toList();
      setState(() { _records = records; _loading = false; });
      return;
    }
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get('/client/${user.id}/measurements');
      setState(() { _records = List.from(res.data); _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use ref.watch (not ref.read) so the widget rebuilds on logout/auth changes
    final user = ref.watch(authProvider).user;
    return Scaffold(
      backgroundColor: const Color(0xFF0F1923),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1923),
        elevation: 0,
        title: Text('Measurement Vault', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined, color: Colors.white70),
            tooltip: 'Export PDF',
            onPressed: () => _showExportSnackbar(context),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
              ? _emptyVault(user)
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _records.length,
                  itemBuilder: (ctx, i) => _MeasurementCard(record: _records[i], index: i),
                ),
    );
  }

  Widget _emptyVault(AuthUser? user) {
    return Center(child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.straighten, color: Colors.white24, size: 48),
        ),
        const SizedBox(height: 20),
        Text('Your Vault is Empty', style: GoogleFonts.outfit(
          color: Colors.white70, fontSize: 20, fontWeight: FontWeight.w600,
        )),
        const SizedBox(height: 8),
        Text('Your tailor will record your measurements here after your first order is confirmed.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(color: const Color(0x66FFFFFF), fontSize: 14)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.accentGold.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('ID: ${user?.readableId ?? '—'}',
              style: GoogleFonts.outfit(color: AppTheme.accentGold, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        ),
      ]),
    ));
  }

  void _showExportSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('PDF export coming in v1.1', style: GoogleFonts.outfit()),
      backgroundColor: AppTheme.primaryDeepNavy,
    ));
  }
}

class _MeasurementCard extends StatelessWidget {
  final dynamic record;
  final int index;
  const _MeasurementCard({required this.record, required this.index});

  @override
  Widget build(BuildContext context) {
    final isCurrent = record['is_current'] == true;
    final tailorName = record['tailor']?['full_name'] ?? 'Unknown Tailor';
    // Support both API field names and mock data field names
    final fields = <String, dynamic>{
      'Neck':      record['neck'],
      'Chest':     record['chest'],
      'Waist':     record['waist'],
      'Hips':      record['hips'],
      'Shoulder':  record['shoulder'] ?? record['shoulder_width'],
      'Sleeve':    record['sleeve']  ?? record['sleeve_length'],
      'Shirt L.':  record['shirt_length'],
      'Trouser L.':record['trouser_length'] ?? record['pant_length'],
    }..removeWhere((k, v) => v == null);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent ? AppTheme.accentGold.withOpacity(0.6) : Colors.white.withOpacity(0.08),
          width: isCurrent ? 1.5 : 1,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Version ${record['version']} • $tailorName',
                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600)),
              Text(record['recorded_at']?.toString().substring(0, 10) ?? '',
                  style: GoogleFonts.outfit(color: const Color(0x66FFFFFF), fontSize: 13)),
            ])),
            if (isCurrent) Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.accentGold.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('CURRENT', style: GoogleFonts.outfit(
                color: AppTheme.accentGold, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1,
              )),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(spacing: 8, runSpacing: 8, children: fields.entries.map((e) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('${e.value}cm', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700)),
              Text(e.key, style: GoogleFonts.outfit(color: const Color(0x66FFFFFF), fontSize: 11)),
            ]),
          )).toList()),
        ),
        if (record['custom_notes'] != null && record['custom_notes'].toString().isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Text('Note: ${record['custom_notes']}',
                style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13)),
          ),
      ]),
    );
  }
}
