import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../services/api_client.dart';
import '../../services/auth_state.dart';
import '../../core/theme.dart';

class RequirementsScreen extends ConsumerStatefulWidget {
  final String orderId;
  const RequirementsScreen({super.key, required this.orderId});
  @override
  ConsumerState<RequirementsScreen> createState() => _RequirementsScreenState();
}

class _RequirementsScreenState extends ConsumerState<RequirementsScreen> {
  List<dynamic> _garments = [];
  bool _loading = true;
  bool _submitted = false;
  Map<String, Map<String, String>> _selections = {};
  Timer? _countdown;
  Duration _remaining = const Duration(hours: 24);

  @override
  void initState() {
    super.initState();
    _load();
    _countdown = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining.inSeconds > 0) setState(() => _remaining -= const Duration(seconds: 1));
      else _autoApprove();
    });
  }

  @override
  void dispose() { _countdown?.cancel(); super.dispose(); }

  Future<void> _load() async {
    try {
      final res = await ref.read(apiClientProvider).get('/orders/${widget.orderId}/requirements');
      final list = List.from(res.data);
      _selections = { for (var g in list) g['garment_id']: <String, String>{} };
      setState(() { _garments = list; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  Future<void> _submit() async {
    final body = <String, dynamic>{};
    for (final g in _garments) {
      body[g['garment_id']] = _selections[g['garment_id']] ?? {};
    }
    try {
      await ref.read(apiClientProvider).post(
        '/orders/${widget.orderId}/requirements/verify',
        data: {'requirements_by_garment': body},
      );
      setState(() => _submitted = true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e', style: GoogleFonts.outfit()),
        backgroundColor: Colors.red,
      ));
    }
  }

  void _autoApprove() {
    _countdown?.cancel();
    _submit();
  }

  String _formatTime(Duration d) =>
      '${d.inHours.toString().padLeft(2, '0')}:${(d.inMinutes % 60).toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    if (_submitted) return _successView();
    return Scaffold(
      backgroundColor: const Color(0xFF0F1923),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1923),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text('Verify Requirements', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              // Countdown banner
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.accentGold.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.accentGold.withOpacity(0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.timer_outlined, color: Colors.orangeAccent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(
                    'Auto-approved in ${_formatTime(_remaining)} with defaults',
                    style: GoogleFonts.outfit(color: Colors.orangeAccent, fontSize: 13),
                  )),
                ]),
              ),
              Expanded(child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                itemCount: _garments.length,
                itemBuilder: (ctx, i) {
                  final g = _garments[i];
                  final gid = g['garment_id'];
                  final options = (g['options'] as Map?)?.cast<String, dynamic>() ?? {};
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        const Icon(Icons.dry_cleaning_outlined, color: Colors.white54, size: 18),
                        const SizedBox(width: 8),
                        Text(g['garment_type'], style: GoogleFonts.outfit(
                          color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16,
                        )),
                      ]),
                      const SizedBox(height: 16),
                      for (final entry in options.entries) ...[
                        Text(_formatKey(entry.key), style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12, letterSpacing: 0.8)),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(children: (entry.value as List).map((opt) {
                            final sel = _selections[gid]?[entry.key] == opt;
                            return GestureDetector(
                              onTap: () => setState(() {
                                _selections[gid] = {...(_selections[gid] ?? {}), entry.key: opt};
                              }),
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: sel ? const Color(0xFF2DD4BF).withOpacity(0.2) : Colors.white.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: sel ? const Color(0xFF2DD4BF) : Colors.white.withOpacity(0.12),
                                  ),
                                ),
                                child: Text(opt, style: GoogleFonts.outfit(
                                  color: sel ? const Color(0xFF2DD4BF) : Colors.white60,
                                  fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                                )),
                              ),
                            );
                          }).toList()),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ]),
                  );
                },
              )),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: SizedBox(
                  width: double.infinity, height: 54,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2DD4BF),
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('Confirm Requirements', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ]),
    );
  }

  Widget _successView() => Scaffold(
    backgroundColor: const Color(0xFF0F1923),
    body: SafeArea(child: Center(child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: AppTheme.successGreen.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.verified_outlined, size: 60, color: AppTheme.successGreen),
        ),
        const SizedBox(height: 24),
        Text('Requirements Confirmed!', style: GoogleFonts.outfit(
          color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700,
        )),
        const SizedBox(height: 10),
        Text('Your requirements are now frozen into the stitching ticket. Production can begin.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(color: Colors.white54)),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () => context.go('/client/portal'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2DD4BF), foregroundColor: Colors.black87,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text('Track My Order', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        ),
      ]),
    ))),
  );

  String _formatKey(String key) => key.replaceAll('_', ' ').toUpperCase();
}
