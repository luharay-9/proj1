import 'package:flutter/material.dart';

import '../data/firestore_mapping.dart';
import '../theme/app_colors.dart';

class MuscleReport {
  const MuscleReport({
    required this.label,
    required this.score,
    required this.detail,
    required this.careTitle,
    required this.careDetail,
    required this.polygons,
  });

  final String label;
  final int score;
  final String detail;
  final String careTitle;
  final String careDetail;
  final List<List<Offset>> polygons;

  factory MuscleReport.fromMap(Map<String, dynamic> map) {
    return MuscleReport(
      label: stringFromMap(map, 'label', 'Area'),
      score: intFromMap(map, 'score', 1).clamp(1, 10).toInt(),
      detail: stringFromMap(map, 'detail', ''),
      careTitle: stringFromMap(map, 'careTitle', 'Recommended care'),
      careDetail: stringFromMap(map, 'careDetail', ''),
      polygons: _polygonsFromValue(map['polygons']),
    );
  }

  Color get color {
    final normalized = ((score.clamp(1, 10) - 1) / 9).toDouble();
    if (normalized <= .5) {
      return Color.lerp(AppColors.pulse, AppColors.gold, normalized * 2)!;
    }
    return Color.lerp(AppColors.gold, AppColors.red, (normalized - .5) * 2)!;
  }
}

List<List<Offset>> _polygonsFromValue(Object? value) {
  if (value is! Iterable) {
    return const [];
  }
  return value
      .map((polygon) {
        if (polygon is! Iterable) {
          return <Offset>[];
        }
        return polygon.map((point) {
          if (point is Map) {
            final mapped = Map<String, dynamic>.from(point);
            return Offset(
              doubleFromMap(mapped, 'x', 0),
              doubleFromMap(mapped, 'y', 0),
            );
          }
          if (point is Iterable) {
            final values = point.whereType<num>().toList();
            if (values.length >= 2) {
              return Offset(values[0].toDouble(), values[1].toDouble());
            }
          }
          return Offset.zero;
        }).toList();
      })
      .where((polygon) => polygon.length >= 3)
      .toList();
}
