import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/theme.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Auth
import 'features/auth/login_screen.dart';
import 'features/auth/tailor_register_screen.dart';
import 'features/auth/client_register_screen.dart';

// Client
import 'features/client/portal_screen.dart';
import 'features/client/track_screen.dart';
import 'features/client/requirements_screen.dart';
import 'features/client/orders_screen.dart';
import 'features/client/vault_screen.dart';
import 'features/client/discover_screen.dart';
import 'features/client/profile_screen.dart';

// Tailor
import 'features/tailor/tailor_shell_screen.dart';
import 'features/tailor/pos_screen.dart';
import 'features/tailor/booking_queue_screen.dart';
import 'features/tailor/staff_screen.dart';
import 'features/tailor/tailor_profile_screen.dart';

// Client detail screens
import 'features/client/tailor_detail_screen.dart';

// Services
import 'services/auth_state.dart';

import 'dart:async';

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      debugPrint("Warning: .env file not found. API endpoints may default to mocks.");
    }
    runApp(const ProviderScope(child: StitchFlowApp()));
  }, (error, stackTrace) {
    debugPrint('GLOBAL ERROR: $error');
  });
}

// ── Router ───────────────────────────────────────────────────────────────────

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    // ── Gateway ──────────────────────────────────────────────────────────────
    GoRoute(path: '/', builder: (ctx, state) => const DualEntryGateway()),

    // ── Auth ──────────────────────────────────────────────────────────────────
    GoRoute(path: '/auth/login',           builder: (ctx, state) => const LoginScreen()),
    GoRoute(path: '/auth/register/tailor', builder: (ctx, state) => const TailorRegisterScreen()),
    GoRoute(path: '/auth/register/client', builder: (ctx, state) => const ClientRegisterScreen()),

    // ── Client Shell (tabs: Home | Orders | Vault | Discover | Profile) ──────
    GoRoute(path: '/client/portal', builder: (ctx, state) => const ClientPortalScreen()),

    // ── Client Sub-screens (pushed on top of shell) ───────────────────────────
    GoRoute(
      path: '/client/track',
      builder: (ctx, state) =>
          OrderTrackingScreen(readableId: state.uri.queryParameters['id'] ?? ''),
    ),
    GoRoute(
      path: '/client/requirements/:orderId',
      builder: (ctx, state) =>
          RequirementsScreen(orderId: state.pathParameters['orderId']!),
    ),
    GoRoute(
      path: '/client/tailor/:tailorId',
      builder: (ctx, state) => TailorDetailScreen(tailorId: state.pathParameters['tailorId']!),
    ),

    // ── Tailor Shell (tabs: Dashboard | Queue | Staff | Profile) ─────────────
    GoRoute(path: '/tailor/dashboard', builder: (ctx, state) => const TailorShellScreen()),

    // ── Tailor Sub-screens (pushed on top of shell) ───────────────────────────
    GoRoute(
      path: '/tailor/pos/:orderId',
      builder: (ctx, state) => PosScreen(orderId: state.pathParameters['orderId']!),
    ),
    GoRoute(
      path: '/tailor/portfolio',
      builder: (ctx, state) => const Scaffold(body: Center(child: Text('Portfolio (Coming Soon)'))),
    ),
  ],
  errorBuilder: (ctx, state) => Scaffold(
    backgroundColor: AppTheme.primaryDeepNavy,
    body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.link_off, color: Colors.white24, size: 52),
      const SizedBox(height: 16),
      Text('Page not found: ${state.uri}',
          style: GoogleFonts.outfit(color: Colors.white54, fontSize: 16)),
      const SizedBox(height: 12),
      ElevatedButton(
        onPressed: () => ctx.go('/'),
        child: Text('Go Home', style: GoogleFonts.outfit()),
      ),
    ])),
  ),
);

// ── App Root ──────────────────────────────────────────────────────────────────

class StitchFlowApp extends ConsumerWidget {
  const StitchFlowApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'StitchFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: _router,
    );
  }
}

// ── Dual Entry Gateway ────────────────────────────────────────────────────────

class DualEntryGateway extends ConsumerStatefulWidget {
  const DualEntryGateway({super.key});
  @override
  ConsumerState<DualEntryGateway> createState() => _DualEntryGatewayState();
}

class _DualEntryGatewayState extends ConsumerState<DualEntryGateway>
    with TickerProviderStateMixin {
  late AnimationController _bgCtrl;
  late AnimationController _cardCtrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _bgCtrl   = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _cardCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fade  = CurvedAnimation(parent: _bgCtrl,   curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOutCubic));
    _bgCtrl.forward().then((_) => _cardCtrl.forward());

    // Auto-restore existing session
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).user;
      if (user != null && mounted) {
        if (user.isTailor) {
          context.go('/tailor/dashboard');
        } else if (user.isClient) {
          context.go('/client/portal');
        }
      }
    });
  }

  @override
  void dispose() { _bgCtrl.dispose(); _cardCtrl.dispose(); super.dispose(); }

  Future<void> _demoLogin(String role) async {
    await ref.read(authProvider.notifier).demoLogin(role);
    if (!mounted) return;
    if (role == 'TAILOR') context.go('/tailor/dashboard');
    else context.go('/client/portal');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF060D1A), Color(0xFF0A1628), Color(0xFF0D1F38)],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fade,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(children: [
                const Spacer(),
                // Logo
                SlideTransition(
                  position: _slide,
                  child: Column(children: [
                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppTheme.accentGold, AppTheme.accentGold.withOpacity(0.6)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: AppTheme.accentGold.withOpacity(0.4), blurRadius: 24)],
                      ),
                      child: const Icon(Icons.content_cut, color: Colors.black87, size: 32),
                    ),
                    const SizedBox(height: 20),
                    Text('StitchFlow', style: GoogleFonts.outfit(
                      color: Colors.white, fontSize: 38, fontWeight: FontWeight.w800, letterSpacing: -1,
                    )),
                    const SizedBox(height: 8),
                    Text('The Tailor OS. The Client Portal.', style: GoogleFonts.outfit(
                      color: const Color(0x66FFFFFF), fontSize: 15,
                    )),
                  ]),
                ),
                const SizedBox(height: 52),
                // Entry Cards
                SlideTransition(
                  position: _slide,
                  child: Column(children: [
                    _EntryCard(
                      title: "I'm a Tailor",
                      subtitle: 'Manage orders, clients & payments',
                      icon: Icons.design_services_outlined,
                      color: AppTheme.accentGold,
                      onRegister: () => context.go('/auth/register/tailor'),
                      onLogin:    () => context.go('/auth/login'),
                      onDemo:     () => _demoLogin('TAILOR'),
                    ),
                    const SizedBox(height: 14),
                    _EntryCard(
                      title: "I'm a Client",
                      subtitle: 'Track orders & own your measurements',
                      icon: Icons.person_outline,
                      color: const Color(0xFF2DD4BF),
                      onRegister: () => context.go('/auth/register/client'),
                      onLogin:    () => context.go('/auth/login'),
                      onDemo:     () => _demoLogin('CLIENT'),
                    ),
                  ]),
                ),
                const Spacer(),
                // Demo banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withOpacity(0.07)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.bolt, color: Colors.amber, size: 14),
                    const SizedBox(width: 8),
                    Expanded(child: Text(
                      'Quick Demo ⚡ — demo account KHAN, no server needed',
                      style: GoogleFonts.outfit(color: Colors.white30, fontSize: 11),
                    )),
                  ]),
                ),
                const SizedBox(height: 10),
                Text('StitchFlow v1.0 • Anti-Gravity Edition',
                    style: GoogleFonts.outfit(color: Colors.white12, fontSize: 11)),
                const SizedBox(height: 16),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Entry Card ────────────────────────────────────────────────────────────────

class _EntryCard extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onRegister, onLogin, onDemo;

  const _EntryCard({
    required this.title, required this.subtitle, required this.icon,
    required this.color, required this.onRegister,
    required this.onLogin, required this.onDemo,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onRegister,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.08),
                Colors.white.withOpacity(0.03),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withOpacity(0.35), width: 1.5),
            boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 18)],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Top row
            Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: GoogleFonts.outfit(
                  color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700,
                )),
                Text(subtitle, style: GoogleFonts.outfit(
                  color: const Color(0x80FFFFFF), fontSize: 12,
                )),
              ])),
              Icon(Icons.arrow_forward_ios_rounded, color: color.withOpacity(0.6), size: 14),
            ]),
            const SizedBox(height: 12),
            // Action row — each has independent tap
            Row(children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onLogin,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                  ),
                  child: Text('Sign In', style: GoogleFonts.outfit(
                    color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600,
                  )),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onDemo,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withOpacity(0.5)),
                  ),
                  child: Text('Quick Demo ⚡', style: GoogleFonts.outfit(
                    color: color, fontSize: 12, fontWeight: FontWeight.w700,
                  )),
                ),
              ),
              const Spacer(),
              Text('Register →', style: GoogleFonts.outfit(
                color: color.withOpacity(0.55), fontSize: 11,
              )),
            ]),
          ]),
        ),
      ),
    );
  }
}
