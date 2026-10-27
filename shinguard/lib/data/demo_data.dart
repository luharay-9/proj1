enum DemoDataSection { home, statistics, care }

const demoDocumentIds = [
  'debug_demo_match_1',
  'debug_demo_match_2',
  'debug_demo_match_3',
  demoTrainingSessionId,
];

const demoTrainingSessionId = 'debug_demo_soccer_training';
const demoRouteDocumentId = 'debug_demo_route';
const demoTrainingStartXMeters = -8.0;
const demoTrainingStartYMeters = 82.0;

const demoMuscleReportIds = [
  'debug_demo_front_quadriceps',
  'debug_demo_front_calf',
  'debug_demo_front_core',
  'debug_demo_back_hamstring',
  'debug_demo_back_calf',
  'debug_demo_back_upper',
];

const demoRootFieldSections = <String, DemoDataSection>{
  'readiness': DemoDataSection.home,
  'dashboardMetrics': DemoDataSection.home,
  'tips': DemoDataSection.home,
  'achievements': DemoDataSection.home,
  'performance': DemoDataSection.statistics,
  'careRisk': DemoDataSection.care,
};

Map<String, dynamic> demoRootFields(Set<DemoDataSection> sections) {
  return {
    if (sections.contains(DemoDataSection.home)) ...{
      'readiness': {
        'label': 'READINESS TODAY',
        'score': 84,
        'progress': .84,
        'status': 'READY',
        'detail': 'Movement load is within your target range',
        'recoveryLabel': '8h recovery',
      },
      'dashboardMetrics': <Map<String, dynamic>>[
        {
          'icon': 'directions_run',
          'label': 'DISTANCE',
          'value': '8.7 km',
          'color': 'cyan',
        },
        {
          'icon': 'speed',
          'label': 'TOP SPEED',
          'value': '28.4 km/h',
          'color': 'gold',
        },
        {'icon': 'bolt', 'label': 'SPRINTS', 'value': '31', 'color': 'green'},
      ],
      'tips': <Map<String, dynamic>>[
        {
          'tag': 'RECOVERY',
          'title': 'Keep tomorrow\'s first session light',
          'icon': 'self_improvement',
          'color': 'cyan',
        },
        {
          'tag': 'LOAD',
          'title': 'Give your left quadriceps extra recovery',
          'icon': 'healing',
          'color': 'gold',
        },
        {
          'tag': 'FORM',
          'title': 'Maintain a shorter stride during accelerations',
          'icon': 'directions_run',
          'color': 'green',
        },
      ],
      'achievements': <Map<String, dynamic>>[
        {'icon': 'local_fire_department', 'title': '5 Match Streak'},
        {'icon': 'speed', 'title': 'Speed Breaker'},
        {'icon': 'star', 'title': 'Top Performer'},
        {'icon': 'shield', 'title': 'Full Match'},
      ],
    },
    if (sections.contains(DemoDataSection.statistics)) ...{
      'performance': {
        'eyebrow': 'Season overview',
        'distanceRun': '29.8',
        'distanceUnit': 'km',
        'distanceDelta': '+12%',
        'trendPoints': <double>[5.8, 7.1, 6.6, 8.3, 7.8, 5.2, 8.7],
        'sprintTotal': 132,
        'sprintZones': <Map<String, dynamic>>[
          {'color': 'green', 'label': 'High intensity', 'value': 51},
          {'color': 'cyan', 'label': 'Moderate', 'value': 52},
          {'color': 'gold', 'label': 'Explosive', 'value': 29},
        ],
      },
    },
    if (sections.contains(DemoDataSection.care))
      'careRisk': {
        'score': 6,
        'progress': .6,
        'level': 'Moderate Load',
        'detail': 'Two areas would benefit from focused recovery today.',
      },
  };
}

List<Map<String, dynamic>> demoMatchDocuments(DateTime now) {
  final matches = [
    (
      id: demoDocumentIds[0],
      daysAgo: 0,
      title: 'League Match vs Harbor FC',
      minutes: 82,
      position: 'Right wing',
      result: 'WIN',
      score: '3-1',
      distance: '8.7 km',
      speed: '28.4 km/h',
      sprints: 31,
      kicks: 48,
      shots: 9,
      goals: 1,
      assists: 1,
      tackles: 3,
      passAccuracy: 86.0,
      color: 'green',
    ),
    (
      id: demoDocumentIds[1],
      daysAgo: 7,
      title: 'Cup Match vs United',
      minutes: 74,
      position: 'Striker',
      result: 'DRAW',
      score: '2-2',
      distance: '7.4 km',
      speed: '27.1 km/h',
      sprints: 27,
      kicks: 41,
      shots: 8,
      goals: 1,
      assists: 0,
      tackles: 2,
      passAccuracy: 79.0,
      color: 'gold',
    ),
    (
      id: demoDocumentIds[2],
      daysAgo: 14,
      title: 'Training Match',
      minutes: 68,
      position: 'Left wing',
      result: 'WIN',
      score: '2-0',
      distance: '6.9 km',
      speed: '26.8 km/h',
      sprints: 28,
      kicks: 44,
      shots: 7,
      goals: 0,
      assists: 2,
      tackles: 4,
      passAccuracy: 88.0,
      color: 'cyan',
    ),
    (
      id: demoTrainingSessionId,
      daysAgo: 2,
      title: 'Soccer Demo Training',
      minutes: 64,
      position: 'Striker',
      result: 'TRAINING',
      score: 'DRILL',
      distance: '5.2 km',
      speed: '30.2 km/h',
      sprints: 46,
      kicks: 78,
      shots: 24,
      goals: 0,
      assists: 0,
      tackles: 1,
      passAccuracy: 84.0,
      color: 'green',
    ),
  ];

  return matches.map((match) {
    final startedAt = now.subtract(Duration(days: match.daysAgo));
    return {
      'id': match.id,
      'order': -startedAt.millisecondsSinceEpoch,
      'sessionId': match.id,
      'title': match.title,
      'date': _demoDateLabel(startedAt),
      'minutes': match.minutes,
      'position': match.position,
      'positionRole': 'Forward',
      'startingPosition': match.position,
      'teamSize': 11,
      'formation': '4-3-3',
      'result': match.result,
      'score': match.score,
      'distance': match.distance,
      'speed': match.speed,
      'sprints': match.sprints,
      'scoreValue': 0,
      'color': match.color,
      'kicks': match.kicks,
      'shots': match.shots,
      'goals': match.goals,
      'assists': match.assists,
      'tackles': match.tackles,
      'passAccuracy': match.passAccuracy,
      'clearances': 1,
      'saves': 0,
      'goalsConceded': 0,
      'startedAt': startedAt,
      'durationSeconds': match.minutes * 60,
      'debugDemo': true,
    };
  }).toList();
}

List<Map<String, dynamic>> demoSessionDocuments(DateTime now) {
  final matches = demoMatchDocuments(now);
  return matches.map((match) {
    final durationMinutes = match['minutes'] as int;
    final sprints = match['sprints'] as int;
    final kicks = match['kicks'] as int;
    final shots = match['shots'] as int;
    final id = match['id'] as String;
    final date = match['date'] as String;
    final isShootingDrill = id == demoTrainingSessionId;
    return {
      'id': id,
      'order': match['order'],
      'sessionId': id,
      'shortName': date.split(',').first,
      'title': match['title'],
      'date': date,
      'position': match['position'],
      'positionRole': match['positionRole'],
      'startingPosition': match['startingPosition'],
      'teamSize': match['teamSize'],
      'formation': match['formation'],
      'durationLabel': '$durationMinutes min',
      'durationSeconds': durationMinutes * 60,
      'result': match['result'],
      'topSpeed': double.parse(
        (match['speed'] as String).replaceFirst(' km/h', ''),
      ),
      'sprints': sprints,
      'kicks': kicks,
      'shots': shots,
      'typeIcon': 'soccer',
      'events': <Map<String, dynamic>>[
        {
          'time': '0:00',
          'title': 'Session started',
          'detail': 'BNO085 and GPS recording began.',
          'value': 'START',
          'icon': 'schedule',
          'color': 'cyan',
        },
        if (isShootingDrill)
          {
            'time': '12:30',
            'title': 'Shooting drill',
            'detail': 'Finishing repetitions concentrated in the bottom half.',
            'value': '$shots shots',
            'icon': 'soccer',
            'color': 'cyan',
          },
        {
          'time': isShootingDrill ? '28:10' : '18:42',
          'title': 'Sprint cluster',
          'detail': isShootingDrill
              ? 'Repeated explosive runs into shooting positions.'
              : 'Four high-intensity acceleration events detected.',
          'value': isShootingDrill ? '8 sprints' : '4 sprints',
          'icon': 'directions_run',
          'color': 'green',
        },
        {
          'time': '46:15',
          'title': 'Peak speed reached',
          'detail': 'Fastest movement during this session.',
          'value': match['speed'],
          'icon': 'speed',
          'color': 'gold',
        },
        {
          'time': '$durationMinutes:00',
          'title': 'Session completed',
          'detail': isShootingDrill
              ? '$sprints sprints and $shots shots recorded.'
              : '$sprints sprints and $kicks touches recorded.',
          'value': '$durationMinutes min',
          'icon': 'health_and_safety',
          'color': 'green',
        },
      ],
      'startedAt': match['startedAt'],
      'debugDemo': true,
    };
  }).toList();
}

List<Map<String, dynamic>> demoSoccerTrainingRoutePoints() {
  const originLatitude = 37.3349;
  const originLongitude = -122.0090;
  const metersPerLatitudeDegree = 111320.0;
  const metersPerLongitudeDegree = 88450.0;
  final points = <Map<String, dynamic>>[];
  var seconds = 0.0;

  void addPoint(double xMeters, double yMeters, double speedKmh) {
    points.add({
      'latitude': originLatitude - yMeters / metersPerLatitudeDegree,
      'longitude': originLongitude + xMeters / metersPerLongitudeDegree,
      'sensorTimeSeconds': seconds,
      'satellites': 10,
      'speedKmh': speedKmh,
    });
    seconds += 1;
  }

  void pauseBetweenRepetitions() => seconds += 4;

  // The drill begins about 25 yards from the attacking goal line.
  addPoint(demoTrainingStartXMeters, demoTrainingStartYMeters, 5);
  pauseBetweenRepetitions();

  // Short check-ins move back toward the 30-yard line before turning toward
  // goal. Their uneven lateral movement avoids an artificial mirrored route.
  const checkInRuns = [
    [(-10.0, 82.0), (-13.0, 79.0), (-9.0, 77.5), (-5.0, 81.0)],
    [(-18.0, 83.0), (-20.0, 79.0), (-16.0, 77.0), (-12.0, 82.0)],
    [(-2.0, 82.0), (2.0, 78.0), (5.0, 77.5), (3.0, 81.0)],
    [(9.0, 83.0), (13.0, 79.0), (10.0, 77.0), (6.0, 82.0)],
    [(-6.0, 81.0), (-3.0, 77.5), (1.0, 79.0), (4.0, 83.0)],
  ];
  for (var repetition = 0; repetition < 2; repetition++) {
    for (final run in checkInRuns) {
      for (var step = 0; step < run.length; step++) {
        addPoint(run[step].$1, run[step].$2, 12 + step * 2);
      }
      pauseBetweenRepetitions();
    }
  }

  // Shooting entries fan out from the 25-yard line, with irregular cuts into
  // the penalty box and a dense set of finishing positions around goal.
  const finishingRuns = [
    [(-18.0, 82.0), (-16.0, 87.0), (-12.0, 92.0), (-8.0, 97.0), (-6.0, 101.0)],
    [(-12.0, 83.0), (-9.0, 86.0), (-5.0, 91.0), (-2.0, 98.0), (-1.0, 101.0)],
    [(-6.0, 81.0), (-8.0, 87.0), (-4.0, 92.0), (-1.0, 96.0), (1.0, 101.0)],
    [(0.0, 83.0), (-3.0, 86.0), (0.0, 91.0), (2.0, 98.0), (3.0, 101.0)],
    [(7.0, 82.0), (4.0, 88.0), (6.0, 92.0), (5.0, 97.0), (4.0, 101.0)],
    [(14.0, 81.0), (11.0, 86.0), (9.0, 91.0), (7.0, 96.0), (6.0, 101.0)],
    [(-15.0, 81.0), (-12.0, 86.0), (-10.0, 93.0), (-5.0, 97.0), (-3.0, 101.0)],
    [(-9.0, 83.0), (-5.0, 88.0), (-7.0, 92.0), (-3.0, 96.0), (-2.0, 101.0)],
    [(-2.0, 82.0), (2.0, 87.0), (1.0, 91.0), (4.0, 98.0), (5.0, 101.0)],
    [(-19.0, 81.0), (-16.0, 86.0), (-13.0, 93.0), (-10.0, 97.0), (-7.0, 101.0)],
    [(-12.0, 83.0), (-15.0, 88.0), (-11.0, 92.0), (-8.0, 96.0), (-6.0, 101.0)],
    [(17.0, 82.0), (14.0, 87.0), (11.0, 91.0), (8.0, 98.0), (5.0, 101.0)],
  ];
  for (var shot = 0; shot < 24; shot++) {
    final run = finishingRuns[shot % finishingRuns.length];
    for (var step = 0; step < run.length; step++) {
      final speed = switch (step) {
        0 => 19.0,
        1 => 23.0,
        2 => 28.0 + (shot % 4),
        3 => 13.0,
        _ => 5.0,
      };
      addPoint(run[step].$1, run[step].$2, speed);
    }
    pauseBetweenRepetitions();
  }

  // Wider repetitions continue down each touchline and finish at either
  // attacking corner, spreading the low-density cloud beyond the box.
  const wideRuns = [
    [
      (-17.0, 82.0),
      (-23.0, 87.0),
      (-28.0, 94.0),
      (-31.0, 99.0),
      (-32.0, 103.0),
    ],
    [(-10.0, 83.0), (-20.0, 88.0), (-27.0, 95.0), (-30.0, 101.0)],
    [(-20.0, 81.0), (-26.0, 86.0), (-30.0, 93.0), (-31.0, 102.0)],
    [
      (-14.0, 82.0),
      (-22.0, 87.0),
      (-28.0, 94.0),
      (-31.0, 100.0),
      (-32.0, 103.0),
    ],
    [(18.0, 83.0), (24.0, 88.0), (29.0, 96.0), (31.0, 102.0)],
  ];
  for (final run in wideRuns) {
    for (var step = 0; step < run.length; step++) {
      addPoint(run[step].$1, run[step].$2, 18 + step * 2);
    }
    pauseBetweenRepetitions();
  }
  return points;
}

List<Map<String, dynamic>> demoMuscleReportDocuments() {
  return [
    _muscleReport(
      id: demoMuscleReportIds[0],
      order: 1,
      view: 'front',
      label: 'Left Quadriceps',
      score: 7,
      detail: 'Elevated load after repeated accelerations.',
      careTitle: 'Active recovery',
      careDetail: 'Use light mobility work and avoid maximal sprints today.',
      polygon: const [
        [.385, .505],
        [.475, .505],
        [.475, .69],
        [.425, .72],
        [.39, .64],
      ],
    ),
    _muscleReport(
      id: demoMuscleReportIds[1],
      order: 2,
      view: 'front',
      label: 'Right Calf',
      score: 5,
      detail: 'Moderate lower-leg load with no severe spike.',
      careTitle: 'Calf mobility',
      careDetail: 'Add gentle calf raises and ankle mobility before training.',
      polygon: const [
        [.535, .72],
        [.60, .73],
        [.59, .89],
        [.55, .91],
        [.53, .82],
      ],
    ),
    _muscleReport(
      id: demoMuscleReportIds[2],
      order: 3,
      view: 'front',
      label: 'Core',
      score: 3,
      detail: 'Normal rotational load for the recorded match.',
      careTitle: 'Maintain routine',
      careDetail: 'Continue normal core activation and hydration.',
      polygon: const [
        [.455, .29],
        [.545, .29],
        [.55, .49],
        [.50, .515],
        [.45, .49],
      ],
    ),
    _muscleReport(
      id: demoMuscleReportIds[3],
      order: 1,
      view: 'back',
      label: 'Right Hamstring',
      score: 8,
      detail: 'High posterior-chain load from repeated top-speed runs.',
      careTitle: 'Reduce sprint volume',
      careDetail: 'Prioritize recovery and reassess before explosive work.',
      polygon: const [
        [.525, .535],
        [.61, .54],
        [.59, .70],
        [.54, .72],
        [.52, .63],
      ],
    ),
    _muscleReport(
      id: demoMuscleReportIds[4],
      order: 2,
      view: 'back',
      label: 'Left Calf',
      score: 4,
      detail: 'Mild accumulated load through the lower leg.',
      careTitle: 'Light recovery',
      careDetail: 'Use easy movement and monitor stiffness tomorrow.',
      polygon: const [
        [.39, .715],
        [.46, .72],
        [.455, .88],
        [.415, .91],
        [.39, .82],
      ],
    ),
    _muscleReport(
      id: demoMuscleReportIds[5],
      order: 3,
      view: 'back',
      label: 'Upper Back',
      score: 2,
      detail: 'Low load with balanced movement on both sides.',
      careTitle: 'No restriction',
      careDetail: 'Continue normal warm-up and recovery habits.',
      polygon: const [
        [.39, .19],
        [.61, .19],
        [.58, .34],
        [.50, .365],
        [.42, .34],
      ],
    ),
  ];
}

Map<String, dynamic> _muscleReport({
  required String id,
  required int order,
  required String view,
  required String label,
  required int score,
  required String detail,
  required String careTitle,
  required String careDetail,
  required List<List<double>> polygon,
}) {
  return {
    'id': id,
    'order': order,
    'view': view,
    'label': label,
    'score': score,
    'detail': detail,
    'careTitle': careTitle,
    'careDetail': careDetail,
    'polygons': [
      {
        'points': polygon
            .map((point) => {'x': point[0], 'y': point[1]})
            .toList(),
      },
    ],
    'debugDemo': true,
  };
}

String _demoDateLabel(DateTime date) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}
