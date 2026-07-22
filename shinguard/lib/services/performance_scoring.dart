import '../models/match_summary.dart';
import '../models/training_session.dart';

class PerformanceScoring {
  const PerformanceScoring._();

  static int score(MatchSummary match, String selectedPosition) {
    final metrics = <String, double>{
      'minutes': _ratio(match.minutes, 90),
      'distance': _ratio(_numberFromLabel(match.distance), 10),
      'speed': _ratio(_numberFromLabel(match.speed), 30),
      'sprints': _ratio(match.sprints, 25),
      'kicks': _ratio(match.kicks, 60),
      'goals': _ratio(match.goals, 2),
      'assists': _ratio(match.assists, 2),
      'tackles': _ratio(match.tackles, 10),
      'passAccuracy': _ratio(match.passAccuracy, 100),
      'clearances': _ratio(match.clearances, 10),
      'saves': _ratio(match.saves, 8),
      'shotPrevention': (1 - _ratio(match.goalsConceded, 4)).clamp(0, 1),
    };

    final weights = _weightsFor(selectedPosition);
    var weightedTotal = 0.0;
    for (final entry in weights.entries) {
      weightedTotal += (metrics[entry.key] ?? 0) * entry.value;
    }

    return (35 + weightedTotal * 65).round().clamp(35, 100).toInt();
  }

  static int average(List<MatchSummary> matches, String selectedPosition) {
    if (matches.isEmpty) {
      return 0;
    }
    final total = matches.fold<int>(
      0,
      (sum, match) => sum + score(match, selectedPosition),
    );
    return (total / matches.length).round();
  }

  static int sessionScore(TrainingSession session, String selectedPosition) {
    final metrics = <String, double>{
      'minutes': _ratio(_numberFromLabel(session.durationLabel), 90),
      'speed': _ratio(session.topSpeed, 30),
      'sprints': _ratio(session.sprints, 25),
      'kicks': _ratio(session.kicks, 60),
    };
    final weights = switch (selectedPosition.toLowerCase()) {
      'forward' => const {
        'minutes': .10,
        'speed': .30,
        'sprints': .25,
        'kicks': .35,
      },
      'defense' => const {
        'minutes': .30,
        'speed': .20,
        'sprints': .30,
        'kicks': .20,
      },
      'goalkeeper' => const {
        'minutes': .40,
        'speed': .10,
        'sprints': .10,
        'kicks': .40,
      },
      _ => const {'minutes': .25, 'speed': .20, 'sprints': .25, 'kicks': .30},
    };
    var weightedTotal = 0.0;
    for (final entry in weights.entries) {
      weightedTotal += (metrics[entry.key] ?? 0) * entry.value;
    }
    return (35 + weightedTotal * 65).round().clamp(35, 100).toInt();
  }

  static Map<String, double> _weightsFor(String position) {
    return switch (position.toLowerCase()) {
      'forward' => const {
        'minutes': .10,
        'distance': .10,
        'speed': .15,
        'sprints': .15,
        'kicks': .15,
        'goals': .20,
        'assists': .10,
        'passAccuracy': .05,
      },
      'defense' => const {
        'minutes': .10,
        'distance': .12,
        'speed': .08,
        'sprints': .08,
        'kicks': .05,
        'tackles': .22,
        'passAccuracy': .15,
        'clearances': .20,
      },
      'goalkeeper' => const {
        'minutes': .10,
        'distance': .05,
        'speed': .05,
        'kicks': .10,
        'passAccuracy': .15,
        'saves': .35,
        'shotPrevention': .20,
      },
      _ => const {
        'minutes': .10,
        'distance': .18,
        'speed': .08,
        'sprints': .12,
        'kicks': .10,
        'assists': .12,
        'tackles': .10,
        'passAccuracy': .20,
      },
    };
  }

  static double _ratio(num value, num target) {
    if (target <= 0) {
      return 0;
    }
    return (value / target).clamp(0, 1).toDouble();
  }

  static double _numberFromLabel(String value) {
    final match = RegExp(r'-?\d+(?:\.\d+)?').firstMatch(value);
    return double.tryParse(match?.group(0) ?? '') ?? 0;
  }
}
