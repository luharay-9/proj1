import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shinguard/models/match_summary.dart';
import 'package:shinguard/services/performance_scoring.dart';

void main() {
  MatchSummary match({int goals = 0, int tackles = 0, int clearances = 0}) {
    return MatchSummary(
      title: 'Test match',
      date: 'Today',
      minutes: 90,
      position: 'Midfield',
      result: 'WIN',
      score: '2-0',
      distance: '10 km',
      speed: '27 km/h',
      sprints: 20,
      scoreValue: 0,
      color: Colors.green,
      kicks: 45,
      goals: goals,
      tackles: tackles,
      clearances: clearances,
      passAccuracy: 85,
    );
  }

  test('forward scoring rewards goals more than defense scoring', () {
    final attackingMatch = match(goals: 2);

    expect(
      PerformanceScoring.score(attackingMatch, 'Forward'),
      greaterThan(PerformanceScoring.score(attackingMatch, 'Defense')),
    );
  });

  test('defense scoring rewards tackles and clearances', () {
    final defensiveMatch = match(tackles: 10, clearances: 10);

    expect(
      PerformanceScoring.score(defensiveMatch, 'Defense'),
      greaterThan(PerformanceScoring.score(defensiveMatch, 'Forward')),
    );
  });

  test('average score is derived from match scores', () {
    final matches = [match(goals: 1), match(tackles: 8)];
    final expected =
        ((PerformanceScoring.score(matches[0], 'Midfield') +
                    PerformanceScoring.score(matches[1], 'Midfield')) /
                2)
            .round();

    expect(PerformanceScoring.average(matches, 'Midfield'), expected);
  });
}
