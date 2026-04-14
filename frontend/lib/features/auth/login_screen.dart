import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_state.dart';
import '../../core/theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;
  late AnimationController _fadeCtrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() { 
    _fadeCtrl.dispose(); 
    _usernameCtrl.dispose(); 
    _passwordCtrl.dispose(); 
    super.dispose(); 
  }

  Future<void> _login() async {
    if (_usernameCtrl.text.trim().isEmpty || _passwordCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Enter both username and password');
      return;
    }
    setState(() { _loading = true; _error = null; });
    
    final err = await ref.read(authProvider.notifier).login(
      _usernameCtrl.text.trim(),
      _passwordCtrl.text.trim()
    );
    
    setState(() => _loading = false);
    
    if (err != null) { 
      setState(() => _error = err); 
      return; 
    }
    
    final user = ref.read(authProvider).user;
    if (user?.isTailor == true && mounted) context.go('/tailor/dashboard');
    else if (user?.isClient == true && mounted) context.go('/client/portal');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDeepNavy,
      body: FadeTransition(
        opacity: _fade,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 40),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => context.go('/'),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.arrow_back_ios_new, color: Colors.white54, size: 18),
                  const SizedBox(width: 6),
                  Text('Back', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 14)),
                ]),
              ),
              const SizedBox(height: 48),
              Text('Welcome\nBack', style: GoogleFonts.outfit(
                color: Colors.white, fontSize: 40, fontWeight: FontWeight.w700, height: 1.1,
              )),
              const SizedBox(height: 12),
              Text('Sign in to continue', style: GoogleFonts.outfit(
                color: Colors.white60, fontSize: 16,
              )),
              const SizedBox(height: 48),
              
              _buildUsernameField(),
              const SizedBox(height: 20),
              _buildPasswordField(),
              
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(_error!, style: GoogleFonts.outfit(color: Colors.redAccent)),
                ),
              ],
              const SizedBox(height: 28),
              
              _buildActionButton(),
              
              const SizedBox(height: 24),
              Center(
                child: GestureDetector(
                  onTap: () => context.go('/'),
                  child: RichText(
                    text: TextSpan(children: [
                      TextSpan(text: "Don't have an account? ", style: GoogleFonts.outfit(color: Colors.white54)),
                      TextSpan(text: "Register", style: GoogleFonts.outfit(
                        color: AppTheme.accentGold, fontWeight: FontWeight.w600,
                      )),
                    ]),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildUsernameField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: TextField(
        controller: _usernameCtrl,
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.next,
        style: GoogleFonts.outfit(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Username',
          hintStyle: GoogleFonts.outfit(color: Colors.white38),
          prefixIcon: const Icon(Icons.person_outline, color: Colors.white38),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: TextField(
        controller: _passwordCtrl,
        obscureText: _obscurePassword,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _login(),
        style: GoogleFonts.outfit(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Password',
          hintStyle: GoogleFonts.outfit(color: Colors.white38),
          prefixIcon: const Icon(Icons.lock_outline, color: Colors.white38),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: Colors.white38,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _loading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.accentGold,
          foregroundColor: Colors.black87,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          disabledBackgroundColor: AppTheme.accentGold.withOpacity(0.5),
        ),
        child: _loading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black54))
            : Text('Sign In', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
