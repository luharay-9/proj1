import 'package:flutter/material.dart';

import '../data/firebase_data_repository.dart';
import '../models/measurement_system.dart';
import '../theme/app_colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    this.debugReplay = false,
    this.initialAnswers = const {},
    super.key,
  });

  final bool debugReplay;
  final Map<String, String> initialAnswers;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _repository = FirebaseDataRepository();
  late final Map<String, String> _answers;
  final _textController = TextEditingController();
  final _heightFeetController = TextEditingController();
  final _heightInchesController = TextEditingController();
  final _heightCmController = TextEditingController();
  final _weightLbController = TextEditingController();
  final _weightKgController = TextEditingController();

  int _index = 0;
  bool _isSaving = false;
  String? _errorMessage;

  final _steps = const [
    _OnboardingStep.welcome(),
    _OnboardingStep.input(
      keyName: 'username',
      title: 'Choose a username',
      detail: 'This is the name shown throughout ShinGuard.',
      hint: 'Example: Leo7',
    ),
    _OnboardingStep.options(
      keyName: 'unitSystem',
      title: 'Choose your units',
      detail:
          'ShinGuard will use this for your profile, distances, and speeds.',
      options: ['Imperial', 'Metric'],
    ),
    _OnboardingStep.options(
      keyName: 'dominantFoot',
      title: 'Dominant foot',
      detail: 'Which foot do you naturally use for shooting or long passes?',
      options: ['Right', 'Left', 'Both'],
    ),
    _OnboardingStep.options(
      keyName: 'position',
      title: 'Primary position',
      detail: 'Pick the role you play most often.',
      options: ['Forward', 'Midfield', 'Defense', 'Goalkeeper'],
    ),
    _OnboardingStep.measurement(
      keyName: 'height',
      title: 'Height',
      detail: 'Enter your height so ShinGuard can tune motion thresholds.',
    ),
    _OnboardingStep.measurement(
      keyName: 'weight',
      title: 'Weight',
      detail: 'Enter your weight for load and impact calculations.',
    ),
    _OnboardingStep.input(
      keyName: 'club',
      title: 'Club',
      detail: 'Add your team or club name.',
      hint: 'Example: Eagles FC',
    ),
    _OnboardingStep.input(
      keyName: 'ageGroup',
      title: 'Age group',
      detail: 'Add your age group, school year, or competition level.',
      hint: 'Example: U14',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _answers = Map<String, String>.from(widget.initialAnswers);
    _loadSavedMeasurements();
  }

  @override
  void dispose() {
    _textController.dispose();
    _heightFeetController.dispose();
    _heightInchesController.dispose();
    _heightCmController.dispose();
    _weightLbController.dispose();
    _weightKgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_index];
    final isLast = _index == _steps.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LinearProgressIndicator(
                value: (_index + 1) / _steps.length,
                minHeight: 6,
                backgroundColor: AppColors.panel,
                valueColor: const AlwaysStoppedAnimation(AppColors.pulse),
              ),
              const SizedBox(height: 28),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: _StepBody(
                    key: ValueKey(_index),
                    step: step,
                    selectedValue: _answers[step.keyName],
                    textController: _textController,
                    measurementSystem: _measurementSystem,
                    heightFeetController: _heightFeetController,
                    heightInchesController: _heightInchesController,
                    heightCmController: _heightCmController,
                    weightLbController: _weightLbController,
                    weightKgController: _weightKgController,
                    onOptionSelected: (value) {
                      setState(() {
                        _answers[step.keyName] = step.keyName == 'unitSystem'
                            ? value.toLowerCase()
                            : value;
                        _errorMessage = null;
                      });
                    },
                  ),
                ),
              ),
              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: AppColors.red,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  if (_index > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSaving ? null : _previous,
                        child: const Text('Back'),
                      ),
                    ),
                  if (_index > 0) const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isSaving ? null : _next,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.pulse,
                        foregroundColor: AppColors.ink,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      child: _isSaving
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.ink,
                              ),
                            )
                          : Text(isLast ? 'Finish setup' : 'Next'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _previous() {
    final currentStep = _steps[_index];
    if (_usesTextController(currentStep)) {
      _answers[currentStep.keyName] = _textController.text.trim();
    }
    final previousStep = _steps[_index - 1];
    if (_usesTextController(previousStep)) {
      _textController.text = _answers[previousStep.keyName] ?? '';
    }
    setState(() {
      _index -= 1;
      _errorMessage = null;
    });
  }

  Future<void> _next() async {
    final step = _steps[_index];
    if (step.kind == _OnboardingStepKind.measurement) {
      final measurement = _measurementAnswer(step.keyName);
      if (measurement == null) return;
      _answers[step.keyName] = measurement;
    } else if (step.kind == _OnboardingStepKind.input) {
      final value = _textController.text.trim();
      if (value.isEmpty) {
        setState(() => _errorMessage = 'Enter an answer to continue.');
        return;
      }
      if (step.keyName == 'username' &&
          !RegExp(r'^[A-Za-z0-9_]{3,24}$').hasMatch(value)) {
        setState(() {
          _errorMessage =
              'Use 3-24 letters, numbers, or underscores for your username.';
        });
        return;
      }
      _answers[step.keyName] = value;
    } else if (step.kind == _OnboardingStepKind.options &&
        (_answers[step.keyName] ?? '').isEmpty) {
      setState(() => _errorMessage = 'Choose an option to continue.');
      return;
    }

    if (_index < _steps.length - 1) {
      final nextStep = _steps[_index + 1];
      if (_usesTextController(nextStep)) {
        _textController.text = _answers[nextStep.keyName] ?? '';
      }
      setState(() {
        _index += 1;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    var returningToSettings = false;
    try {
      await _repository.saveOnboardingAnswers(_answers);
      if (mounted && widget.debugReplay) {
        returningToSettings = true;
        Navigator.of(context).pop();
      }
    } catch (_) {
      setState(() => _errorMessage = 'Unable to save onboarding answers.');
    } finally {
      if (mounted && !returningToSettings) {
        setState(() => _isSaving = false);
      }
    }
  }

  bool _usesTextController(_OnboardingStep step) {
    return step.kind == _OnboardingStepKind.input;
  }

  MeasurementSystem get _measurementSystem {
    return MeasurementSystem.fromValue(_answers['unitSystem']);
  }

  String? _measurementAnswer(String keyName) {
    if (keyName == 'height') {
      if (_measurementSystem == MeasurementSystem.imperial) {
        final feet = int.tryParse(_heightFeetController.text.trim());
        final inches = int.tryParse(_heightInchesController.text.trim());
        if (feet == null || feet <= 0 || inches == null || inches < 0) {
          setState(() {
            _errorMessage = 'Enter your height in feet and inches.';
          });
          return null;
        }
        if (inches >= 12) {
          setState(() => _errorMessage = 'Inches must be between 0 and 11.');
          return null;
        }
        return '$feet ft $inches in';
      }

      final centimeters = double.tryParse(_heightCmController.text.trim());
      if (centimeters == null || centimeters <= 0) {
        setState(() => _errorMessage = 'Enter your height in centimeters.');
        return null;
      }
      return '${_formatMeasurement(centimeters)} cm';
    }

    final controller = _measurementSystem == MeasurementSystem.imperial
        ? _weightLbController
        : _weightKgController;
    final weight = double.tryParse(controller.text.trim());
    if (weight == null || weight <= 0) {
      setState(() {
        _errorMessage = _measurementSystem == MeasurementSystem.imperial
            ? 'Enter your weight in pounds.'
            : 'Enter your weight in kilograms.';
      });
      return null;
    }
    final unit = _measurementSystem == MeasurementSystem.imperial ? 'lb' : 'kg';
    return '${_formatMeasurement(weight)} $unit';
  }

  String _formatMeasurement(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }

  void _loadSavedMeasurements() {
    final height = _answers['height'] ?? '';
    final heightValues = _numbersIn(height);
    if (height.toLowerCase().contains('cm')) {
      _answers.putIfAbsent('unitSystem', () => 'metric');
      if (heightValues.isNotEmpty) {
        _heightCmController.text = _formatMeasurement(heightValues.first);
      }
    } else if (heightValues.isNotEmpty) {
      _answers.putIfAbsent('unitSystem', () => 'imperial');
      _heightFeetController.text = _formatMeasurement(heightValues.first);
      if (heightValues.length > 1) {
        _heightInchesController.text = _formatMeasurement(heightValues[1]);
      }
    }

    final weight = _answers['weight'] ?? '';
    final weightValues = _numbersIn(weight);
    if (weight.toLowerCase().contains('kg')) {
      _answers.putIfAbsent('unitSystem', () => 'metric');
      if (weightValues.isNotEmpty) {
        _weightKgController.text = _formatMeasurement(weightValues.first);
      }
    } else if (weightValues.isNotEmpty) {
      _answers.putIfAbsent('unitSystem', () => 'imperial');
      _weightLbController.text = _formatMeasurement(weightValues.first);
    }
  }

  List<double> _numbersIn(String value) {
    return RegExp(
      r'\d+(?:\.\d+)?',
    ).allMatches(value).map((match) => double.parse(match.group(0)!)).toList();
  }
}

class _StepBody extends StatelessWidget {
  const _StepBody({
    required this.step,
    required this.selectedValue,
    required this.textController,
    required this.onOptionSelected,
    required this.measurementSystem,
    required this.heightFeetController,
    required this.heightInchesController,
    required this.heightCmController,
    required this.weightLbController,
    required this.weightKgController,
    super.key,
  });

  final _OnboardingStep step;
  final String? selectedValue;
  final TextEditingController textController;
  final ValueChanged<String> onOptionSelected;
  final MeasurementSystem measurementSystem;
  final TextEditingController heightFeetController;
  final TextEditingController heightInchesController;
  final TextEditingController heightCmController;
  final TextEditingController weightLbController;
  final TextEditingController weightKgController;

  @override
  Widget build(BuildContext context) {
    if (step.kind == _OnboardingStepKind.welcome) {
      return const _WelcomeStep();
    }
    if (step.kind == _OnboardingStepKind.measurement) {
      final isHeight = step.keyName == 'height';
      return _MeasurementStep(
        key: ValueKey(step.keyName),
        title: step.title,
        detail: step.detail,
        measurementSystem: measurementSystem,
        isHeight: isHeight,
        primaryController: isHeight
            ? (measurementSystem == MeasurementSystem.imperial
                  ? heightFeetController
                  : heightCmController)
            : (measurementSystem == MeasurementSystem.imperial
                  ? weightLbController
                  : weightKgController),
        secondaryController:
            isHeight && measurementSystem == MeasurementSystem.imperial
            ? heightInchesController
            : null,
      );
    }

    return Column(
      key: ValueKey(step.keyName),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          step.title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppColors.text,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          step.detail,
          style: const TextStyle(
            color: AppColors.muted,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 28),
        if (step.kind == _OnboardingStepKind.options)
          ...step.options.map(
            (option) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _OptionButton(
                label: option,
                selected: selectedValue?.toLowerCase() == option.toLowerCase(),
                onTap: () => onOptionSelected(option),
              ),
            ),
          )
        else
          TextField(
            controller: textController,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: step.hint,
              filled: true,
              fillColor: AppColors.panel,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.line),
              ),
            ),
          ),
      ],
    );
  }
}

class _MeasurementStep extends StatelessWidget {
  const _MeasurementStep({
    required this.title,
    required this.detail,
    required this.measurementSystem,
    required this.isHeight,
    required this.primaryController,
    this.secondaryController,
    super.key,
  });

  final String title;
  final String detail;
  final MeasurementSystem measurementSystem;
  final bool isHeight;
  final TextEditingController primaryController;
  final TextEditingController? secondaryController;

  @override
  Widget build(BuildContext context) {
    final isImperial = measurementSystem == MeasurementSystem.imperial;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.text,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              detail,
              style: const TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: constraints.maxHeight * 0.08),
            Text(
              '${measurementSystem.displayName} units',
              style: const TextStyle(
                color: AppColors.pulse,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 24),
            if (isHeight && isImperial)
              Row(
                children: [
                  Expanded(
                    child: _MeasurementField(
                      controller: primaryController,
                      label: 'Feet',
                      suffix: 'ft',
                      allowDecimal: false,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MeasurementField(
                      controller: secondaryController!,
                      label: 'Inches',
                      suffix: 'in',
                      allowDecimal: false,
                    ),
                  ),
                ],
              )
            else
              _MeasurementField(
                controller: primaryController,
                label: isHeight
                    ? 'Height in centimeters'
                    : isImperial
                    ? 'Weight in pounds'
                    : 'Weight in kilograms',
                suffix: isHeight
                    ? 'cm'
                    : isImperial
                    ? 'lb'
                    : 'kg',
                allowDecimal: !isImperial || !isHeight,
              ),
          ],
        );
      },
    );
  }
}

class _MeasurementField extends StatelessWidget {
  const _MeasurementField({
    required this.controller,
    required this.label,
    required this.suffix,
    required this.allowDecimal,
  });

  final TextEditingController controller;
  final String label;
  final String suffix;
  final bool allowDecimal;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        filled: true,
        fillColor: AppColors.panel,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.shield_rounded, color: AppColors.pulse, size: 82),
        const SizedBox(height: 28),
        Text(
          'Welcome to ShinGuard',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppColors.text,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'A few athlete details help tune motion spikes, kick detection, and recovery guidance before your first device connection.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            color: selected ? AppColors.pulse : AppColors.panel,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.pulse : AppColors.line,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.ink : AppColors.text,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

enum _OnboardingStepKind { welcome, options, input, measurement }

class _OnboardingStep {
  const _OnboardingStep.welcome()
    : kind = _OnboardingStepKind.welcome,
      keyName = 'welcome',
      title = 'Welcome',
      detail = '',
      hint = '',
      options = const [];

  const _OnboardingStep.options({
    required this.keyName,
    required this.title,
    required this.detail,
    required this.options,
  }) : kind = _OnboardingStepKind.options,
       hint = '';

  const _OnboardingStep.input({
    required this.keyName,
    required this.title,
    required this.detail,
    required this.hint,
  }) : kind = _OnboardingStepKind.input,
       options = const [];

  const _OnboardingStep.measurement({
    required this.keyName,
    required this.title,
    required this.detail,
  }) : kind = _OnboardingStepKind.measurement,
       hint = '',
       options = const [];

  final _OnboardingStepKind kind;
  final String keyName;
  final String title;
  final String detail;
  final String hint;
  final List<String> options;
}
