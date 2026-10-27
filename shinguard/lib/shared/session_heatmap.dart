import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../data/demo_data.dart';
import '../data/firebase_data_repository.dart';
import '../models/player_position.dart';
import '../models/session_route.dart';
import '../theme/app_colors.dart';

class SessionHeatmap extends StatefulWidget {
  const SessionHeatmap({required this.sessionId, this.routeStream, super.key});
  final String sessionId;
  final Stream<List<PlayerPosition>>? routeStream;

  @override
  State<SessionHeatmap> createState() => _SessionHeatmapState();
}

class _SessionHeatmapState extends State<SessionHeatmap> {
  late Stream<List<PlayerPosition>> _route;
  bool _showRoute = false;
  RouteCell? _selected;

  @override
  void initState() {
    super.initState();
    _route =
        widget.routeStream ??
        FirebaseDataRepository().watchSessionRoute(widget.sessionId);
  }

  @override
  void didUpdateWidget(SessionHeatmap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sessionId != widget.sessionId ||
        oldWidget.routeStream != widget.routeStream) {
      _route =
          widget.routeStream ??
          FirebaseDataRepository().watchSessionRoute(widget.sessionId);
      _selected = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Position Heatmap',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
            const Text('Route'),
            Switch(
              value: _showRoute,
              onChanged: (value) => setState(() => _showRoute = value),
            ),
          ],
        ),
        StreamBuilder<List<PlayerPosition>>(
          stream: _route,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text('Route unavailable. Please try again.');
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 240,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final data = SessionRoute(snapshot.data ?? []);
            if (data.points.isEmpty) {
              return const SizedBox(
                height: 120,
                child: Center(
                  child: Text('No GPS route recorded for this session.'),
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 420,
                  width: double.infinity,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final size = Size(
                        constraints.maxWidth,
                        constraints.maxHeight,
                      );
                      final displayBounds =
                          widget.sessionId == demoTrainingSessionId
                          ? const Rect.fromLTWH(
                              -34 - demoTrainingStartXMeters,
                              -demoTrainingStartYMeters,
                              68,
                              105,
                            )
                          : data.bounds;
                      return GestureDetector(
                        onTapUp: (event) {
                          final transform = _PitchTransform(
                            displayBounds,
                            size,
                          );
                          final point = transform.inverse(event.localPosition);
                          setState(
                            () => _selected =
                                data.cells[(
                                  (point.dx / SessionRoute.cellMeters).floor(),
                                  (point.dy / SessionRoute.cellMeters).floor(),
                                )],
                          );
                        },
                        child: CustomPaint(
                          painter: _HeatmapPainter(
                            data,
                            _showRoute,
                            _selected,
                            displayBounds,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _selected == null
                      ? '${data.points.length} GPS samples · ${data.cells.length} visited areas'
                      : '${_selected!.visits} visits · ${_selected!.samples} GPS samples',
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 9,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: const LinearGradient(
                      stops: [0, .20, .40, .62, .86],
                      colors: [
                        Color(0xff27d85f),
                        Color(0xff8ee63f),
                        Color(0xffffe343),
                        Color(0xffff9f32),
                        Color(0xffff3b30),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                const Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Low activity',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Medium',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'High activity',
                        textAlign: TextAlign.end,
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _PitchTransform {
  _PitchTransform(this.bounds, Size size) {
    const pitchAspectRatio = 68 / 105;
    final available = Rect.fromLTWH(
      10,
      10,
      math.max(1, size.width - 20),
      math.max(1, size.height - 20),
    );
    late final double pitchWidth;
    late final double pitchHeight;
    if (available.width / available.height > pitchAspectRatio) {
      pitchHeight = available.height;
      pitchWidth = pitchHeight * pitchAspectRatio;
    } else {
      pitchWidth = available.width;
      pitchHeight = pitchWidth / pitchAspectRatio;
    }
    pitch = Rect.fromCenter(
      center: available.center,
      width: pitchWidth,
      height: pitchHeight,
    );
    scale = math.min(
      (pitch.width - 24) / bounds.width,
      (pitch.height - 24) / bounds.height,
    );
    offset = Offset(
      pitch.center.dx - bounds.center.dx * scale,
      pitch.center.dy - bounds.center.dy * scale,
    );
  }
  final Rect bounds;
  late final Rect pitch;
  late final double scale;
  late final Offset offset;
  Offset project(Offset point) => point * scale + offset;
  Offset inverse(Offset point) => (point - offset) / scale;
}

class _HeatmapPainter extends CustomPainter {
  _HeatmapPainter(this.data, this.showRoute, this.selected, this.displayBounds);
  final SessionRoute data;
  final bool showRoute;
  final RouteCell? selected;
  final Rect displayBounds;

  @override
  void paint(Canvas canvas, Size size) {
    final transform = _PitchTransform(displayBounds, size);
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.deepInk);
    _drawPitch(canvas, transform.pitch, lineOpacity: .42);

    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(transform.pitch, const Radius.circular(8)),
    );
    _drawDensityCloud(canvas, transform);
    if (showRoute) {
      final path = Path();
      for (var i = 0; i < data.points.length; i++) {
        final point = transform.project(data.points[i]);
        if (i == 0 || data.times[i] - data.times[i - 1] > 3) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withValues(alpha: .82)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.35,
      );
      canvas.drawCircle(
        transform.project(data.points.first),
        4,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        transform.project(data.points.last),
        4,
        Paint()..color = AppColors.cyan,
      );
    }
    canvas.restore();
    _drawPitch(canvas, transform.pitch, background: false, lineOpacity: .58);

    final selectedCell = selected;
    if (selectedCell != null) {
      final center = transform.project(
        Offset(
          (selectedCell.x + .5) * SessionRoute.cellMeters,
          (selectedCell.y + .5) * SessionRoute.cellMeters,
        ),
      );
      canvas.drawCircle(
        center,
        12,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  void _drawDensityCloud(Canvas canvas, _PitchTransform transform) {
    final pitch = transform.pitch;
    final columns = (pitch.width / 5).round().clamp(42, 72);
    final rows = (pitch.height / 5).round().clamp(64, 112);
    final sources = data.cells.values.map((cell) {
      return (
        center: transform.project(
          Offset(
            (cell.x + .5) * SessionRoute.cellMeters,
            (cell.y + .5) * SessionRoute.cellMeters,
          ),
        ),
        weight: math.sqrt(cell.samples) + cell.visits * .8,
      );
    }).toList();
    final sigma = math.max(20.0, pitch.width * .058);
    final denominator = 2 * sigma * sigma;
    final densities = <double>[];
    final positions = <Offset>[];
    var maximumDensity = 0.0;

    for (var row = 0; row <= rows; row++) {
      final y = pitch.top + pitch.height * row / rows;
      for (var column = 0; column <= columns; column++) {
        final x = pitch.left + pitch.width * column / columns;
        final point = Offset(x, y);
        var density = 0.0;
        for (final source in sources) {
          final delta = point - source.center;
          final squaredDistance = delta.dx * delta.dx + delta.dy * delta.dy;
          density += source.weight * math.exp(-squaredDistance / denominator);
        }
        positions.add(point);
        densities.add(density);
        maximumDensity = math.max(maximumDensity, density);
      }
    }
    if (maximumDensity <= 0) return;

    final colors = densities.map((density) {
      final normalized = math.pow(density / maximumDensity, .72).toDouble();
      final visible = ((normalized - .035) / .18).clamp(0.0, 1.0);
      final alpha = _smoothStep(visible) * .88;
      return _heatColor(normalized).withValues(alpha: alpha);
    }).toList();
    final indices = <int>[];
    final stride = columns + 1;
    for (var row = 0; row < rows; row++) {
      for (var column = 0; column < columns; column++) {
        final topLeft = row * stride + column;
        final topRight = topLeft + 1;
        final bottomLeft = topLeft + stride;
        final bottomRight = bottomLeft + 1;
        indices.addAll([
          topLeft,
          bottomLeft,
          topRight,
          topRight,
          bottomLeft,
          bottomRight,
        ]);
      }
    }
    canvas.drawVertices(
      ui.Vertices(
        ui.VertexMode.triangles,
        positions,
        colors: colors,
        indices: indices,
      ),
      BlendMode.srcOver,
      Paint(),
    );
  }

  double _smoothStep(double value) => value * value * (3 - 2 * value);

  Color _heatColor(double intensity) {
    const colors = [
      Color(0xff27d85f),
      Color(0xff8ee63f),
      Color(0xffffe343),
      Color(0xffff9f32),
      Color(0xffff3b30),
    ];
    const stops = [0.0, .20, .40, .62, .86];
    final value = intensity.clamp(0.0, 1.0);
    for (var index = 0; index < stops.length - 1; index++) {
      if (value <= stops[index + 1]) {
        final local =
            (value - stops[index]) / (stops[index + 1] - stops[index]);
        return Color.lerp(colors[index], colors[index + 1], local)!;
      }
    }
    return colors.last;
  }

  void _drawPitch(
    Canvas canvas,
    Rect pitch, {
    bool background = true,
    required double lineOpacity,
  }) {
    final roundedPitch = RRect.fromRectAndRadius(
      pitch,
      const Radius.circular(8),
    );
    if (background) {
      canvas.drawRRect(roundedPitch, Paint()..color = const Color(0xff12402b));
      canvas.save();
      canvas.clipRRect(roundedPitch);
      final stripeHeight = pitch.height / 10;
      for (var index = 0; index < 10; index++) {
        if (index.isOdd) {
          canvas.drawRect(
            Rect.fromLTWH(
              pitch.left,
              pitch.top + stripeHeight * index,
              pitch.width,
              stripeHeight,
            ),
            Paint()..color = const Color(0xff184932),
          );
        }
      }
      canvas.restore();
    }

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: lineOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.35;
    canvas.drawRRect(roundedPitch, linePaint);
    canvas.drawLine(
      Offset(pitch.left, pitch.center.dy),
      Offset(pitch.right, pitch.center.dy),
      linePaint,
    );
    canvas.drawCircle(pitch.center, pitch.width * (9.15 / 68), linePaint);
    canvas.drawCircle(
      pitch.center,
      1.7,
      Paint()..color = Colors.white.withValues(alpha: lineOpacity),
    );

    final penaltyWidth = pitch.width * (40.32 / 68);
    final penaltyDepth = pitch.height * (16.5 / 105);
    final goalAreaWidth = pitch.width * (18.32 / 68);
    final goalAreaDepth = pitch.height * (5.5 / 105);
    final penaltyLeft = pitch.center.dx - penaltyWidth / 2;
    final goalAreaLeft = pitch.center.dx - goalAreaWidth / 2;
    canvas.drawRect(
      Rect.fromLTWH(penaltyLeft, pitch.top, penaltyWidth, penaltyDepth),
      linePaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        penaltyLeft,
        pitch.bottom - penaltyDepth,
        penaltyWidth,
        penaltyDepth,
      ),
      linePaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(goalAreaLeft, pitch.top, goalAreaWidth, goalAreaDepth),
      linePaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        goalAreaLeft,
        pitch.bottom - goalAreaDepth,
        goalAreaWidth,
        goalAreaDepth,
      ),
      linePaint,
    );

    final spotOffset = pitch.height * (11 / 105);
    final spotPaint = Paint()
      ..color = Colors.white.withValues(alpha: lineOpacity);
    canvas.drawCircle(
      Offset(pitch.center.dx, pitch.top + spotOffset),
      1.5,
      spotPaint,
    );
    canvas.drawCircle(
      Offset(pitch.center.dx, pitch.bottom - spotOffset),
      1.5,
      spotPaint,
    );

    final goalWidth = pitch.width * (7.32 / 68);
    final goalLeft = pitch.center.dx - goalWidth / 2;
    canvas.drawRect(
      Rect.fromLTWH(goalLeft, pitch.top - 5, goalWidth, 5),
      linePaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(goalLeft, pitch.bottom, goalWidth, 5),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(_HeatmapPainter oldDelegate) => true;
}
