import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_client.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';

class PosScreen extends ConsumerStatefulWidget {
  final String orderId;
  const PosScreen({super.key, required this.orderId});
  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  final _basePriceCtrl = TextEditingController();
  final _advanceCtrl = TextEditingController();
  String _garmentType = 'Suit Jacket';
  DateTime? _deliveryDate;
  bool _loading = false;
  Map<String, dynamic>? _result;

  static const _garmentTypes = [
    'Suit Jacket', 'Suit Trouser', 'Sherwani', 'Shalwar Kameez',
    'Waistcoat', 'Blouse', 'Shirt', 'Other',
  ];

  double get _base => double.tryParse(_basePriceCtrl.text) ?? 0;
  double get _advance => double.tryParse(_advanceCtrl.text) ?? 0;
  double get _balance => _base - _advance;
  String get _paymentStatus => _advance >= _base ? 'FULLY_PAID' : (_advance > 0 ? 'ADVANCE_RECEIVED' : 'BALANCE_PENDING');

  Future<void> _execute() async {
    if (_base <= 0) { _snack('Enter base price', Colors.red); return; }
    setState(() => _loading = true);
    try {
      final res = await ref.read(apiClientProvider).post(
        '/orders/${widget.orderId}/pos',
        data: {
          'basePrice': _base,
          'advancePaid': _advance,
          'garmentType': _garmentType,
          'deliveryDate': _deliveryDate?.toIso8601String(),
        },
      );
      setState(() { _result = Map<String, dynamic>.from(res.data); _loading = false; });
    } catch (e) { setState(() => _loading = false); _snack('Error: $e', Colors.red); }
  }

  void _snack(String msg, Color color) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: GoogleFonts.outfit()), backgroundColor: color));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDeepNavy,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDeepNavy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text('Point of Sale', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: _result != null ? _resultView() : _formView(),
    );
  }

  Widget _formView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Generate Invoice + Stitching Ticket', style: GoogleFonts.outfit(
          color: Colors.white70, fontSize: 14,
        )),
        const SizedBox(height: 24),
        _label('Garment Type'),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _garmentType,
              dropdownColor: const Color(0xFF1A2535),
              style: GoogleFonts.outfit(color: Colors.white),
              isExpanded: true,
              items: _garmentTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => _garmentType = v!),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _label('Base Price (${AppCurrency.code})'),
            const SizedBox(height: 8),
            _numField(_basePriceCtrl, 'e.g. 25000'),
          ])),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _label('Advance Paid (${AppCurrency.code})'),
            const SizedBox(height: 8),
            _numField(_advanceCtrl, 'e.g. 10000'),
          ])),
        ]),
        const SizedBox(height: 20),
        // Live balance preview
        StatefulBuilder(builder: (ctx, s) => AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: [
            _balRow('Base Price', AppCurrency.format(_base)),
            _balRow('Advance', '- ${AppCurrency.format(_advance)}'),
            const Divider(color: Colors.white12, height: 20),
            _balRow('Balance Due', AppCurrency.format(_balance), highlight: true),
            const SizedBox(height: 6),
            Text(_paymentStatus, style: GoogleFonts.outfit(
              color: _paymentStatus == 'FULLY_PAID' ? AppTheme.successGreen : AppTheme.accentGold,
              fontWeight: FontWeight.w600, fontSize: 13,
            )),
          ]),
        )),
        const SizedBox(height: 20),
        _label('Delivery Date'),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: DateTime.now().add(const Duration(days: 14)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (d != null) setState(() => _deliveryDate = d);
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              const Icon(Icons.calendar_today_outlined, color: Colors.white38, size: 18),
              const SizedBox(width: 10),
              Text(
                _deliveryDate != null
                    ? '${_deliveryDate!.day}/${_deliveryDate!.month}/${_deliveryDate!.year}'
                    : 'Select delivery date',
                style: GoogleFonts.outfit(color: _deliveryDate != null ? Colors.white : Colors.white38),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity, height: 56,
          child: ElevatedButton.icon(
            onPressed: _loading ? null : _execute,
            icon: _loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.receipt_long),
            label: Text('Generate Invoice + Ticket', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentGold,
              foregroundColor: AppTheme.primaryDeepNavy,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _resultView() {
    final inv = _result!['invoice'] ?? {};
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.successGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.successGreen.withOpacity(0.4)),
          ),
          child: Column(children: [
            Icon(Icons.check_circle, color: AppTheme.successGreen, size: 48),
            const SizedBox(height: 12),
            Text('POS Complete!', style: GoogleFonts.outfit(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700,
            )),
            const SizedBox(height: 8),
            Text('Invoice & Stitching Ticket generated', style: GoogleFonts.outfit(color: Colors.white60)),
          ]),
        ),
        const SizedBox(height: 24),
        _summaryCard('Invoice ID', inv['id'] ?? '-'),
        _summaryCard('Base Price', AppCurrency.format((inv['base_price'] ?? 0) as num)),
        _summaryCard('Advance', AppCurrency.format((inv['advance_paid'] ?? 0) as num)),
        _summaryCard('Balance Due', AppCurrency.format((inv['balance_due'] ?? 0) as num)),
        _summaryCard('Status', inv['payment_status'] ?? '-'),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(child: OutlinedButton.icon(
            icon: const Icon(Icons.share),
            label: Text('Share Invoice', style: GoogleFonts.outfit()),
            onPressed: () => _snack('WhatsApp sharing coming in v1.1', AppTheme.primaryDeepNavy),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white30)),
          )),
          const SizedBox(width: 12),
          Expanded(child: OutlinedButton.icon(
            icon: const Icon(Icons.qr_code),
            label: Text('Print Ticket', style: GoogleFonts.outfit()),
            onPressed: () => _snack('Thermal print coming in v1.1', AppTheme.primaryDeepNavy),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white30)),
          )),
        ]),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: () => context.pop(),
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentGold, foregroundColor: AppTheme.primaryDeepNavy),
          child: Text('Done', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        )),
      ]),
    );
  }

  Widget _label(String text) => Text(text, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12, letterSpacing: 0.8));

  Widget _numField(TextEditingController ctrl, String hint) => Container(
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.07), borderRadius: BorderRadius.circular(12)),
    child: TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      style: GoogleFonts.outfit(color: Colors.white),
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: hint, hintStyle: GoogleFonts.outfit(color: Colors.white38),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      ),
    ),
  );

  Widget _balRow(String label, String value, {bool highlight = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13)),
      Text(value, style: GoogleFonts.outfit(
        color: highlight ? AppTheme.accentGold : Colors.white,
        fontWeight: highlight ? FontWeight.w700 : FontWeight.w400,
        fontSize: highlight ? 15 : 13,
      )),
    ]),
  );

  Widget _summaryCard(String k, String v) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.06),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(k, style: GoogleFonts.outfit(color: Colors.white54)),
      Text(v, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600)),
    ]),
  );
}
