import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../services/api_client.dart';
import '../../services/auth_state.dart';

// ─────────────────────────────────────────────
//  ORDER TRACKING SCREEN   (Client Track Portal)
// ─────────────────────────────────────────────
class OrderTrackingScreen extends ConsumerStatefulWidget {
  final String readableId;
  const OrderTrackingScreen({Key? key, required this.readableId})
      : super(key: key);

  @override
  ConsumerState<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen>
    with TickerProviderStateMixin {
  late AnimationController _heroCtrl;
  late AnimationController _listCtrl;
  late Animation<double> _heroFade;
  late Animation<Offset> _heroSlide;

  bool _loading = true;
  dynamic _order;
  String? _error;

  // Map enum stages to display names and icons
  static const List<String> _stageEnums = [
    'MEASUREMENT_CONFIRMED', 'FABRIC_CUT', 'INTERLINING_ATTACHED', 'BODY_STITCHED',
    'SLEEVES_SET', 'QC_PASSED', 'READY'
  ];

  static const List<_Stage> _stages = [
    _Stage('Measurement Confirmed', Icons.straighten_rounded,   AppTheme.successGreen),
    _Stage('Fabric Cut',            Icons.content_cut_rounded,   AppTheme.successGreen),
    _Stage('Interlining Attached',  Icons.layers_rounded,        AppTheme.successGreen),
    _Stage('Body Stitched',         Icons.checkroom_rounded,     AppTheme.softAmber),
    _Stage('Sleeves Set',           Icons.design_services_rounded, Colors.grey),
    _Stage('QC Passed',             Icons.verified_rounded,       Colors.grey),
    _Stage('Ready for Delivery',    Icons.local_shipping_rounded, Colors.grey),
  ];

  int _getCurrentStageIndex() {
    if (_order == null || _order['garments'] == null || (_order['garments'] as List).isEmpty) return 0;
    final stage = _order['garments'][0]['delivery_stage'];
    final idx = _stageEnums.indexOf(stage);
    return idx >= 0 ? idx : 0;
  }

  @override
  void initState() {
    super.initState();
    _heroCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _listCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));

    _heroFade = CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOut);
    _heroSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOutCubic));

    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final isDemo = ref.read(authProvider.notifier).isDemoMode;
    if (isDemo) {
      await Future.delayed(const Duration(milliseconds: 800));
      // In demo, we just simulate a found order
      setState(() { _order = {'id': widget.readableId, 'booking_status': 'CONFIRMED', 'garments': [{'garment_type': 'Suit Jacket', 'delivery_stage': 'BODY_STITCHED'}], 'preferred_date_end': '2026-05-24'}; _loading = false; });
      _heroCtrl.forward().then((_) => _listCtrl.forward());
      return;
    }

    try {
      final res = await ref.read(apiClientProvider).get('/search/track', params: {'id': widget.readableId});
      setState(() { 
        _order = res.data['order']; 
        _loading = false; 
        if (_order == null) _error = 'No active order found for this ID';
      });
      _heroCtrl.forward().then((_) => _listCtrl.forward());
    } catch (e) {
      setState(() { _error = 'Could not fetch tracking data'; _loading = false; });
    }
  }

  @override
  void dispose() {
    _heroCtrl.dispose();
    _listCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.canPop() ? context.pop() : context.go('/client/portal'),
        ),
        title: Row(
          children: [
            const Icon(Icons.checkroom_rounded,
                color: AppTheme.premiumGold, size: 22),
            const SizedBox(width: 8),
            Text('Order Tracker',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () {
              Clipboard.setData(ClipboardData(
                  text: 'SF-ORDER/${widget.readableId}'));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Order ID copied!',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                  backgroundColor: AppTheme.successGreen,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.error_outline, size: 48, color: AppTheme.errorRed),
                  const SizedBox(height: 16),
                  Text(_error!, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 16)),
                  const SizedBox(height: 20),
                  ElevatedButton(onPressed: _load, child: const Text('Retry')),
                ]))
              : SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero Card ──
            FadeTransition(
              opacity: _heroFade,
              child: SlideTransition(
                position: _heroSlide,
                child: _buildHeroCard(),
              ),
            ),
            const SizedBox(height: 28),

            // ── Progress Summary Chips ──
            FadeTransition(
              opacity: _heroFade,
              child: _buildProgressChips(),
            ),
            const SizedBox(height: 28),

            // ── Checklist Header ──
            SectionHeader(
              title: 'Production Checklist',
              subtitle:
                  '${_getCurrentStageIndex()} of ${_stages.length} stages complete',
              trailing: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (_getCurrentStageIndex() == _stages.length - 1 ? AppTheme.successGreen : AppTheme.softAmber).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  _getCurrentStageIndex() == _stages.length - 1 ? 'READY' : 'IN PROGRESS',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _getCurrentStageIndex() == _stages.length - 1 ? AppTheme.successGreen : AppTheme.softAmber,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Stage Items ──
            ..._stages.asMap().entries.map((e) {
              final index = e.key;
              final stage = e.value;
              final currentIdx = _getCurrentStageIndex();
              final isCompleted = index < currentIdx;
              final isCurrent  = index == currentIdx;
              final isPending  = index > currentIdx;

              return _AnimatedStageItem(
                stage: stage,
                isCompleted: isCompleted,
                isCurrent: isCurrent,
                isPending: isPending,
                isLast: index == _stages.length - 1,
                animationDelay: Duration(milliseconds: 80 * index),
                parentController: _listCtrl,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryDeepNavy, Color(0xFF1E3A5F)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryDeepNavy.withOpacity(0.35),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.premiumGold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.style_rounded,
                    color: AppTheme.premiumGold, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _order?['garments']?[0]?['garment_type'] ?? 'Garment',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.readableId,
                      style: GoogleFonts.outfit(
                        color: Colors.white54,
                        fontSize: 12,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedPulseBadge(
                color: _getCurrentStageIndex() == _stages.length - 1 ? AppTheme.successGreen : AppTheme.softAmber,
                size: 10,
                label: '',
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 1,
            color: Colors.white.withOpacity(0.1),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _heroStat('Stage', '${_getCurrentStageIndex() + 1} of ${_stages.length}', Icons.timelapse_rounded),
              const SizedBox(width: 24),
              _heroStat('Due', _order?['preferred_date_end']?.toString().split('T')[0] ?? 'TBD', Icons.event_rounded),
              const Spacer(),
              _heroStat('Progress', '${((_getCurrentStageIndex() + 1) / _stages.length * 100).round()}%', Icons.trending_up_rounded),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (_getCurrentStageIndex() + 1) / _stages.length,
              minHeight: 6,
              backgroundColor: Colors.white.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation<Color>(_getCurrentStageIndex() == _stages.length - 1 ? AppTheme.successGreen : AppTheme.softAmber),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroStat(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.white38),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.outfit(
                    fontSize: 10,
                    color: Colors.white38,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8)),
            Text(value,
                style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: Colors.white,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressChips() {
    final currentIdx = _getCurrentStageIndex();
    return Row(
      children: [
        _chip(Icons.check_circle_rounded, '$currentIdx Done',
            AppTheme.successGreen),
        const SizedBox(width: 10),
        _chip(Icons.pending_rounded, '1 Active', AppTheme.softAmber),
        const SizedBox(width: 10),
        _chip(Icons.hourglass_empty_rounded,
            '${_stages.length - currentIdx - 1} Left',
            Colors.grey.shade400),
      ],
    );
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                )),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Animated Stage List Item
// ─────────────────────────────────────────────
class _AnimatedStageItem extends StatelessWidget {
  final _Stage stage;
  final bool isCompleted;
  final bool isCurrent;
  final bool isPending;
  final bool isLast;
  final Duration animationDelay;
  final AnimationController parentController;

  const _AnimatedStageItem({
    required this.stage,
    required this.isCompleted,
    required this.isCurrent,
    required this.isPending,
    required this.isLast,
    required this.animationDelay,
    required this.parentController,
  });

  @override
  Widget build(BuildContext context) {
    final delay = (animationDelay.inMilliseconds /
            (parentController.duration?.inMilliseconds ?? 1))
        .clamp(0.0, 0.9);

    final slideAnim = Tween<Offset>(
      begin: const Offset(0.2, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: parentController,
      curve: Interval(delay, (delay + 0.4).clamp(0.0, 1.0),
          curve: Curves.easeOutCubic),
    ));

    final fadeAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: parentController,
      curve: Interval(delay, (delay + 0.4).clamp(0.0, 1.0),
          curve: Curves.easeOut),
    ));

    final Color dotColor = isCompleted
        ? AppTheme.successGreen
        : isCurrent
            ? AppTheme.softAmber
            : Colors.grey.shade300;

    return FadeTransition(
      opacity: fadeAnim,
      child: SlideTransition(
        position: slideAnim,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Timeline Track ──
            Column(
              children: [
                // dot / badge
                if (isCurrent)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: AnimatedPulseBadge(
                        color: AppTheme.softAmber, size: 14),
                  )
                else
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: dotColor,
                      boxShadow: isCompleted
                          ? [
                              BoxShadow(
                                color: AppTheme.successGreen.withOpacity(0.3),
                                blurRadius: 8,
                              )
                            ]
                          : null,
                    ),
                    child: isCompleted
                        ? const Icon(Icons.check_rounded,
                            size: 16, color: Colors.white)
                        : Icon(stage.icon,
                            size: 14, color: Colors.grey.shade400),
                  ),
                // connector line
                if (!isLast)
                  Container(
                    width: 2,
                    height: 48,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppTheme.successGreen.withOpacity(0.3)
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            // ── Content ──
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                    bottom: isLast ? 0 : 48, top: isCurrent ? 0 : 4),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: isCurrent
                      ? const EdgeInsets.all(16)
                      : EdgeInsets.zero,
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? AppTheme.softAmber.withOpacity(0.06)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: isCurrent
                        ? Border.all(
                            color: AppTheme.softAmber.withOpacity(0.2),
                            width: 1)
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stage.title,
                        style: GoogleFonts.outfit(
                          fontSize: isCurrent ? 16 : 15,
                          fontWeight: isCurrent
                              ? FontWeight.w800
                              : isCompleted
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                          color: isPending
                              ? Colors.grey.shade400
                              : AppTheme.primaryDeepNavy,
                        ),
                      ),
                      if (isCurrent) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Currently in progress · Est. 2 days remaining',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: AppTheme.softAmber,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      if (isCompleted) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Completed',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: AppTheme.successGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────// ── Internal Data Classes ─────────────────────────────────────────────────────
class _Stage {
  final String title;
  final IconData icon;
  final Color color;
  const _Stage(this.title, this.icon, this.color);
}
