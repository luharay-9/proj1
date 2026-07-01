import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/demo_data.dart';
import '../models/match_summary.dart';
import '../shared/shared_widgets.dart';
import '../theme/app_colors.dart';

class PerformanceScreen extends StatefulWidget {
  const PerformanceScreen({super.key});

  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen> {
  int rangeIndex = 2;

  @override
  Widget build(BuildContext context) {
    return AppScrollView(
      children: [
        const TopBar(eyebrow: 'Past year · 46 sessions', title: 'Performance'),
        const SizedBox(height: 18),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 0, label: Text('Week')),
            ButtonSegment(value: 1, label: Text('Month')),
            ButtonSegment(value: 2, label: Text('Year')),
          ],
          selected: {rangeIndex},
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
            setState(() => rangeIndex = value.first);
          },
        ),
        const SizedBox(height: 18),
        const TrendCard(
          title: 'DISTANCE RUN',
          value: '641.8',
          unit: 'km',
          delta: '+22%',
          points: [18, 25, 28, 36, 44, 41, 47, 50, 49, 56, 62, 68],
        ),
        const SizedBox(height: 20),
        const SectionTitle('Sprint Zones'),
        const SprintZonesCard(),
        const SizedBox(height: 20),
        const SectionTitle('Year History'),
        const SizedBox(height: 10),
        ...yearSessions.map((match) => HistoryCard(match: match)),
      ],
    );
  }
}

class TrendCard extends StatelessWidget {
  const TrendCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.delta,
    required this.points,
    super.key,
  });

  final String title;
  final String value;
  final String unit;
  final String delta;
  final List<double> points;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 178,
      padding: const EdgeInsets.all(18),
      decoration: panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.pulse.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  delta,
                  style: const TextStyle(
                    color: AppColors.pulse,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: const TextStyle(
                    color: AppColors.softText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          SizedBox(
            height: 64,
            child: CustomPaint(
              painter: LineChartPainter(points),
              size: Size.infinite,
            ),
          ),
        ],
      ),
    );
  }
}

class SprintZonesCard extends StatelessWidget {
  const SprintZonesCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: panelDecoration(),
      child: Row(
        children: [
          SizedBox(
            width: 112,
            height: 112,
            child: CustomPaint(
              painter: DonutPainter(),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '240',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'SPRINTS',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          const Expanded(
            child: Column(
              children: [
                LegendRow(color: AppColors.pulse, label: 'Low', value: '128'),
                LegendRow(color: AppColors.gold, label: 'Medium', value: '82'),
                LegendRow(color: AppColors.red, label: 'High', value: '30'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LegendRow extends StatelessWidget {
  const LegendRow({
    required this.color,
    required this.label,
    required this.value,
    super.key,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          CircleAvatar(radius: 5, backgroundColor: color),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class HistoryCard extends StatelessWidget {
  const HistoryCard({required this.match, super.key});

  final MatchSummary match;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [match.color.withValues(alpha: .58), AppColors.panel],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusPill(label: match.result, icon: Icons.circle),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: .35),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  match.score,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),
          Text(
            match.title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            '${match.date} · ${match.minutes} min · ${match.position}',
            style: const TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              HistoryMetric(value: match.distance, label: 'Distance'),
              HistoryMetric(value: match.speed, label: 'Top Speed'),
              HistoryMetric(value: '${match.sprints}', label: 'Sprints'),
              HistoryMetric(value: '${match.scoreValue}', label: 'Score'),
            ],
          ),
        ],
      ),
    );
  }
}

class HistoryMetric extends StatelessWidget {
  const HistoryMetric({required this.value, required this.label, super.key});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class LineChartPainter extends CustomPainter {
  LineChartPainter(this.points);

  final List<double> points;

  @override
  void paint(Canvas canvas, Size size) {
    final minValue = points.reduce(math.min);
    final maxValue = points.reduce(math.max);
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = i / (points.length - 1) * size.width;
      final normalized = (points[i] - minValue) / (maxValue - minValue);
      final y = size.height - normalized * size.height * .82 - 6;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    final fillPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0x775fe781), Color(0x005fe781)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Offset.zero & size);
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = AppColors.pulse
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant LineChartPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}

class DonutPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.butt;
    final segments = [
      (AppColors.pulse, .53),
      (AppColors.gold, .34),
      (AppColors.red, .13),
    ];
    var start = -math.pi / 2;
    for (final segment in segments) {
      paint.color = segment.$1;
      final sweep = math.pi * 2 * segment.$2;
      canvas.drawArc(rect.deflate(12), start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
