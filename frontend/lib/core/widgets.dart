import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme.dart';

// ─────────────────────────────────────────────
//  AnimatedPulseBadge
//  A glowing, pulsing live-status dot
// ─────────────────────────────────────────────
class AnimatedPulseBadge extends StatefulWidget {
  final Color color;
  final double size;
  final String? label;

  const AnimatedPulseBadge({
    Key? key,
    this.color = AppTheme.softAmber,
    this.size = 10,
    this.label,
  }) : super(key: key);

  @override
  State<AnimatedPulseBadge> createState() => _AnimatedPulseBadgeState();
}

class _AnimatedPulseBadgeState extends State<AnimatedPulseBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _pulse = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final badge = SizedBox(
      width: widget.size * 2.8,
      height: widget.size * 2.8,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (_, __) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // outer ring
              Opacity(
                opacity: (1 - _pulse.value).clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: 1.0 + _pulse.value * 1.4,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.color.withOpacity(0.4),
                    ),
                  ),
                ),
              ),
              // inner solid dot
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color,
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withOpacity(0.5),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    if (widget.label == null) return badge;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        badge,
        const SizedBox(width: 6),
        Text(
          widget.label!,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: widget.color,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  CapacityGauge
//  Animated radial gauge with sweep animation
// ─────────────────────────────────────────────
class CapacityGauge extends StatefulWidget {
  final int current;
  final int max;
  final double size;

  const CapacityGauge({
    Key? key,
    required this.current,
    required this.max,
    this.size = 160,
  }) : super(key: key);

  @override
  State<CapacityGauge> createState() => _CapacityGaugeState();
}

class _CapacityGaugeState extends State<CapacityGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _sweep;

  @override
  void initState() {
    super.initState();
    final pct =
        widget.max > 0 ? (widget.current / widget.max).clamp(0.0, 1.0) : 0.0;
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _sweep = Tween<double>(begin: 0, end: pct).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutQuart),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color _gaugeColor(double pct) {
    if (pct > 0.85) return AppTheme.errorRed;
    if (pct > 0.55) return AppTheme.softAmber;
    return AppTheme.successGreen;
  }

  @override
  Widget build(BuildContext context) {
    final pct =
        widget.max > 0 ? (widget.current / widget.max).clamp(0.0, 1.0) : 0.0;
    final gaugeColor = _gaugeColor(pct);

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _sweep,
        builder: (_, __) {
          return CustomPaint(
            painter: _GaugePainter(
              value: _sweep.value,
              color: gaugeColor,
              trackColor: Colors.grey.shade200,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${widget.current}',
                  style: GoogleFonts.outfit(
                    fontSize: widget.size * 0.2,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryDeepNavy,
                    height: 1,
                  ),
                ),
                Text(
                  'of ${widget.max}',
                  style: GoogleFonts.outfit(
                    fontSize: widget.size * 0.09,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: gaugeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    'SLOTS',
                    style: GoogleFonts.outfit(
                      fontSize: widget.size * 0.075,
                      fontWeight: FontWeight.w800,
                      color: gaugeColor,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value;
  final Color color;
  final Color trackColor;

  _GaugePainter(
      {required this.value, required this.color, required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - 14;
    const strokeW = 14.0;
    const startAngle = math.pi * 0.65;
    const sweepAngle = math.pi * 1.7;

    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
        startAngle, sweepAngle, false, trackPaint);

    if (value > 0) {
      final arcPaint = Paint()
        ..shader = SweepGradient(
          startAngle: startAngle,
          endAngle: startAngle + sweepAngle,
          colors: [color.withOpacity(0.6), color],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..strokeWidth = strokeW
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
          startAngle, sweepAngle * value, false, arcPaint);
    }
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.value != value || old.color != color;
}

// ─────────────────────────────────────────────
//  QueueNotificationBadge
//  Stacked badge with count + bounce entry
// ─────────────────────────────────────────────
class QueueNotificationBadge extends StatefulWidget {
  final int count;
  final Color color;
  final Widget child;

  const QueueNotificationBadge({
    Key? key,
    required this.count,
    required this.child,
    this.color = AppTheme.errorRed,
  }) : super(key: key);

  @override
  State<QueueNotificationBadge> createState() =>
      _QueueNotificationBadgeState();
}

class _QueueNotificationBadgeState extends State<QueueNotificationBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        if (widget.count > 0)
          Positioned(
            right: -6,
            top: -6,
            child: ScaleTransition(
              scale: _scale,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                child: Text(
                  widget.count > 99 ? '99+' : '${widget.count}',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  GarmentCard  (Interactive Order Listing)
// ─────────────────────────────────────────────
class GarmentCard extends StatefulWidget {
  final String orderId;
  final String garmentTitle;
  final String clientName;
  final String stage;
  final Color stageColor;
  final String dueDate;
  final VoidCallback? onTap;
  final VoidCallback? onActionPressed;
  final String actionLabel;

  const GarmentCard({
    Key? key,
    required this.orderId,
    required this.garmentTitle,
    required this.clientName,
    required this.stage,
    required this.stageColor,
    required this.dueDate,
    this.onTap,
    this.onActionPressed,
    this.actionLabel = 'View Details',
  }) : super(key: key);

  @override
  State<GarmentCard> createState() => _GarmentCardState();
}

class _GarmentCardState extends State<GarmentCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverCtrl;
  late Animation<double> _elevation;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _hoverCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 180));
    _elevation =
        Tween<double>(begin: 0, end: 1).animate(_hoverCtrl);
  }

  @override
  void dispose() {
    _hoverCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _hovered = true);
        _hoverCtrl.forward();
      },
      onExit: (_) {
        setState(() => _hovered = false);
        _hoverCtrl.reverse();
      },
      child: AnimatedBuilder(
        animation: _elevation,
        builder: (_, child) => AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _hovered
                  ? widget.stageColor.withOpacity(0.35)
                  : Colors.grey.shade100,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _hovered
                    ? widget.stageColor.withOpacity(0.12)
                    : Colors.black.withOpacity(0.04),
                blurRadius: _hovered ? 24 : 12,
                offset: Offset(0, _hovered ? 8 : 4),
              ),
            ],
          ),
          child: child,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // header row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryDeepNavy.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.orderId,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.slateGrey,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const Spacer(),
                      AnimatedPulseBadge(
                        color: widget.stageColor,
                        size: 8,
                        label: widget.stage,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.garmentTitle,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryDeepNavy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.clientName,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded,
                          size: 14, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(
                        'Due: ${widget.dueDate}',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: widget.onActionPressed ?? widget.onTap,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          backgroundColor:
                              widget.stageColor.withOpacity(0.10),
                          foregroundColor: widget.stageColor,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          widget.actionLabel,
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SectionHeader  — reusable titled section
// ─────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const SectionHeader({
    Key? key,
    required this.title,
    this.subtitle,
    this.trailing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryDeepNavy,
                    letterSpacing: -0.3,
                  )),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                    )),
              ]
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// Keep old name as alias so existing code doesn't break
typedef CapacityRadialGauge = CapacityGauge;
