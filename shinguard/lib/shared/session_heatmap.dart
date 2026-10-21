import 'dart:math' as math;
import 'package:flutter/material.dart';
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
  bool _showRoute = true;
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
                  height: 260,
                  width: double.infinity,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final size = Size(
                        constraints.maxWidth,
                        constraints.maxHeight,
                      );
                      return GestureDetector(
                        onTapUp: (event) {
                          final transform = _MapTransform(data.bounds, size);
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
                          painter: _HeatmapPainter(data, _showRoute, _selected),
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
                const SizedBox(height: 8),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Low', style: TextStyle(color: Color(0xff70d883))),
                    Text('Medium', style: TextStyle(color: Color(0xffffcb45))),
                    Text('High', style: TextStyle(color: Color(0xffef5350))),
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

class _MapTransform {
  _MapTransform(this.bounds, Size size) {
    scale = math.min(
      (size.width - 24) / bounds.width,
      (size.height - 24) / bounds.height,
    );
    offset = Offset(
      (size.width - bounds.width * scale) / 2,
      (size.height - bounds.height * scale) / 2,
    );
  }
  final Rect bounds;
  late final double scale;
  late final Offset offset;
  Offset project(Offset point) => (point - bounds.topLeft) * scale + offset;
  Offset inverse(Offset point) => (point - offset) / scale + bounds.topLeft;
}

class _HeatmapPainter extends CustomPainter {
  _HeatmapPainter(this.data, this.showRoute, this.selected);
  final SessionRoute data;
  final bool showRoute;
  final RouteCell? selected;

  @override
  void paint(Canvas canvas, Size size) {
    final transform = _MapTransform(data.bounds, size);
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.panel);
    for (final cell in data.cells.values) {
      final rect = Rect.fromLTWH(
        cell.x * SessionRoute.cellMeters,
        cell.y * SessionRoute.cellMeters,
        SessionRoute.cellMeters,
        SessionRoute.cellMeters,
      );
      final screen = Rect.fromPoints(
        transform.project(rect.topLeft),
        transform.project(rect.bottomRight),
      );
      canvas.drawRect(
        screen.deflate(.5),
        Paint()..color = data.colorFor(cell).withValues(alpha: .75),
      );
      if (selected?.x == cell.x && selected?.y == cell.y) {
        canvas.drawRect(
          screen,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }
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
          ..color = Colors.white70
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
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
  }

  @override
  bool shouldRepaint(_HeatmapPainter oldDelegate) => true;
}
