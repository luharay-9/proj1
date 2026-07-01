import 'package:flutter/material.dart';

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

  Color get color {
    final normalized = ((score.clamp(1, 10) - 1) / 9).toDouble();
    if (normalized <= .5) {
      return Color.lerp(AppColors.pulse, AppColors.gold, normalized * 2)!;
    }
    return Color.lerp(AppColors.gold, AppColors.red, (normalized - .5) * 2)!;
  }
}
