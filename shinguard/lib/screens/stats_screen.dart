import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/firebase_data_repository.dart';
import '../models/app_data.dart';
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
  final FirebaseDataRepository _repository = FirebaseDataRepository();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserAppData>(
      stream: _repository.watchUserData(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const AppLoading();
        }
        if (userSnapshot.hasError || !userSnapshot.hasData) {
          return const AppMessage(
            title: 'Performance unavailable',
            detail: 'Check your Firebase profile performance data.',
            icon: Icons.cloud_off_rounded,
          );
        }

        final performance = userSnapshot.data!.performance;
        return StreamBuilder<List<MatchSummary>>(
          stream: _repository.watchMatches(),
          builder: (context, matchSnapshot) {
            final matches = matchSnapshot.data ?? const <MatchSummary>[];
            return AppScrollView(
              children: [
                TopBar(eyebrow: performance.eyebrow, title: 'Performance'),
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
                TrendCard(
                  title: 'DISTANCE RUN',
                  value: performance.distanceRun,
                  unit: performance.distanceUnit,
                  delta: performance.distanceDelta,
                  points: performance.trendPoints,
                ),
                const SizedBox(height: 20),
                const SectionTitle('Sprint Zones'),
                SprintZonesCard(
                  total: performance.sprintTotal,
                  zones: performance.sprintZones,
                ),
                const SizedBox(height: 20),
                const SectionTitle('Year History'),
                const SizedBox(height: 10),
                if (matchSnapshot.connectionState == ConnectionState.waiting)
                  const AppLoading()
                else if (matches.isEmpty)
                  const AppMessage(title: 'No match history synced yet')
                else
                  ...matches.map((match) => HistoryCard(match: match)),
              ],
            );
          },
        );
      },
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
      height: MediaQuery.of(context).size.height * 0.23,
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
  const SprintZonesCard({required this.total, required this.zones, super.key});

  final int total;
  final List<SprintZoneData> zones;

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
              painter: DonutPainter(zones),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$total',
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
          Expanded(
            child: Column(
              children: zones
                  .map(
                    (zone) => LegendRow(
                      color: zone.color,
                      label: zone.label,
                      value: '${zone.value}',
                    ),
                  )
                  .toList(),
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
    if (points.length < 2) {
      return;
    }
    final minValue = points.reduce(math.min);
    final maxValue = points.reduce(math.max);
    final spread = maxValue - minValue;
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = i / (points.length - 1) * size.width;
      final normalized = spread == 0 ? .5 : (points[i] - minValue) / spread;
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
  DonutPainter(this.zones);

  final List<SprintZoneData> zones;

  @override
  void paint(Canvas canvas, Size size) {
    if (zones.isEmpty) {
      return;
    }
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.butt;
    final total = zones.fold(0, (sum, zone) => sum + zone.value);
    var start = -math.pi / 2;
    for (final zone in zones) {
      paint.color = zone.color;
      final sweep =
          math.pi * 2 * (total == 0 ? 1 / zones.length : zone.value / total);
      canvas.drawArc(rect.deflate(12), start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant DonutPainter oldDelegate) {
    return oldDelegate.zones != zones;
  }
}
