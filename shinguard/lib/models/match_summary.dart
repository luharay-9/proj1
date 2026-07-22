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
    this.kicks = 0,
    this.goals = 0,
    this.assists = 0,
    this.tackles = 0,
    this.passAccuracy = 0,
    this.clearances = 0,
    this.saves = 0,
    this.goalsConceded = 0,
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
  final int kicks;
  final int goals;
  final int assists;
  final int tackles;
  final double passAccuracy;
  final int clearances;
  final int saves;
  final int goalsConceded;

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
      kicks: intFromMap(map, 'kicks', 0),
      goals: intFromMap(map, 'goals', 0),
      assists: intFromMap(map, 'assists', 0),
      tackles: intFromMap(map, 'tackles', 0),
      passAccuracy: doubleFromMap(map, 'passAccuracy', 0),
      clearances: intFromMap(map, 'clearances', 0),
      saves: intFromMap(map, 'saves', 0),
      goalsConceded: intFromMap(map, 'goalsConceded', 0),
    );
  }
}
