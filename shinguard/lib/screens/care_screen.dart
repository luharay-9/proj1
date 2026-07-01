import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/muscle_report.dart';
import '../shared/shared_widgets.dart';
import '../theme/app_colors.dart';

class CareScreen extends StatefulWidget {
  const CareScreen({super.key});

  @override
  State<CareScreen> createState() => _CareScreenState();
}

class _CareScreenState extends State<CareScreen> {
  int viewIndex = 0;

  static const frontReports = [
    MuscleReport(
      label: 'Shin',
      score: 8,
      detail: 'Elevated impact load during sprint deceleration',
      careTitle: 'Ice and unload for 24 hours',
      careDetail:
          'Apply ice for 15 minutes after training, avoid repeated hard cuts tomorrow, and complete a light ankle mobility warmup before returning to sprint work.',
      polygons: [
        [
          Offset(.405, .705),
          Offset(.452, .710),
          Offset(.445, .880),
          Offset(.420, .880),
        ],
        [
          Offset(.548, .710),
          Offset(.595, .705),
          Offset(.580, .880),
          Offset(.555, .880),
        ],
      ],
    ),
    MuscleReport(
      label: 'Ankle',
      score: 5,
      detail: 'Moderate landing stiffness after direction changes',
      careTitle: 'Add stability and landing work',
      careDetail:
          'Use a 6-minute balance routine, slow calf raises, and soft landing reps before the next session. Keep jumps and pivots moderate today.',
      polygons: [
        [
          Offset(.392, .882),
          Offset(.455, .882),
          Offset(.450, .935),
          Offset(.382, .932),
        ],
        [
          Offset(.545, .882),
          Offset(.608, .882),
          Offset(.618, .932),
          Offset(.550, .935),
        ],
      ],
    ),
    MuscleReport(
      label: 'Quadricep',
      score: 4,
      detail: 'Balanced load, below weekly risk threshold',
      careTitle: 'Maintain normal training load',
      careDetail:
          'Keep regular training, then add a short quad stretch and foam-roll pass after practice to preserve symmetry between legs.',
      polygons: [
        [
          Offset(.370, .5),
          Offset(.468, .5),
          Offset(.448, .695),
          Offset(.397, .700),
          Offset(.382, .620),
        ],
        [
          Offset(.532, .5),
          Offset(.630, .5),
          Offset(.618, .620),
          Offset(.603, .700),
          Offset(.552, .695),
        ],
      ],
    ),
  ];

  static const backReports = [
    MuscleReport(
      label: 'Hamstring',
      score: 6,
      detail: 'Posterior chain fatigue is trending upward',
      careTitle: 'Reduce max-speed sprint volume',
      careDetail:
          'Limit full-speed sprints for the next session, add eccentric hamstring bridges, and finish with gentle posterior-chain stretching.',
      polygons: [
        [
          Offset(.360, .535),
          Offset(.468, .535),
          Offset(.446, .705),
          Offset(.392, .705),
        ],
        [
          Offset(.532, .535),
          Offset(.640, .535),
          Offset(.608, .705),
          Offset(.554, .705),
        ],
      ],
    ),
    MuscleReport(
      label: 'Calf',
      score: 7,
      detail: 'Repeated high-load pushes detected late session',
      careTitle: 'Prioritize calf recovery',
      careDetail:
          'Use light compression, two sets of slow calf raises, and keep tomorrow to technical ball work instead of repeated acceleration drills.',
      polygons: [
        [
          Offset(.380, .715),
          Offset(.445, .715),
          Offset(.450, .842),
          Offset(.405, .842),
        ],
        [
          Offset(.555, .715),
          Offset(.620, .715),
          Offset(.595, .842),
          Offset(.550, .842),
        ],
      ],
    ),
    MuscleReport(
      label: 'Achilles',
      score: 3,
      detail: 'Normal tendon load and recovery response',
      careTitle: 'Continue tendon maintenance',
      careDetail:
          'No restriction needed. Keep the normal warmup and add gentle ankle circles after training to maintain tendon mobility.',
      polygons: [
        [
          Offset(.420, .842),
          Offset(.452, .842),
          Offset(.450, .928),
          Offset(.425, .928),
        ],
        [
          Offset(.548, .842),
          Offset(.580, .842),
          Offset(.575, .928),
          Offset(.550, .928),
        ],
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isFront = viewIndex == 0;
    final reports = isFront ? frontReports : backReports;

    return AppScrollView(
      children: [
        const TopBar(
          eyebrow: 'AI-powered prevention insights',
          title: 'Injury Care',
        ),
        const SizedBox(height: 18),
        const RiskScoreCard(),
        const SectionHeader(title: 'Body Load Map'),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(
              value: 0,
              label: Text('Front'),
              icon: Icon(Icons.accessibility_new_rounded),
            ),
            ButtonSegment(
              value: 1,
              label: Text('Back'),
              icon: Icon(Icons.accessibility_rounded),
            ),
          ],
          selected: {viewIndex},
          showSelectedIcon: false,
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? AppColors.pulse
                  : AppColors.panel,
            ),
            foregroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? AppColors.ink
                  : AppColors.muted,
            ),
            side: const WidgetStatePropertyAll(BorderSide.none),
            textStyle: const WidgetStatePropertyAll(
              TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          onSelectionChanged: (value) {
            setState(() => viewIndex = value.first);
          },
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: panelDecoration(),
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: DiagramRiskMap(
                  assetPath: isFront
                      ? 'assets/DiagramFront.png'
                      : 'assets/DiagramBack.png',
                  reports: reports,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 4,
                child: Column(
                  children: reports
                      .map(
                        (report) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: RiskRow(
                            report: report,
                            onTap: () => _showReportSheet(context, report),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Risk scale: safe green · caution yellow-orange · danger red',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.muted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  void _showReportSheet(BuildContext context, MuscleReport report) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.panel,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => ReportInfoSheet(report: report),
    );
  }
}

class RiskScoreCard extends StatelessWidget {
  const RiskScoreCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xff643519), Color(0xff8d4b22)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 76,
            height: 76,
            child: CustomPaint(
              painter: RingPainter(.56, AppColors.gold),
              child: const Center(
                child: Text(
                  '6',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RISK SCORE',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 12,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Moderate',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                Text(
                  'Right shin loading is above baseline. Active recovery recommended for 24h.',
                  style: TextStyle(
                    color: AppColors.softText,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DiagramRiskMap extends StatelessWidget {
  const DiagramRiskMap({
    required this.assetPath,
    required this.reports,
    super.key,
  });

  final String assetPath;
  final List<MuscleReport> reports;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1145 / 1374,
      child: Transform.scale(
        scale: 1.08,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(painter: MuscleOverlayPainter(reports)),
            Image.asset(assetPath, fit: BoxFit.contain),
          ],
        ),
      ),
    );
  }
}

class RiskRow extends StatelessWidget {
  const RiskRow({required this.report, required this.onTap, super.key});

  final MuscleReport report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.deepInk.withValues(alpha: .34),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              CircleAvatar(radius: 5, backgroundColor: report.color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  report.label,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              Text(
                '${report.score}/10',
                style: TextStyle(
                  color: report.color,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.muted,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ReportInfoSheet extends StatelessWidget {
  const ReportInfoSheet({required this.report, super.key});

  final MuscleReport report;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(radius: 6, backgroundColor: report.color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    report.label,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: report.color.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${report.score}/10',
                    style: TextStyle(
                      color: report.color,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              'Current State',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                letterSpacing: 1,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              report.detail,
              style: const TextStyle(
                color: AppColors.softText,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Recommended Care',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                letterSpacing: 1,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.deepInk.withValues(alpha: .42),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.healing_rounded, color: report.color),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.careTitle,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          report.careDetail,
                          style: const TextStyle(
                            color: AppColors.softText,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CareAction extends StatelessWidget {
  const CareAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: panelDecoration(),
      child: Row(
        children: [
          IconBadge(icon: icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.pulse),
        ],
      ),
    );
  }
}

class RingPainter extends CustomPainter {
  RingPainter(this.progress, this.color);

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * .1;
    final rect = Offset.zero & size;
    final base = Paint()
      ..color = Colors.white.withValues(alpha: .18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final active = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      rect.deflate(stroke),
      -math.pi / 2,
      math.pi * 2,
      false,
      base,
    );
    canvas.drawArc(
      rect.deflate(stroke),
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      active,
    );
  }

  @override
  bool shouldRepaint(covariant RingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class MuscleOverlayPainter extends CustomPainter {
  MuscleOverlayPainter(this.reports);

  final List<MuscleReport> reports;

  @override
  void paint(Canvas canvas, Size size) {
    for (final report in reports) {
      final fill = Paint()
        ..color = report.color.withValues(alpha: .78)
        ..style = PaintingStyle.fill;
      final border = Paint()
        ..color = Colors.white.withValues(alpha: .34)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round;

      for (final polygon in report.polygons) {
        if (polygon.isEmpty) {
          continue;
        }
        final path = Path()
          ..moveTo(
            polygon.first.dx * size.width,
            polygon.first.dy * size.height,
          );
        for (final point in polygon.skip(1)) {
          path.lineTo(point.dx * size.width, point.dy * size.height);
        }
        path.close();
        canvas.drawPath(path, fill);
        canvas.drawPath(path, border);
      }
    }
  }

  @override
  bool shouldRepaint(covariant MuscleOverlayPainter oldDelegate) {
    return oldDelegate.reports != reports;
  }
}
