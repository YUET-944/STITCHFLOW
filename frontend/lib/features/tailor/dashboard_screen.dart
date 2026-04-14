import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_state.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../services/api_client.dart';
import 'package:go_router/go_router.dart';

// ─────────────────────────────────────────────
//  TAILOR COMMAND CENTRE
// ─────────────────────────────────────────────
class TailorDashboardScreen extends ConsumerStatefulWidget {
  const TailorDashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<TailorDashboardScreen> createState() => _TailorDashboardScreenState();
}

class _TailorDashboardScreenState extends ConsumerState<TailorDashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _heroCtrl;
  late AnimationController _cardsCtrl;
  late Animation<double> _heroFade;
  late Animation<Offset> _heroSlide;

  int _pendingQueueCount = 3;
  bool _gaugeExpanded = false;

  // Mock garment data
  static final List<_GarmentData> _orders = [
    _GarmentData(
      id: 'CL-KAR-042',
      garment: 'Three-Piece Suit',
      client: 'Bilal Mirza',
      stage: 'Body Stitched',
      stageColor: AppTheme.softAmber,
      dueDate: '18 May 2026',
    ),
    _GarmentData(
      id: 'CL-LHE-089',
      garment: 'Sherwani',
      client: 'Yasir Khan',
      stage: 'Ready for Fitting',
      stageColor: AppTheme.successGreen,
      dueDate: '12 May 2026',
    ),
    _GarmentData(
      id: 'CL-ISB-011',
      garment: 'Waistcoat Set',
      client: 'Hamza Siddiqui',
      stage: 'Fabric Cut',
      stageColor: const Color(0xFF6366F1),
      dueDate: '28 May 2026',
    ),
    _GarmentData(
      id: 'CL-KAR-058',
      garment: 'Kurta Shalwar',
      client: 'Ali Hassan',
      stage: 'QC Passed',
      stageColor: AppTheme.successGreen,
      dueDate: '10 May 2026',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _heroCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _cardsCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));

    _heroFade = CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOut);
    _heroSlide = Tween<Offset>(
      begin: const Offset(0, -0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOutCubic));

    Future.delayed(const Duration(milliseconds: 100), () {
      _heroCtrl.forward().then((_) => _cardsCtrl.forward());
    });
  }

  @override
  void dispose() {
    _heroCtrl.dispose();
    _cardsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: _buildAppBar(context),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(milliseconds: 800));
          setState(() {});
        },
        color: AppTheme.premiumGold,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // ── Hero Capacity Panel ──
              FadeTransition(
                opacity: _heroFade,
                child: SlideTransition(
                  position: _heroSlide,
                  child: _buildCapacityHero(),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Queue Summary ──
                    FadeTransition(
                      opacity: _heroFade,
                      child: _buildQueueSummaryRow(),
                    ),
                    const SizedBox(height: 28),

                    // ── Garment Listing ──
                    SectionHeader(
                      title: 'Active Orders',
                      subtitle: '${_orders.length} garments in production',
                      trailing: TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.filter_list_rounded, size: 16),
                        label: Text('Filter',
                            style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w700, fontSize: 13)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Garment cards with stagger
                    ..._orders.asMap().entries.map((e) {
                      final idx = e.key;
                      final data = e.value;
                      final delay = idx * 0.15;
                      final fadeAnim = Tween<double>(begin: 0, end: 1).animate(
                        CurvedAnimation(
                          parent: _cardsCtrl,
                          curve: Interval(delay,
                              (delay + 0.4).clamp(0.0, 1.0),
                              curve: Curves.easeOut),
                        ),
                      );
                      final slideAnim =
                          Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
                              .animate(CurvedAnimation(
                        parent: _cardsCtrl,
                        curve: Interval(delay, (delay + 0.4).clamp(0.0, 1.0),
                            curve: Curves.easeOutCubic),
                      ));

                      return FadeTransition(
                        opacity: fadeAnim,
                        child: SlideTransition(
                          position: slideAnim,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: GarmentCard(
                              orderId: data.id,
                              garmentTitle: data.garment,
                              clientName: data.client,
                              stage: data.stage,
                              stageColor: data.stageColor,
                              dueDate: data.dueDate,
                              actionLabel: 'Update Stage',
                              onTap: () => _showOrderDetails(context, data),
                              onActionPressed: () =>
                                  _showStageUpdateSheet(context, data),
                            ),
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // ── FAB: Add New Order ──
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewOrderSheet(context),
        backgroundColor: AppTheme.primaryDeepNavy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text('New Order',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        elevation: 4,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.premiumGold.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.design_services_rounded,
                color: AppTheme.premiumGold, size: 18),
          ),
          const SizedBox(width: 10),
          Text('Command Centre',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        ],
      ),
      actions: [
        // Queue Notification Badge
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: QueueNotificationBadge(
            count: _pendingQueueCount,
            color: AppTheme.errorRed,
            child: IconButton(
              icon: const Icon(Icons.notifications_rounded),
              color: AppTheme.slateGrey,
              onPressed: () => _showQueuePanel(context),
            ),
          ),
        ),
        // Profile avatar
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: GestureDetector(
            onTap: () => _showProfileSheet(context),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.primaryDeepNavy,
              child: Text('TM',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  )),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCapacityHero() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back,',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        ref.watch(authProvider).user?.fullName ?? 'Tailor',
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryDeepNavy,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      AnimatedPulseBadge(
                        color: AppTheme.successGreen,
                        size: 8,
                        label: 'Shop Open',
                      ),
                    ],
                  ),
                ),
                // Gauge
                GestureDetector(
                  onTap: () =>
                      setState(() => _gaugeExpanded = !_gaugeExpanded),
                  child: CapacityGauge(current: 8, max: 10, size: 140),
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: _gaugeExpanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Column(
                      children: [
                        Container(
                          height: 1,
                          color: Colors.grey.shade100,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _capacityStat('Available', '2', AppTheme.successGreen),
                            _capacityStat('Active', '8', AppTheme.softAmber),
                            _capacityStat('Max', '10', Colors.grey.shade400),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setState(() => _gaugeExpanded = false);
                            },
                            icon: const Icon(Icons.tune_rounded, size: 16),
                            label: Text('Adjust Capacity',
                                style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w700)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              side: BorderSide(
                                  color: Colors.grey.shade300, width: 1.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _capacityStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildQueueSummaryRow() {
    return Row(
      children: [
        Expanded(child: _queueBadgeCard(Icons.pending_actions_rounded, 'Pending\nApproval', '$_pendingQueueCount', AppTheme.softAmber)),
        const SizedBox(width: 12),
        Expanded(child: _queueBadgeCard(Icons.local_shipping_rounded, 'Ready\nToday', '1', AppTheme.successGreen)),
        const SizedBox(width: 12),
        Expanded(child: _queueBadgeCard(Icons.warning_amber_rounded, 'Overdue', '0', Colors.grey.shade400)),
      ],
    );
  }

  Widget _queueBadgeCard(IconData icon, String label, String count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              QueueNotificationBadge(
                count: int.tryParse(count) ?? 0,
                color: color,
                child: const SizedBox(width: 20, height: 20),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              count,
              style: GoogleFonts.outfit(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: color,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sheets & Dialogs ──────────────────────────────────────────────────────

  void _showOrderDetails(BuildContext context, _GarmentData data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OrderDetailsSheet(data: data),
    );
  }

  void _showStageUpdateSheet(BuildContext context, _GarmentData data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StageUpdateSheet(
        data: data,
        onStageSelected: (newStage) {
          setState(() {
            final idx = _orders.indexWhere((o) => o.id == data.id);
            if (idx >= 0) _orders[idx] = data.copyWith(stage: newStage);
          });
        },
      ),
    );
  }

  void _showQueuePanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _QueuePanel(
        count: _pendingQueueCount,
        onDismiss: () {
          setState(() => _pendingQueueCount = 0);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showNewOrderSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _NewOrderSheet(),
    );
  }

  void _showProfileSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProfileSheet(
        onLogout: () {
          Navigator.pop(context);
          context.go('/');
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  BOTTOM SHEETS
// ─────────────────────────────────────────────

class _BottomSheetWrapper extends StatelessWidget {
  final String title;
  final Widget child;
  final double initialChildSize;

  const _BottomSheetWrapper({
    required this.title,
    required this.child,
    this.initialChildSize = 0.55,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: initialChildSize,
      minChildSize: 0.3,
      maxChildSize: 0.92,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28), topRight: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // title
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: [
                  Text(title,
                      style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryDeepNavy)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
            Divider(color: Colors.grey.shade100, height: 1),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollCtrl,
                padding: const EdgeInsets.all(24),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Order Details Sheet
class _OrderDetailsSheet extends StatelessWidget {
  final _GarmentData data;
  const _OrderDetailsSheet({required this.data});

  @override
  Widget build(BuildContext context) {
    return _BottomSheetWrapper(
      title: 'Order Details',
      initialChildSize: 0.6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _detailRow('Order ID', data.id, Icons.tag_rounded),
          _detailRow('Garment', data.garment, Icons.checkroom_rounded),
          _detailRow('Client', data.client, Icons.person_rounded),
          _detailRow('Current Stage', data.stage, Icons.timelapse_rounded,
              valueColor: data.stageColor),
          _detailRow('Due Date', data.dueDate, Icons.event_rounded),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, IconData icon,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.backgroundLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppTheme.slateGrey),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: Colors.grey.shade400,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5)),
                Text(value,
                    style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: valueColor ?? AppTheme.primaryDeepNavy)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Stage Update Sheet
class _StageUpdateSheet extends StatefulWidget {
  final _GarmentData data;
  final void Function(String stage) onStageSelected;
  const _StageUpdateSheet(
      {required this.data, required this.onStageSelected});

  @override
  State<_StageUpdateSheet> createState() => _StageUpdateSheetState();
}

class _StageUpdateSheetState extends State<_StageUpdateSheet> {
  static const List<String> _allStages = [
    'Measurement Confirmed',
    'Fabric Cut',
    'Interlining Attached',
    'Body Stitched',
    'Sleeves Set',
    'QC Passed',
    'Ready for Delivery',
  ];

  String? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.data.stage;
  }

  @override
  Widget build(BuildContext context) {
    return _BottomSheetWrapper(
      title: 'Update Stage',
      initialChildSize: 0.65,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select the current production stage for ${widget.data.garment}',
              style: GoogleFonts.outfit(
                  color: Colors.grey.shade500, fontSize: 14)),
          const SizedBox(height: 20),
          ..._allStages.map((stage) {
            final isSelected = _selected == stage;
            return GestureDetector(
              onTap: () => setState(() => _selected = stage),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryDeepNavy
                      : AppTheme.backgroundLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryDeepNavy
                        : Colors.grey.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      size: 20,
                      color: isSelected ? AppTheme.premiumGold : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Text(stage,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : AppTheme.primaryDeepNavy,
                        )),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (_selected != null) {
                  widget.onStageSelected(_selected!);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Stage updated to: $_selected',
                          style:
                              GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                      backgroundColor: AppTheme.successGreen,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              },
              child: Text('Confirm Update',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

// Queue Panel
class _QueuePanel extends StatelessWidget {
  final int count;
  final VoidCallback onDismiss;
  const _QueuePanel({required this.count, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return _BottomSheetWrapper(
      title: 'Pending Queue ($count)',
      child: Column(
        children: [
          if (count == 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle_outline_rounded,
                        size: 48, color: AppTheme.successGreen),
                    const SizedBox(height: 12),
                    Text('All caught up!',
                        style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryDeepNavy)),
                  ],
                ),
              ),
            )
          else ...[
            _queueItem('New booking from Bilal Mirza', '3 min ago',
                Icons.person_add_rounded, AppTheme.softAmber),
            _queueItem('Measurement upload: CL-ISB-022', '18 min ago',
                Icons.straighten_rounded, const Color(0xFF6366F1)),
            _queueItem('Fabric arrival confirmed', '1 hr ago',
                Icons.inventory_2_rounded, AppTheme.successGreen),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onDismiss,
                child: Text('Mark All as Read',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _queueItem(
      String title, String time, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.15), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryDeepNavy)),
                const SizedBox(height: 3),
                Text(time,
                    style: GoogleFonts.outfit(
                        fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ),
          AnimatedPulseBadge(color: color, size: 7),
        ],
      ),
    );
  }
}

// New Order Sheet
class _NewOrderSheet extends ConsumerStatefulWidget {
  const _NewOrderSheet();

  @override
  ConsumerState<_NewOrderSheet> createState() => _NewOrderSheetState();
}

class _NewOrderSheetState extends ConsumerState<_NewOrderSheet> {
  final _nameCtrl = TextEditingController();
  final _garmentCtrl = TextEditingController();
  String? _selectedStage = 'Measurement Confirmed';
  bool _submitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _garmentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _BottomSheetWrapper(
      title: 'New Order',
      initialChildSize: 0.75,
      child: Column(
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              hintText: 'Client Name',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _garmentCtrl,
            decoration: const InputDecoration(
              hintText: 'Garment Type (e.g. Suit Jacket)',
              prefixIcon: Icon(Icons.checkroom_outlined),
            ),
          ),
          const SizedBox(height: 24),
          Text('Initial Stage',
              style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryDeepNavy)),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _selectedStage,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 16),
            ),
            items: [
              'Measurement Confirmed',
              'Fabric Cut',
              'Body Stitched',
            ]
                .map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w600))))
                .toList(),
            onChanged: (v) => setState(() => _selectedStage = v),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : () async {
                if (_nameCtrl.text.isEmpty || _garmentCtrl.text.isEmpty) return;
                
                setState(() => _submitting = true);
                try {
                  final isDemo = ref.read(authProvider.notifier).isDemoMode;
                  if (isDemo) {
                    await Future.delayed(const Duration(milliseconds: 1000));
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Demo Order created locally!',
                              style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                          backgroundColor: AppTheme.successGreen,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                    return;
                  }

                  // Real API call
                  final res = await ref.read(apiClientProvider).post('/orders', data: {
                    'tailor_id': ref.read(authProvider).user?.id,
                    'client_id': '6b713600-0000-4000-8000-000000000000', // Mock link for demo-to-real transition
                    'preferredDateStart': DateTime.now().toIso8601String(),
                    'preferredDateEnd': DateTime.now().add(const Duration(days: 14)).toIso8601String(),
                    'specialInstructions': 'Created via Tailor Dashboard',
                    'garments': [_garmentCtrl.text],
                  });
                  
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Order created: ${res.data['id']}',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                        backgroundColor: AppTheme.successGreen,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _submitting = false);
                }
              },
              child: _submitting 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text('Create Order', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

// Profile Sheet
class _ProfileSheet extends ConsumerWidget {
  final VoidCallback onLogout;
  const _ProfileSheet({required this.onLogout});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28), topRight: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          CircleAvatar(
            radius: 36,
            backgroundColor: AppTheme.primaryDeepNavy,
            child: Text((ref.watch(authProvider).user?.fullName ?? 'T')[0].toUpperCase(),
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 12),
          Text(ref.watch(authProvider).user?.fullName ?? 'Tailor',
              style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryDeepNavy)),
          Text('Master Tailor · ${ref.watch(authProvider).user?.city ?? 'StitchFlow'}',
              style: GoogleFonts.outfit(
                  fontSize: 13, color: Colors.grey.shade500)),
          const SizedBox(height: 28),
          ListTile(
            leading: const Icon(Icons.settings_rounded),
            title: Text('Settings',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
            onTap: () => Navigator.pop(context),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            tileColor: AppTheme.backgroundLight,
          ),
          const SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppTheme.errorRed),
            title: Text('Log Out',
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600, color: AppTheme.errorRed)),
            onTap: onLogout,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            tileColor: AppTheme.errorRed.withOpacity(0.06),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─────────────────────────────
//  Data Models
// ─────────────────────────────
class _GarmentData {
  final String id;
  final String garment;
  final String client;
  final String stage;
  final Color stageColor;
  final String dueDate;

  const _GarmentData({
    required this.id,
    required this.garment,
    required this.client,
    required this.stage,
    required this.stageColor,
    required this.dueDate,
  });

  _GarmentData copyWith({String? stage}) {
    return _GarmentData(
      id: id,
      garment: garment,
      client: client,
      stage: stage ?? this.stage,
      stageColor: stageColor,
      dueDate: dueDate,
    );
  }
}
