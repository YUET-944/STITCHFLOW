import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_client.dart';
import '../../services/auth_state.dart';
import '../../core/theme.dart';
import '../../core/mock_data.dart';

const _stages = [
  'MEASUREMENT_CONFIRMED', 'FABRIC_CUT', 'INTERLINING_ATTACHED', 'BODY_STITCHED',
  'COLLAR_LAPEL_ATTACHED', 'SLEEVES_SET', 'POCKETS_SEWN', 'LINING_INSTALLED',
  'BUTTONS_CLOSURES_ATTACHED', 'PRESSING_FINISHING', 'QC_PASSED', 'READY',
];

const _stageDisplay = {
  'MEASUREMENT_CONFIRMED': 'Measurement Confirmed',
  'FABRIC_CUT': 'Fabric Cut',
  'INTERLINING_ATTACHED': 'Interlining / Padding Attached',
  'BODY_STITCHED': 'Main Body Stitched',
  'COLLAR_LAPEL_ATTACHED': 'Collar / Lapel Attached',
  'SLEEVES_SET': 'Sleeves Set',
  'POCKETS_SEWN': 'Pockets Sewn',
  'LINING_INSTALLED': 'Lining Installed',
  'BUTTONS_CLOSURES_ATTACHED': 'Buttons / Closures Attached',
  'PRESSING_FINISHING': 'Pressing & Finishing',
  'QC_PASSED': 'Quality Check Passed',
  'READY': 'Ready for Pickup ✓',
};

class StaffManagementScreen extends ConsumerStatefulWidget {
  const StaffManagementScreen({super.key});
  @override
  ConsumerState<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends ConsumerState<StaffManagementScreen> {
  List<dynamic> _staff = [];
  bool _loading = true;

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final isDemo = ref.read(authProvider.notifier).isDemoMode;
    if (isDemo) {
      await Future.delayed(const Duration(milliseconds: 300));
      setState(() { _staff = List.from(MockData.demoStaff); _loading = false; });
      return;
    }
    try {
      final res = await ref.read(apiClientProvider).get('/staff');
      setState(() { _staff = List.from(res.data); _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  Future<void> _addStaffDialog() async {
    _nameCtrl.clear();
    _phoneCtrl.clear();
    String specialty = 'Stitching';
    final specs = ['Cutting', 'Stitching', 'Finishing', 'Embroidery', 'All'];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A2535),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setModal) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Add Staff Member', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          _inputField(_nameCtrl, 'Name', Icons.person_outline),
          const SizedBox(height: 12),
          _inputField(_phoneCtrl, 'Phone', Icons.phone_outlined, type: TextInputType.phone),
          const SizedBox(height: 12),
          Text('Specialty', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: specs.map((s) => ChoiceChip(
            label: Text(s, style: GoogleFonts.outfit(
              color: specialty == s ? AppTheme.primaryDeepNavy : Colors.white70, fontSize: 12,
            )),
            selected: specialty == s,
            selectedColor: AppTheme.accentGold,
            backgroundColor: Colors.white.withOpacity(0.07),
            onSelected: (v) => setModal(() => specialty = s),
          )).toList()),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity, height: 48,
            child: ElevatedButton(
              onPressed: () async {
                final isDemo = ref.read(authProvider.notifier).isDemoMode;
                if (!isDemo) {
                  await ref.read(apiClientProvider).post('/staff', data: {
                    'name': _nameCtrl.text, 'specialty': specialty, 'phone': _phoneCtrl.text,
                  });
                } else {
                  _snack('Demo Mode: Staff added locally (simulated)', AppTheme.accentGold);
                }
                Navigator.pop(ctx);
                _load();
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentGold, foregroundColor: AppTheme.primaryDeepNavy),
              child: Text('Add Staff', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDeepNavy,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDeepNavy,
        elevation: 0,
        title: Text('Staff Management', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(icon: const Icon(Icons.add, color: Colors.white), onPressed: _addStaffDialog),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _staff.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.group_outlined, size: 48, color: Colors.white24),
                  const SizedBox(height: 12),
                  Text('No staff added yet', style: GoogleFonts.outfit(color: Colors.white54, fontSize: 17)),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _addStaffDialog,
                    icon: const Icon(Icons.add),
                    label: Text('Add First Staff', style: GoogleFonts.outfit()),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentGold, foregroundColor: AppTheme.primaryDeepNavy),
                  ),
                ]))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _staff.length,
                  itemBuilder: (ctx, i) {
                    final s = _staff[i];
                    final onTime = s['total_on_time'] ?? 0;
                    final total = s['total_assigned'] ?? 0;
                    final rate = total > 0 ? (onTime / total * 100).round() : 0;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      child: Row(children: [
                        CircleAvatar(
                          backgroundColor: AppTheme.accentGold.withOpacity(0.15),
                          child: Text(s['name'][0], style: GoogleFonts.outfit(color: AppTheme.accentGold, fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(s['name'], style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600)),
                          Text('${s['specialty']} • ${s['phone']}', style: GoogleFonts.outfit(color: const Color(0x66FFFFFF), fontSize: 12)),
                          const SizedBox(height: 4),
                          Text('$total garments assigned • $rate% on-time', style: GoogleFonts.outfit(color: Colors.white60, fontSize: 12)),
                        ])),
                        Switch(
                          value: s['is_active'] ?? true,
                          onChanged: (v) async {
                            final isDemo = ref.read(authProvider.notifier).isDemoMode;
                            if (!isDemo) {
                              await ref.read(apiClientProvider).patch('/staff/${s['id']}/toggle', data: {'is_active': v});
                            } else {
                              _snack('Demo Mode: Status toggled locally', AppTheme.accentGold);
                            }
                            _load();
                          },
                          activeColor: AppTheme.successGreen,
                        ),
                      ]),
                    );
                  },
                ),
    );
  }

  void _snack(String msg, Color color) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: GoogleFonts.outfit()), backgroundColor: color));

  Widget _inputField(TextEditingController ctrl, String label, IconData icon, {TextInputType type = TextInputType.text}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.07), borderRadius: BorderRadius.circular(10)),
      child: TextField(
        controller: ctrl,
        keyboardType: type,
        style: GoogleFonts.outfit(color: Colors.white),
        decoration: InputDecoration(
          hintText: label, hintStyle: GoogleFonts.outfit(color: Colors.white38),
          prefixIcon: Icon(icon, color: Colors.white38, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
