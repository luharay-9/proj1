enum DemoDataSection { home, statistics, care }

const demoDocumentIds = [
  'debug_demo_match_1',
  'debug_demo_match_2',
  'debug_demo_match_3',
];

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
        'distanceRun': '24.6',
        'distanceUnit': 'km',
        'distanceDelta': '+12%',
        'trendPoints': <double>[5.8, 7.1, 6.6, 8.3, 7.8, 9.2, 8.7],
        'sprintTotal': 86,
        'sprintZones': <Map<String, dynamic>>[
          {'color': 'green', 'label': 'High intensity', 'value': 31},
          {'color': 'cyan', 'label': 'Moderate', 'value': 37},
          {'color': 'gold', 'label': 'Explosive', 'value': 18},
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
      goals: 0,
      assists: 2,
      tackles: 4,
      passAccuracy: 88.0,
      color: 'cyan',
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
    final id = match['id'] as String;
    final date = match['date'] as String;
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
        {
          'time': '18:42',
          'title': 'Sprint cluster',
          'detail': 'Four high-intensity acceleration events detected.',
          'value': '4 sprints',
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
          'detail': '$sprints sprints and $kicks touches recorded.',
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
