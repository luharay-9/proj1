import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

IconData iconFromKey(Object? value, {IconData fallback = Icons.circle}) {
  return switch (value) {
    'accessibility' => Icons.accessibility_rounded,
    'accessibility_new' => Icons.accessibility_new_rounded,
    'balance' => Icons.balance_rounded,
    'bolt' => Icons.bolt_rounded,
    'directions_run' => Icons.directions_run_rounded,
    'emoji_events' => Icons.emoji_events,
    'family_restroom' => Icons.family_restroom,
    'fitness_center' => Icons.fitness_center_rounded,
    'groups' => Icons.groups_rounded,
    'healing' => Icons.healing_rounded,
    'health_and_safety' => Icons.health_and_safety_rounded,
    'local_fire_department' => Icons.local_fire_department,
    'notifications' => Icons.notifications_rounded,
    'schedule' => Icons.schedule_rounded,
    'self_improvement' => Icons.self_improvement_rounded,
    'shield' => Icons.shield_rounded,
    'soccer' => Icons.sports_soccer_rounded,
    'speed' => Icons.speed_rounded,
    'swap_calls' => Icons.swap_calls_rounded,
    'timeline' => Icons.timeline_rounded,
    'warning' => Icons.warning_rounded,
    _ => fallback,
  };
}

Color colorFromValue(Object? value, {Color fallback = AppColors.pulse}) {
  if (value is int) {
    return Color(value);
  }
  if (value is String) {
    final named = switch (value) {
      'cyan' => AppColors.cyan,
      'gold' => AppColors.gold,
      'green' => AppColors.pulse,
      'muted' => AppColors.muted,
      'red' => AppColors.red,
      'violet' => AppColors.violet,
      _ => null,
    };
    if (named != null) {
      return named;
    }

    final normalized = value.replaceFirst('#', '').replaceFirst('0x', '');
    final hex = normalized.length == 6 ? 'ff$normalized' : normalized;
    final parsed = int.tryParse(hex, radix: 16);
    if (parsed != null) {
      return Color(parsed);
    }
  }
  return fallback;
}

String stringFromMap(Map<String, dynamic> map, String key, String fallback) {
  final value = map[key];
  return value is String && value.trim().isNotEmpty ? value : fallback;
}

int intFromMap(Map<String, dynamic> map, String key, int fallback) {
  final value = map[key];
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.round();
  }
  if (value is String) {
    return int.tryParse(value) ?? fallback;
  }
  return fallback;
}

bool boolFromMap(Map<String, dynamic> map, String key, bool fallback) {
  final value = map[key];
  if (value is bool) {
    return value;
  }
  if (value is String) {
    return switch (value.toLowerCase()) {
      'true' || 'yes' || '1' => true,
      'false' || 'no' || '0' => false,
      _ => fallback,
    };
  }
  return fallback;
}

double doubleFromMap(Map<String, dynamic> map, String key, double fallback) {
  final value = map[key];
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value) ?? fallback;
  }
  return fallback;
}

List<Map<String, dynamic>> mapListFromValue(Object? value) {
  if (value is! Iterable) {
    return const [];
  }
  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}

List<double> doubleListFromValue(Object? value) {
  if (value is! Iterable) {
    return const [];
  }
  return value.whereType<num>().map((item) => item.toDouble()).toList();
}
