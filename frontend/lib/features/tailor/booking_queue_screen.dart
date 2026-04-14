import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_client.dart';
import '../../services/auth_state.dart';
import '../../core/theme.dart';
import '../../core/mock_data.dart';

const _rejectionReasons = [
  'FULLY_BOOKED',
  'SPECIALIZATION_MISMATCH',
  'TIMELINE_UNAVAILABLE',
  'CLIENT_REQUEST_UNCLEAR',
  'OTHER',
];

class BookingQueueScreen extends ConsumerStatefulWidget {
  const BookingQueueScreen({super.key});
  @override
  ConsumerState<BookingQueueScreen> createState() => _BookingQueueScreenState();
}

class _BookingQueueScreenState extends ConsumerState<BookingQueueScreen> {
  List<dynamic> _queue = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    // Demo mode — use mock data without hitting the API
    final isDemo = ref.read(authProvider.notifier).isDemoMode;
    if (isDemo) {
      await Future.delayed(const Duration(milliseconds: 400));
      setState(() { _queue = List.from(MockData.demoQueue); _loading = false; });
      return;
    }
    try {
      final res = await ref.read(apiClientProvider).get('/orders/tailor/queue');
      setState(() { _queue = List.from(res.data); _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  Future<void> _approve(String orderId) async {
    try {
      await ref.read(apiClientProvider).patch('/orders/$orderId/approve');
      _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Order approved ✓', style: GoogleFonts.outfit()),
        backgroundColor: AppTheme.successGreen,
      ));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e', style: GoogleFonts.outfit()),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _reject(String orderId) async {
    String selectedReason = _rejectionReasons[0];
    final notesCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A2535),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Reject Order', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Text('Reason', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: _rejectionReasons.map((r) {
              final sel = selectedReason == r;
              return GestureDetector(
                onTap: () => setModal(() => selectedReason = r),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: sel ? Colors.redAccent.withOpacity(0.25) : Colors.white.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: sel ? Colors.redAccent : Colors.white.withOpacity(0.1)),
                  ),
                  child: Text(r.replaceAll('_', ' '), style: GoogleFonts.outfit(
                    color: sel ? Colors.redAccent : Colors.white70, fontSize: 12,
                  )),
                ),
              );
            }).toList()),
            const SizedBox(height: 14),
            TextField(
              controller: notesCtrl,
              style: GoogleFonts.outfit(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Optional note to client...',
                hintStyle: GoogleFonts.outfit(color: Colors.white38),
                filled: true, fillColor: Colors.white.withOpacity(0.06),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity, height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await ref.read(apiClientProvider).patch('/orders/$orderId/reject', data: {
                    'reason': selectedReason,
                    'notes': notesCtrl.text,
                  });
                  _load();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red.withOpacity(0.8)),
                child: Text('Confirm Rejection', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ),
      ),
    );
    // Fix memory leak: dispose controller after the sheet closes
    notesCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDeepNavy,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDeepNavy,
        elevation: 0,
        title: Text('Booking Queue', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600)),
        actions: [
          if (_queue.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
              child: Text('${_queue.length}', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _queue.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.check_circle_outline, color: Colors.white24, size: 52),
                  const SizedBox(height: 12),
                  Text('No pending requests', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 17, fontWeight: FontWeight.w600)),
                ]))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _queue.length,
                    itemBuilder: (ctx, i) {
                      final o = _queue[i];
                      final client = o['client'] ?? {};
                      final garments = (o['garments'] as List?)?.map((g) => g['garment_type']).join(', ') ?? '-';
                      final notes = o['special_instructions'] ?? '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.accentGold.withOpacity(0.3)),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                            child: Row(children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: AppTheme.accentGold.withOpacity(0.15),
                                child: Text(
                                  (client['full_name'] ?? '?').toString()[0].toUpperCase(),
                                  style: GoogleFonts.outfit(color: AppTheme.accentGold, fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(client['full_name'] ?? 'Client',
                                    style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600)),
                                Text(client['readable_id'] ?? '',
                                    style: GoogleFonts.outfit(color: const Color(0x66FFFFFF), fontSize: 12)),
                              ])),
                            ]),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              _infoRow(Icons.dry_cleaning_outlined, garments),
                              if (notes.isNotEmpty) _infoRow(Icons.notes_outlined, notes),
                              if (o['preferred_date_start'] != null)
                                _infoRow(Icons.calendar_today_outlined,
                                    '${o['preferred_date_start']} → ${o['preferred_date_end'] ?? '?'}'),
                            ]),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Row(children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _reject(o['id']),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.redAccent,
                                    side: const BorderSide(color: Colors.redAccent),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: Text('Reject', style: GoogleFonts.outfit()),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _approve(o['id']),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.successGreen,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: Text('Approve', style: GoogleFonts.outfit(
                                    color: Colors.white, fontWeight: FontWeight.w600,
                                  )),
                                ),
                              ),
                            ]),
                          ),
                        ]),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _infoRow(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(children: [
      Icon(icon, size: 15, color: const Color(0x66FFFFFF)),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: GoogleFonts.outfit(color: Colors.white60, fontSize: 13))),
    ]),
  );
}
