import 'package:flutter/material.dart';

class TrainingSession {
  const TrainingSession({
    required this.shortName,
    required this.title,
    required this.date,
    required this.position,
    required this.durationLabel,
    required this.result,
    required this.topSpeed,
    required this.sprints,
    required this.kicks,
    required this.typeIcon,
    required this.events,
  });

  final String shortName;
  final String title;
  final String date;
  final String position;
  final String durationLabel;
  final String result;
  final double topSpeed;
  final int sprints;
  final int kicks;
  final IconData typeIcon;
  final List<TimelineEvent> events;
}

class TimelineEvent {
  const TimelineEvent({
    required this.time,
    required this.title,
    required this.detail,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String time;
  final String title;
  final String detail;
  final String value;
  final IconData icon;
  final Color color;
}
