import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_client.dart';
import '../../services/auth_state.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../core/mock_data.dart';

class OrdersHistoryScreen extends ConsumerStatefulWidget {
  const OrdersHistoryScreen({super.key});
  @override
  ConsumerState<OrdersHistoryScreen> createState() => _OrdersHistoryScreenState();
}

class _OrdersHistoryScreenState extends ConsumerState<OrdersHistoryScreen> {
  List<dynamic> _orders = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final isDemo = ref.read(authProvider.notifier).isDemoMode;
      if (isDemo) {
        await Future.delayed(const Duration(milliseconds: 400));
        setState(() { _orders = List.from(MockData.demoOrders); _loading = false; });
        return;
      }
      final api = ref.read(apiClientProvider);
      final res = await api.get('/orders/client/mine');
      setState(() { _orders = List.from(res.data); _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not load orders. Is the server running?',
              style: GoogleFonts.outfit()),
          backgroundColor: Colors.red.shade800,
        ));
      }
    }
  }

  Color _statusColor(String status) => switch (status) {
    'CONFIRMED' => AppTheme.successGreen,
    'PENDING' => AppTheme.accentGold,
    'REJECTED' => Colors.red,
    'CANCELLED' => Colors.grey,
    'COMPLETED' => Colors.blue,
    _ => Colors.white54,
  };

  IconData _statusIcon(String status) => switch (status) {
    'CONFIRMED' => Icons.check_circle_outline,
    'PENDING' => Icons.hourglass_top_outlined,
    'REJECTED' => Icons.cancel_outlined,
    'CANCELLED' => Icons.cancel,
    'COMPLETED' => Icons.verified_outlined,
    _ => Icons.circle_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1923),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1923),
        elevation: 0,
        title: Text('My Orders', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? _empty()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _orders.length,
                    itemBuilder: (ctx, i) {
                      final o = _orders[i];
                      final status = o['booking_status'] ?? 'PENDING';
                      final garments = (o['garments'] as List?)?.map((g) => g['garment_type']).join(', ') ?? '';
                      final tailorName = o['tailor']?['full_name'] ?? 'Unknown';
                      final balance = o['invoice']?['balance_due'];
                      final payment = o['invoice']?['payment_status'];

                      return GestureDetector(
                        onTap: () {
                          if (status == 'CONFIRMED') {
                            context.push('/client/track?id=${o['id']}');
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.08)),
                          ),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Icon(_statusIcon(status), color: _statusColor(status), size: 18),
                              const SizedBox(width: 8),
                              Expanded(child: Text(garments.isNotEmpty ? garments : 'Order',
                                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600))),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _statusColor(status).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(status, style: GoogleFonts.outfit(
                                  color: _statusColor(status), fontSize: 11, fontWeight: FontWeight.w700,
                                )),
                              ),
                            ]),
                            const SizedBox(height: 8),
                            Text('Tailor: $tailorName', style: GoogleFonts.outfit(color: Colors.white60, fontSize: 13)),
                            Text('Order ID: ${o['id']}', style: GoogleFonts.outfit(color: Colors.white30, fontSize: 12)),
                            if (balance != null) ...[
                              const SizedBox(height: 8),
                              Row(children: [
                                Text('Balance Due: ${AppCurrency.format((balance as num))}', style: GoogleFonts.outfit(
                                  color: payment == 'FULLY_PAID' ? AppTheme.successGreen : Colors.orangeAccent,
                                  fontSize: 13, fontWeight: FontWeight.w600,
                                )),
                              ]),
                            ],
                            if (status == 'CONFIRMED') Align(
                              alignment: Alignment.centerRight,
                              child: Text('Tap to track →', style: GoogleFonts.outfit(
                                color: AppTheme.accentGold, fontSize: 12,
                              )),
                            ),
                          ]),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _empty() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Icon(Icons.receipt_long_outlined, color: Colors.white24, size: 52),
    const SizedBox(height: 16),
    Text('No orders yet', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 18, fontWeight: FontWeight.w600)),
    const SizedBox(height: 8),
    Text('Discover a tailor and book your first order', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 14)),
  ]));
}
