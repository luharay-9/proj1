import 'package:flutter/material.dart';

import '../data/firestore_mapping.dart';

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

  factory TrainingSession.fromMap(Map<String, dynamic> map) {
    return TrainingSession(
      shortName: stringFromMap(map, 'shortName', 'Session'),
      title: stringFromMap(map, 'title', 'Training Session'),
      date: stringFromMap(map, 'date', ''),
      position: stringFromMap(map, 'position', ''),
      durationLabel: stringFromMap(map, 'durationLabel', ''),
      result: stringFromMap(map, 'result', ''),
      topSpeed: doubleFromMap(map, 'topSpeed', 0),
      sprints: intFromMap(map, 'sprints', 0),
      kicks: intFromMap(map, 'kicks', 0),
      typeIcon: iconFromKey(
        map['typeIcon'],
        fallback: Icons.sports_soccer_rounded,
      ),
      events: mapListFromValue(
        map['events'],
      ).map(TimelineEvent.fromMap).toList(),
    );
  }
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

  factory TimelineEvent.fromMap(Map<String, dynamic> map) {
    return TimelineEvent(
      time: stringFromMap(map, 'time', ''),
      title: stringFromMap(map, 'title', 'Event'),
      detail: stringFromMap(map, 'detail', ''),
      value: stringFromMap(map, 'value', ''),
      icon: iconFromKey(map['icon'], fallback: Icons.timeline_rounded),
      color: colorFromValue(map['color']),
    );
  }
}
