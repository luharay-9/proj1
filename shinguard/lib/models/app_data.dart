import 'package:flutter/material.dart';

import '../data/firestore_mapping.dart';
import '../theme/app_colors.dart';

class UserAppData {
  const UserAppData({
    required this.displayName,
    required this.profileSubtitle,
    required this.matches,
    required this.goals,
    required this.avgScore,
    required this.readiness,
    required this.metrics,
    required this.tips,
    required this.achievements,
    required this.device,
    required this.performance,
    required this.care,
  });

  final String displayName;
  final String profileSubtitle;
  final int matches;
  final int goals;
  final int avgScore;
  final ReadinessData readiness;
  final List<DashboardMetric> metrics;
  final List<TipData> tips;
  final List<AchievementData> achievements;
  final DeviceData device;
  final PerformanceData performance;
  final CareSummary care;

  factory UserAppData.fromMap(Map<String, dynamic> map) {
    return UserAppData(
      displayName: stringFromMap(map, 'displayName', 'Player'),
      profileSubtitle: stringFromMap(map, 'profileSubtitle', ''),
      matches: intFromMap(map, 'matches', 0),
      goals: intFromMap(map, 'goals', 0),
      avgScore: intFromMap(map, 'avgScore', 0),
      readiness: ReadinessData.fromMap(_nestedMap(map['readiness'])),
      metrics: mapListFromValue(
        map['dashboardMetrics'],
      ).map(DashboardMetric.fromMap).toList(),
      tips: mapListFromValue(map['tips']).map(TipData.fromMap).toList(),
      achievements: mapListFromValue(
        map['achievements'],
      ).map(AchievementData.fromMap).toList(),
      device: DeviceData.fromMap(_nestedMap(map['device'])),
      performance: PerformanceData.fromMap(_nestedMap(map['performance'])),
      care: CareSummary.fromMap(_nestedMap(map['careRisk'])),
    );
  }
}

class ReadinessData {
  const ReadinessData({
    required this.label,
    required this.score,
    required this.progress,
    required this.status,
    required this.detail,
    required this.recoveryLabel,
  });

  final String label;
  final int score;
  final double progress;
  final String status;
  final String detail;
  final String recoveryLabel;

  factory ReadinessData.fromMap(Map<String, dynamic> map) {
    return ReadinessData(
      label: stringFromMap(map, 'label', 'READINESS TODAY'),
      score: intFromMap(map, 'score', 0).clamp(0, 100).toInt(),
      progress: doubleFromMap(map, 'progress', 0).clamp(0, 1).toDouble(),
      status: stringFromMap(map, 'status', ''),
      detail: stringFromMap(map, 'detail', ''),
      recoveryLabel: stringFromMap(map, 'recoveryLabel', ''),
    );
  }
}

class DashboardMetric {
  const DashboardMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  factory DashboardMetric.fromMap(Map<String, dynamic> map) {
    return DashboardMetric(
      icon: iconFromKey(map['icon'], fallback: Icons.query_stats_rounded),
      label: stringFromMap(map, 'label', ''),
      value: stringFromMap(map, 'value', ''),
      color: colorFromValue(map['color']),
    );
  }
}

class TipData {
  const TipData({
    required this.tag,
    required this.title,
    required this.icon,
    required this.color,
  });

  final String tag;
  final String title;
  final IconData icon;
  final Color color;

  factory TipData.fromMap(Map<String, dynamic> map) {
    return TipData(
      tag: stringFromMap(map, 'tag', ''),
      title: stringFromMap(map, 'title', ''),
      icon: iconFromKey(map['icon'], fallback: Icons.self_improvement_rounded),
      color: colorFromValue(map['color']),
    );
  }
}

class AchievementData {
  const AchievementData({required this.icon, required this.title});

  final IconData icon;
  final String title;

  factory AchievementData.fromMap(Map<String, dynamic> map) {
    return AchievementData(
      icon: iconFromKey(map['icon'], fallback: Icons.emoji_events),
      title: stringFromMap(map, 'title', ''),
    );
  }
}

class DeviceData {
  const DeviceData({
    required this.name,
    required this.status,
    required this.firmware,
    required this.battery,
    required this.batteryLabel,
    required this.timeRemaining,
  });

  final String name;
  final String status;
  final String firmware;
  final double battery;
  final String batteryLabel;
  final String timeRemaining;

  factory DeviceData.fromMap(Map<String, dynamic> map) {
    return DeviceData(
      name: stringFromMap(map, 'name', ''),
      status: stringFromMap(map, 'status', ''),
      firmware: stringFromMap(map, 'firmware', ''),
      battery: doubleFromMap(map, 'battery', 0).clamp(0, 1).toDouble(),
      batteryLabel: stringFromMap(map, 'batteryLabel', ''),
      timeRemaining: stringFromMap(map, 'timeRemaining', ''),
    );
  }
}

class PerformanceData {
  const PerformanceData({
    required this.eyebrow,
    required this.distanceRun,
    required this.distanceUnit,
    required this.distanceDelta,
    required this.trendPoints,
    required this.sprintTotal,
    required this.sprintZones,
  });

  final String eyebrow;
  final String distanceRun;
  final String distanceUnit;
  final String distanceDelta;
  final List<double> trendPoints;
  final int sprintTotal;
  final List<SprintZoneData> sprintZones;

  factory PerformanceData.fromMap(Map<String, dynamic> map) {
    final zones = mapListFromValue(
      map['sprintZones'],
    ).map(SprintZoneData.fromMap).toList();
    return PerformanceData(
      eyebrow: stringFromMap(map, 'eyebrow', 'Performance'),
      distanceRun: stringFromMap(map, 'distanceRun', '0'),
      distanceUnit: stringFromMap(map, 'distanceUnit', ''),
      distanceDelta: stringFromMap(map, 'distanceDelta', ''),
      trendPoints: doubleListFromValue(map['trendPoints']),
      sprintTotal: intFromMap(
        map,
        'sprintTotal',
        zones.fold(0, (total, zone) => total + zone.value),
      ),
      sprintZones: zones,
    );
  }
}

class SprintZoneData {
  const SprintZoneData({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final int value;

  factory SprintZoneData.fromMap(Map<String, dynamic> map) {
    return SprintZoneData(
      color: colorFromValue(map['color'], fallback: AppColors.pulse),
      label: stringFromMap(map, 'label', ''),
      value: intFromMap(map, 'value', 0),
    );
  }
}

class CareSummary {
  const CareSummary({
    required this.score,
    required this.progress,
    required this.level,
    required this.detail,
  });

  final int score;
  final double progress;
  final String level;
  final String detail;

  factory CareSummary.fromMap(Map<String, dynamic> map) {
    return CareSummary(
      score: intFromMap(map, 'score', 0).clamp(0, 10).toInt(),
      progress: doubleFromMap(map, 'progress', 0).clamp(0, 1).toDouble(),
      level: stringFromMap(map, 'level', ''),
      detail: stringFromMap(map, 'detail', ''),
    );
  }
}

Map<String, dynamic> _nestedMap(Object? value) {
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return const {};
}
