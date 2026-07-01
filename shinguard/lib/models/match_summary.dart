import 'package:flutter/material.dart';

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
}
