import 'package:flutter/material.dart';

import '../data/firebase_data_repository.dart';
import '../theme/app_colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _repository = FirebaseDataRepository();
  final _answers = <String, String>{};
  final _textController = TextEditingController();

  int _index = 0;
  bool _isSaving = false;
  String? _errorMessage;

  final _steps = const [
    _OnboardingStep.welcome(),
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
    _OnboardingStep.input(
      keyName: 'height',
      title: 'Height',
      detail: 'Enter your height so ShinGuard can tune motion thresholds.',
      hint: 'Example: 5 ft 7 in',
    ),
    _OnboardingStep.input(
      keyName: 'weight',
      title: 'Weight',
      detail: 'Enter your weight for load and impact calculations.',
      hint: 'Example: 120 lb',
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
  void dispose() {
    _textController.dispose();
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
                    onOptionSelected: (value) {
                      setState(() {
                        _answers[step.keyName] = value;
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
    if (currentStep.kind == _OnboardingStepKind.input) {
      _answers[currentStep.keyName] = _textController.text.trim();
    }
    final previousStep = _steps[_index - 1];
    _textController.text = _answers[previousStep.keyName] ?? '';
    setState(() {
      _index -= 1;
      _errorMessage = null;
    });
  }

  Future<void> _next() async {
    final step = _steps[_index];
    if (step.kind == _OnboardingStepKind.input) {
      final value = _textController.text.trim();
      if (value.isEmpty) {
        setState(() => _errorMessage = 'Enter an answer to continue.');
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
      _textController.text = _answers[nextStep.keyName] ?? '';
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
    try {
      await _repository.saveOnboardingAnswers(_answers);
    } catch (_) {
      setState(() => _errorMessage = 'Unable to save onboarding answers.');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

class _StepBody extends StatelessWidget {
  const _StepBody({
    required this.step,
    required this.selectedValue,
    required this.textController,
    required this.onOptionSelected,
    super.key,
  });

  final _OnboardingStep step;
  final String? selectedValue;
  final TextEditingController textController;
  final ValueChanged<String> onOptionSelected;

  @override
  Widget build(BuildContext context) {
    if (step.kind == _OnboardingStepKind.welcome) {
      return const _WelcomeStep();
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
                selected: selectedValue == option,
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

enum _OnboardingStepKind { welcome, options, input }

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

  final _OnboardingStepKind kind;
  final String keyName;
  final String title;
  final String detail;
  final String hint;
  final List<String> options;
}
