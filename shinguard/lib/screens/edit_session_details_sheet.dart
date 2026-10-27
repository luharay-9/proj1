import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class SessionMetadataUpdate {
  const SessionMetadataUpdate({required this.title, required this.position});

  final String title;
  final String position;
}

class EditSessionDetailsSheet extends StatefulWidget {
  const EditSessionDetailsSheet({
    required this.initialTitle,
    required this.initialPosition,
    required this.onSave,
    super.key,
  });

  final String initialTitle;
  final String initialPosition;
  final Future<void> Function(String title, String position) onSave;

  @override
  State<EditSessionDetailsSheet> createState() =>
      _EditSessionDetailsSheetState();
}

class _EditSessionDetailsSheetState extends State<EditSessionDetailsSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _positionController;
  bool _saving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _positionController = TextEditingController(text: widget.initialPosition);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _positionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Edit session details',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Rename the session or correct the played position.',
                  style: TextStyle(
                    color: AppColors.softText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _titleController,
                  autofocus: true,
                  maxLength: 80,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Session name',
                    prefixIcon: Icon(Icons.edit_rounded),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a session name.'
                      : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _positionController,
                  maxLength: 60,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Position played',
                    prefixIcon: Icon(Icons.sports_soccer_rounded),
                  ),
                  onFieldSubmitted: (_) => _save(),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cyan.withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.cyan.withValues(alpha: .25),
                    ),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lock_rounded, size: 18, color: AppColors.cyan),
                      SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          'Recorded stats are locked and cannot be changed.',
                          style: TextStyle(
                            color: AppColors.softText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: AppColors.red,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.pulse,
                    foregroundColor: AppColors.ink,
                  ),
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(_saving ? 'Saving...' : 'Save details'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;
    final title = _titleController.text.trim();
    final position = _positionController.text.trim();
    setState(() {
      _saving = true;
      _errorMessage = null;
    });
    try {
      await widget.onSave(title, position);
      if (mounted) {
        Navigator.of(
          context,
        ).pop(SessionMetadataUpdate(title: title, position: position));
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _errorMessage = 'Unable to save session details. Please try again.';
        });
      }
    }
  }
}
