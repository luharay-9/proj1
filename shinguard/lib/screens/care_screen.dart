import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/firebase_data_repository.dart';
import '../models/app_data.dart';
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
  final FirebaseDataRepository _repository = FirebaseDataRepository();

  @override
  Widget build(BuildContext context) {
    final isFront = viewIndex == 0;
    final view = isFront ? 'front' : 'back';

    return StreamBuilder<UserAppData>(
      stream: _repository.watchUserData(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const AppLoading();
        }
        if (userSnapshot.hasError || !userSnapshot.hasData) {
          return const AppMessage(
            title: 'Care data unavailable',
            detail: 'Check your Firebase profile careRisk data.',
            icon: Icons.cloud_off_rounded,
          );
        }

        return StreamBuilder<List<MuscleReport>>(
          stream: _repository.watchMuscleReports(view),
          builder: (context, reportSnapshot) {
            final reports = reportSnapshot.data ?? const <MuscleReport>[];
            return AppScrollView(
              children: [
                const TopBar(
                  eyebrow: 'AI-powered prevention insights',
                  title: 'Injury Care',
                ),
                const SizedBox(height: 18),
                RiskScoreCard(summary: userSnapshot.data!.care),
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
                if (reportSnapshot.connectionState == ConnectionState.waiting)
                  const AppLoading()
                else if (reports.isEmpty)
                  const AppMessage(title: 'No muscle reports synced yet')
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: panelDecoration(),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(0, 5, 4, 5),
                            child: DiagramRiskMap(
                              assetPath: isFront
                                  ? 'assets/DiagramFront.png'
                                  : 'assets/DiagramBack.png',
                              reports: reports,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 6,
                          child: Column(
                            children: reports
                                .map(
                                  (report) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: RiskRow(
                                      report: report,
                                      onTap: () =>
                                          _showReportSheet(context, report),
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
          },
        );
      },
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
  const RiskScoreCard({required this.summary, super.key});

  final CareSummary summary;

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
              painter: RingPainter(summary.progress, AppColors.gold),
              child: Center(
                child: Text(
                  '${summary.score}',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
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
                  summary.level,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                Text(
                  summary.detail,
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
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: MediaQuery.textScalerOf(context).scale(10),
                  ),
                ),
              ),
              Text(
                '${report.score}/10',
                style: TextStyle(
                  color: report.color,
                  fontWeight: FontWeight.w900,
                  fontSize: MediaQuery.textScalerOf(context).scale(10),
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
