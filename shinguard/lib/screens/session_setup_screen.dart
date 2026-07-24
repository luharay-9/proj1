import 'package:flutter/material.dart';

import '../services/session_recording_service.dart';
import '../theme/app_colors.dart';

const supportedTeamSizes = [5, 7, 9, 11];

class SessionFormation {
  const SessionFormation({
    required this.teamSize,
    required this.name,
    required this.lines,
  });

  final int teamSize;
  final String name;
  final List<int> lines;

  List<FormationSpot> get spots {
    final spots = <FormationSpot>[
      const FormationSpot(
        id: 'goalkeeper',
        label: 'Goalkeeper',
        abbreviation: 'GK',
        role: 'Goalkeeper',
        x: .5,
        y: .9,
      ),
    ];
    const lineY = [.7, .45, .2];
    const roles = ['Defense', 'Midfield', 'Forward'];

    for (var lineIndex = 0; lineIndex < lines.length; lineIndex++) {
      final count = lines[lineIndex];
      final role = roles[lineIndex];
      for (var playerIndex = 0; playerIndex < count; playerIndex++) {
        final label = _positionLabel(role, playerIndex, count);
        spots.add(
          FormationSpot(
            id: '${role.toLowerCase()}_$playerIndex',
            label: label,
            abbreviation: _positionAbbreviation(label),
            role: role,
            x: (playerIndex + 1) / (count + 1),
            y: lineY[lineIndex],
          ),
        );
      }
    }
    return spots;
  }
}

class FormationSpot {
  const FormationSpot({
    required this.id,
    required this.label,
    required this.abbreviation,
    required this.role,
    required this.x,
    required this.y,
  });

  final String id;
  final String label;
  final String abbreviation;
  final String role;
  final double x;
  final double y;
}

class SessionSetupSelection {
  const SessionSetupSelection({
    required this.teamSize,
    required this.formation,
    required this.spot,
  });

  final int teamSize;
  final String formation;
  final FormationSpot spot;
}

List<SessionFormation> sessionFormationsFor(int teamSize) {
  return switch (teamSize) {
    5 => const [
      SessionFormation(teamSize: 5, name: '1-2-1', lines: [1, 2, 1]),
      SessionFormation(teamSize: 5, name: '2-1-1', lines: [2, 1, 1]),
      SessionFormation(teamSize: 5, name: '1-1-2', lines: [1, 1, 2]),
    ],
    7 => const [
      SessionFormation(teamSize: 7, name: '2-3-1', lines: [2, 3, 1]),
      SessionFormation(teamSize: 7, name: '3-2-1', lines: [3, 2, 1]),
      SessionFormation(teamSize: 7, name: '2-2-2', lines: [2, 2, 2]),
    ],
    9 => const [
      SessionFormation(teamSize: 9, name: '3-3-2', lines: [3, 3, 2]),
      SessionFormation(teamSize: 9, name: '3-2-3', lines: [3, 2, 3]),
      SessionFormation(teamSize: 9, name: '2-3-3', lines: [2, 3, 3]),
    ],
    11 => const [
      SessionFormation(teamSize: 11, name: '4-3-3', lines: [4, 3, 3]),
      SessionFormation(teamSize: 11, name: '4-4-2', lines: [4, 4, 2]),
      SessionFormation(teamSize: 11, name: '3-5-2', lines: [3, 5, 2]),
    ],
    _ => const [],
  };
}

class SessionSetupScreen extends StatefulWidget {
  const SessionSetupScreen({this.onConfirm, super.key});

  final Future<void> Function(SessionSetupSelection selection)? onConfirm;

  @override
  State<SessionSetupScreen> createState() => _SessionSetupScreenState();
}

class _SessionSetupScreenState extends State<SessionSetupScreen> {
  int _step = 0;
  int? _teamSize;
  SessionFormation? _formation;
  FormationSpot? _spot;
  bool _isStarting = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set Up Session')),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
              child: _SessionStepIndicator(currentStep: _step),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 12),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: _StepHeading(
                  key: ValueKey(_step),
                  title: switch (_step) {
                    0 => 'Select team size',
                    1 => 'Select your formation',
                    _ => 'Select your starting position',
                  },
                  detail: switch (_step) {
                    0 => 'How many players are on each team?',
                    1 => '${_teamSize}v$_teamSize',
                    _ => _formation?.name ?? '',
                  },
                ),
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: switch (_step) {
                  0 => _TeamSizeStep(
                    key: const ValueKey('team-size'),
                    selectedSize: _teamSize,
                    onSelected: _selectTeamSize,
                  ),
                  1 => _FormationStep(
                    key: ValueKey('formation-$_teamSize'),
                    formations: sessionFormationsFor(_teamSize ?? 0),
                    selectedFormation: _formation,
                    onSelected: _selectFormation,
                  ),
                  _ => _PositionStep(
                    key: ValueKey('position-${_formation?.name}'),
                    formation: _formation!,
                    selectedSpot: _spot,
                    onSelected: (spot) => setState(() {
                      _spot = spot;
                      _errorMessage = null;
                    }),
                  ),
                },
              ),
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 10, 22, 0),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.red,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 18),
          child: Row(
            children: [
              if (_step > 0) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isStarting ? null : _previousStep,
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Back'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: FilledButton.icon(
                  onPressed: _canContinue && !_isStarting
                      ? _continueOrConfirm
                      : null,
                  icon: _isStarting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.ink,
                          ),
                        )
                      : Icon(
                          _step == 2
                              ? Icons.check_rounded
                              : Icons.arrow_forward_rounded,
                        ),
                  label: Text(
                    _isStarting
                        ? 'Starting...'
                        : _step == 2
                        ? 'Confirm'
                        : 'Continue',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.pulse,
                    foregroundColor: AppColors.ink,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _canContinue {
    return switch (_step) {
      0 => _teamSize != null,
      1 => _formation != null,
      _ => _spot != null,
    };
  }

  void _selectTeamSize(int teamSize) {
    setState(() {
      _teamSize = teamSize;
      _formation = null;
      _spot = null;
      _errorMessage = null;
    });
  }

  void _selectFormation(SessionFormation formation) {
    setState(() {
      _formation = formation;
      _spot = null;
      _errorMessage = null;
    });
  }

  void _previousStep() {
    setState(() {
      _step--;
      _errorMessage = null;
    });
  }

  Future<void> _continueOrConfirm() async {
    if (_step < 2) {
      setState(() => _step++);
      return;
    }

    final selection = SessionSetupSelection(
      teamSize: _teamSize!,
      formation: _formation!.name,
      spot: _spot!,
    );
    setState(() {
      _isStarting = true;
      _errorMessage = null;
    });

    try {
      final callback = widget.onConfirm;
      if (callback != null) {
        await callback(selection);
      } else {
        final recorder = SessionRecordingService.instance;
        await recorder.startSession(
          position: selection.spot.role,
          startingPosition: selection.spot.label,
          teamSize: selection.teamSize,
          formation: selection.formation,
        );
        if (recorder.currentState.status != SessionRecordingStatus.recording) {
          throw StateError(recorder.currentState.message);
        }
      }
      if (mounted) {
        Navigator.of(context).pop(selection);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isStarting = false;
          _errorMessage = error is StateError
              ? error.message.toString()
              : 'Unable to start this session.';
        });
      }
    }
  }
}

class _SessionStepIndicator extends StatelessWidget {
  const _SessionStepIndicator({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    const labels = ['Team', 'Formation', 'Position'];
    return Row(
      children: List.generate(labels.length, (index) {
        final active = index <= currentStep;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == labels.length - 1 ? 0 : 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: active ? AppColors.pulse : AppColors.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  labels[index],
                  style: TextStyle(
                    color: active ? AppColors.softText : AppColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _StepHeading extends StatelessWidget {
  const _StepHeading({required this.title, required this.detail, super.key});

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
        ),
        if (detail.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            detail,
            style: const TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}

class _TeamSizeStep extends StatelessWidget {
  const _TeamSizeStep({
    required this.selectedSize,
    required this.onSelected,
    super.key,
  });

  final int? selectedSize;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
      child: Column(
        children: [
          const Expanded(child: SoccerPitch(spots: [])),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: 54,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemCount: supportedTeamSizes.length,
            itemBuilder: (context, index) {
              final size = supportedTeamSizes[index];
              final selected = selectedSize == size;
              return ChoiceChip(
                selected: selected,
                showCheckmark: false,
                avatar: Icon(
                  Icons.groups_rounded,
                  size: 18,
                  color: selected ? AppColors.ink : AppColors.pulse,
                ),
                label: Text('${size}v$size'),
                labelStyle: TextStyle(
                  color: selected ? AppColors.ink : AppColors.text,
                  fontWeight: FontWeight.w900,
                ),
                selectedColor: AppColors.pulse,
                backgroundColor: AppColors.panel,
                side: BorderSide(
                  color: selected ? AppColors.pulse : AppColors.line,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                onSelected: (_) => onSelected(size),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FormationStep extends StatelessWidget {
  const _FormationStep({
    required this.formations,
    required this.selectedFormation,
    required this.onSelected,
    super.key,
  });

  final List<SessionFormation> formations;
  final SessionFormation? selectedFormation;
  final ValueChanged<SessionFormation> onSelected;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
      scrollDirection: Axis.horizontal,
      itemCount: formations.length,
      separatorBuilder: (_, _) => const SizedBox(width: 12),
      itemBuilder: (context, index) {
        final formation = formations[index];
        final selected = selectedFormation?.name == formation.name;
        return SizedBox(
          width: 230,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => onSelected(formation),
              child: Ink(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.pulse.withValues(alpha: .14)
                      : AppColors.panel,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selected ? AppColors.pulse : AppColors.line,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            formation.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (selected)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.pulse,
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: SoccerPitch(spots: formation.spots, compact: true),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PositionStep extends StatelessWidget {
  const _PositionStep({
    required this.formation,
    required this.selectedSpot,
    required this.onSelected,
    super.key,
  });

  final SessionFormation formation;
  final FormationSpot? selectedSpot;
  final ValueChanged<FormationSpot> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
      child: Column(
        children: [
          Expanded(
            child: SoccerPitch(
              spots: formation.spots,
              selectedSpotId: selectedSpot?.id,
              onSpotSelected: onSelected,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 24,
            child: Text(
              selectedSpot?.label ?? 'Choose a player marker',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selectedSpot == null ? AppColors.muted : AppColors.pulse,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SoccerPitch extends StatelessWidget {
  const SoccerPitch({
    required this.spots,
    this.selectedSpotId,
    this.onSpotSelected,
    this.compact = false,
    super.key,
  });

  final List<FormationSpot> spots;
  final String? selectedSpotId;
  final ValueChanged<FormationSpot>? onSpotSelected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AspectRatio(
        aspectRatio: .67,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final markerSize = compact ? 20.0 : 36.0;
              return Stack(
                children: [
                  const Positioned.fill(
                    child: CustomPaint(painter: _SoccerPitchPainter()),
                  ),
                  for (final spot in spots)
                    Positioned(
                      left: constraints.maxWidth * spot.x - markerSize / 2,
                      top: constraints.maxHeight * spot.y - markerSize / 2,
                      width: markerSize,
                      height: markerSize,
                      child: _PlayerMarker(
                        spot: spot,
                        selected: spot.id == selectedSpotId,
                        compact: compact,
                        onTap: onSpotSelected == null
                            ? null
                            : () => onSpotSelected!(spot),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PlayerMarker extends StatelessWidget {
  const _PlayerMarker({
    required this.spot,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final FormationSpot spot;
  final bool selected;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final marker = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppColors.gold : AppColors.text,
        border: Border.all(
          color: selected ? AppColors.ink : AppColors.pulse,
          width: selected ? 3 : 2,
        ),
        boxShadow: selected
            ? const [BoxShadow(color: AppColors.ink, blurRadius: 8)]
            : const [],
      ),
      alignment: Alignment.center,
      child: compact
          ? null
          : Text(
              spot.abbreviation,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
    );

    if (onTap == null) {
      return marker;
    }
    return Semantics(
      key: ValueKey('formation-spot-${spot.id}'),
      button: true,
      selected: selected,
      label: spot.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: marker,
        ),
      ),
    );
  }
}

class _SoccerPitchPainter extends CustomPainter {
  const _SoccerPitchPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final field = Offset.zero & size;
    final stripePaint = Paint()..color = const Color(0xff245f39);
    final alternatePaint = Paint()..color = const Color(0xff2a6b40);
    const stripeCount = 8;
    final stripeHeight = size.height / stripeCount;
    for (var index = 0; index < stripeCount; index++) {
      canvas.drawRect(
        Rect.fromLTWH(0, index * stripeHeight, size.width, stripeHeight),
        index.isEven ? stripePaint : alternatePaint,
      );
    }

    final linePaint = Paint()
      ..color = AppColors.text.withValues(alpha: .72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final inset = size.shortestSide * .055;
    final playable = field.deflate(inset);
    canvas.drawRect(playable, linePaint);
    canvas.drawLine(
      Offset(playable.left, playable.center.dy),
      Offset(playable.right, playable.center.dy),
      linePaint,
    );
    canvas.drawCircle(playable.center, playable.width * .14, linePaint);
    canvas.drawCircle(
      playable.center,
      2,
      Paint()..color = AppColors.text.withValues(alpha: .72),
    );

    final boxWidth = playable.width * .56;
    final boxHeight = playable.height * .14;
    final topBox = Rect.fromLTWH(
      playable.center.dx - boxWidth / 2,
      playable.top,
      boxWidth,
      boxHeight,
    );
    final bottomBox = Rect.fromLTWH(
      playable.center.dx - boxWidth / 2,
      playable.bottom - boxHeight,
      boxWidth,
      boxHeight,
    );
    canvas.drawRect(topBox, linePaint);
    canvas.drawRect(bottomBox, linePaint);

    final goalWidth = playable.width * .28;
    final goalDepth = inset * .7;
    canvas.drawRect(
      Rect.fromLTWH(
        playable.center.dx - goalWidth / 2,
        playable.top - goalDepth,
        goalWidth,
        goalDepth,
      ),
      linePaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        playable.center.dx - goalWidth / 2,
        playable.bottom,
        goalWidth,
        goalDepth,
      ),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SoccerPitchPainter oldDelegate) => false;
}

String _positionLabel(String role, int index, int count) {
  final labels = switch ((role, count)) {
    ('Defense', 1) => const ['Center back'],
    ('Defense', 2) => const ['Left back', 'Right back'],
    ('Defense', 3) => const ['Left back', 'Center back', 'Right back'],
    ('Defense', 4) => const [
      'Left back',
      'Left center back',
      'Right center back',
      'Right back',
    ],
    ('Defense', 5) => const [
      'Left wing back',
      'Left center back',
      'Center back',
      'Right center back',
      'Right wing back',
    ],
    ('Midfield', 1) => const ['Center midfield'],
    ('Midfield', 2) => const ['Left midfield', 'Right midfield'],
    ('Midfield', 3) => const [
      'Left midfield',
      'Center midfield',
      'Right midfield',
    ],
    ('Midfield', 4) => const [
      'Left midfield',
      'Left center midfield',
      'Right center midfield',
      'Right midfield',
    ],
    ('Midfield', 5) => const [
      'Left wing',
      'Left center midfield',
      'Center midfield',
      'Right center midfield',
      'Right wing',
    ],
    ('Forward', 1) => const ['Striker'],
    ('Forward', 2) => const ['Left forward', 'Right forward'],
    ('Forward', 3) => const ['Left wing', 'Striker', 'Right wing'],
    ('Forward', 4) => const [
      'Left wing',
      'Left striker',
      'Right striker',
      'Right wing',
    ],
    _ => List.generate(count, (player) => '$role ${player + 1}'),
  };
  return labels[index];
}

String _positionAbbreviation(String label) {
  return switch (label) {
    'Goalkeeper' => 'GK',
    'Center back' => 'CB',
    'Left center back' => 'LCB',
    'Right center back' => 'RCB',
    'Left back' => 'LB',
    'Right back' => 'RB',
    'Left wing back' => 'LWB',
    'Right wing back' => 'RWB',
    'Center midfield' => 'CM',
    'Left center midfield' => 'LCM',
    'Right center midfield' => 'RCM',
    'Left midfield' => 'LM',
    'Right midfield' => 'RM',
    'Left wing' => 'LW',
    'Right wing' => 'RW',
    'Striker' => 'ST',
    'Left striker' => 'LS',
    'Right striker' => 'RS',
    'Left forward' => 'LF',
    'Right forward' => 'RF',
    _ =>
      label
          .split(' ')
          .where((part) => part.isNotEmpty)
          .take(3)
          .map((part) => part[0].toUpperCase())
          .join(),
  };
}
