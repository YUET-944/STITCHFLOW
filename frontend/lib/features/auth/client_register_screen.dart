import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_state.dart';
import '../../core/theme.dart';

class ClientRegisterScreen extends ConsumerStatefulWidget {
  const ClientRegisterScreen({super.key});
  @override
  ConsumerState<ClientRegisterScreen> createState() => _ClientRegisterScreenState();
}

class _ClientRegisterScreenState extends ConsumerState<ClientRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() { _nameCtrl.dispose(); _usernameCtrl.dispose(); _passwordCtrl.dispose(); _cityCtrl.dispose(); super.dispose(); }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    final err = await ref.read(authProvider.notifier).register({
      'role': 'CLIENT',
      'full_name': _nameCtrl.text.trim(),
      'username': _usernameCtrl.text.trim(),
      'password': _passwordCtrl.text.trim(),
      'city': _cityCtrl.text.trim(),
    });
    setState(() => _loading = false);
    if (err != null) { setState(() => _error = err); return; }
    if (mounted) context.go('/client/portal');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1923),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => context.go('/'),
        ),
        title: Text('Client Registration', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 16),
            Text('Create your\nClient Account', style: GoogleFonts.outfit(
              color: Colors.white, fontSize: 34, fontWeight: FontWeight.w700, height: 1.15,
            )),
            const SizedBox(height: 8),
            Text('Track your orders & own your measurements', style: GoogleFonts.outfit(
              color: Colors.white54, fontSize: 15,
            )),
            const SizedBox(height: 40),
            _field(_nameCtrl, 'Full Name', Icons.person_outline, 'Name is required'),
            const SizedBox(height: 16),
            _field(_usernameCtrl, 'Username', Icons.alternate_email_outlined, 'Username is required'),
            const SizedBox(height: 16),
            _field(_passwordCtrl, 'Password', Icons.lock_outline, 'Password is required', obscure: true),
            const SizedBox(height: 16),
            _field(_cityCtrl, 'City (optional)', Icons.location_city_outlined, null),
            if (_error != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_error!, style: GoogleFonts.outfit(color: Colors.redAccent))),
                ]),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity, height: 56,
              child: ElevatedButton(
                onPressed: _loading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2DD4BF),
                  foregroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _loading
                    ? const CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                    : Text('Create Account', style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: GestureDetector(
                onTap: () => context.go('/auth/login'),
                child: RichText(
                  text: TextSpan(children: [
                    TextSpan(text: 'Already have an account? ', style: GoogleFonts.outfit(color: Colors.white54)),
                    TextSpan(text: 'Sign In', style: GoogleFonts.outfit(
                      color: const Color(0xFF2DD4BF), fontWeight: FontWeight.w600,
                    )),
                  ]),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon, String? requiredMsg,
      {TextInputType type = TextInputType.text, bool obscure = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextFormField(
        controller: ctrl,
        keyboardType: type,
        obscureText: obscure,
        style: GoogleFonts.outfit(color: Colors.white, fontSize: 16),
        validator: requiredMsg != null ? (v) => (v?.isEmpty == true) ? requiredMsg : null : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.outfit(color: Colors.white38),
          prefixIcon: Icon(icon, color: Colors.white38, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
      ),
    );
  }
}
