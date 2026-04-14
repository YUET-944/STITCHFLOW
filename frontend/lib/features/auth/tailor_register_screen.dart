import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_state.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';

class TailorRegisterScreen extends ConsumerStatefulWidget {
  const TailorRegisterScreen({super.key});
  @override
  ConsumerState<TailorRegisterScreen> createState() => _TailorRegisterScreenState();
}

class _TailorRegisterScreenState extends ConsumerState<TailorRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _businessCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _priceMinCtrl = TextEditingController();
  final _priceMaxCtrl = TextEditingController();

  final List<String> _specializations = [];
  static const List<String> _specOptions = [
    'Suits', 'Shalwar Kameez', 'Sherwani', 'Bridal', 'Alterations',
    'Ladies', 'Gents', 'Kids', 'Three-Piece', 'Waistcoat',
  ];

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose(); _businessCtrl.dispose(); _usernameCtrl.dispose(); _passwordCtrl.dispose();
    _cityCtrl.dispose(); _priceMinCtrl.dispose(); _priceMaxCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    final err = await ref.read(authProvider.notifier).register({
      'role': 'TAILOR',
      'full_name': _nameCtrl.text.trim(),
      'business_name': _businessCtrl.text.trim(),
      'username': _usernameCtrl.text.trim(),
      'password': _passwordCtrl.text.trim(),
      'city': _cityCtrl.text.trim(),
      'specializations': _specializations,
      'price_min': double.tryParse(_priceMinCtrl.text),
      'price_max': double.tryParse(_priceMaxCtrl.text),
    });
    setState(() => _loading = false);
    if (err != null) { setState(() => _error = err); return; }
    if (mounted) context.go('/tailor/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDeepNavy,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => context.go('/'),
        ),
        title: Text('Tailor Registration', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _sectionLabel('Personal Info'),
            const SizedBox(height: 12),
            _field(_nameCtrl, 'Full Name', Icons.person_outline, required: true),
            const SizedBox(height: 14),
            _field(_businessCtrl, 'Business Name', Icons.store_outlined, required: true),
            const SizedBox(height: 14),
            _field(_usernameCtrl, 'Username', Icons.alternate_email_outlined, required: true),
            const SizedBox(height: 14),
            _field(_passwordCtrl, 'Password', Icons.lock_outline, required: true, obscure: true),
            const SizedBox(height: 14),
            _field(_cityCtrl, 'City / Location', Icons.location_on_outlined),
            const SizedBox(height: 28),
            _sectionLabel('Specializations'),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: _specOptions.map((s) {
              final selected = _specializations.contains(s);
              return FilterChip(
                label: Text(s, style: GoogleFonts.outfit(
                  color: selected ? AppTheme.primaryDeepNavy : Colors.white70,
                  fontSize: 13,
                )),
                selected: selected,
                selectedColor: AppTheme.accentGold,
                backgroundColor: Colors.white.withOpacity(0.08),
                checkmarkColor: AppTheme.primaryDeepNavy,
                onSelected: (v) => setState(() {
                  if (v) _specializations.add(s); else _specializations.remove(s);
                }),
              );
            }).toList()),
            const SizedBox(height: 28),
            _sectionLabel('Pricing (PKR)'),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _field(_priceMinCtrl, 'Min per Suit', Icons.currency_rupee, keyboardType: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: _field(_priceMaxCtrl, 'Max per Suit', Icons.currency_rupee, keyboardType: TextInputType.number)),
            ]),
            if (_error != null) ...[
              const SizedBox(height: 16),
              _errorBanner(_error!),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity, height: 56,
              child: ElevatedButton(
                onPressed: _loading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentGold,
                  foregroundColor: AppTheme.primaryDeepNavy,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _loading
                    ? const CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                    : Text('Create Tailor Account', style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 20),
          ]),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) => Text(label,
      style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {TextInputType keyboardType = TextInputType.text, bool required = false, bool obscure = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        obscureText: obscure,
        style: GoogleFonts.outfit(color: Colors.white),
        validator: required ? (v) => (v?.isEmpty == true) ? '$label is required' : null : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.outfit(color: Colors.white38),
          prefixIcon: Icon(icon, color: Colors.white38),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _errorBanner(String msg) => Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.red.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
      child: Text(msg, style: GoogleFonts.outfit(color: Colors.redAccent)));
}
