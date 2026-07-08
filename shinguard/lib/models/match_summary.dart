import 'package:flutter/material.dart';

import '../data/firestore_mapping.dart';

class MatchSummary {
  const MatchSummary({
    required this.title,
    required this.date,
    required this.minutes,
    required this.position,
    required this.result,
    required this.score,
    required this.distance,
    required this.speed,
    required this.sprints,
    required this.scoreValue,
    required this.color,
  });

  final String title;
  final String date;
  final int minutes;
  final String position;
  final String result;
  final String score;
  final String distance;
  final String speed;
  final int sprints;
  final int scoreValue;
  final Color color;

  factory MatchSummary.fromMap(Map<String, dynamic> map) {
    return MatchSummary(
      title: stringFromMap(map, 'title', 'Match'),
      date: stringFromMap(map, 'date', ''),
      minutes: intFromMap(map, 'minutes', 0),
      position: stringFromMap(map, 'position', ''),
      result: stringFromMap(map, 'result', ''),
      score: stringFromMap(map, 'score', ''),
      distance: stringFromMap(map, 'distance', ''),
      speed: stringFromMap(map, 'speed', ''),
      sprints: intFromMap(map, 'sprints', 0),
      scoreValue: intFromMap(map, 'scoreValue', 0),
      color: colorFromValue(map['color']),
    );
  }
}
