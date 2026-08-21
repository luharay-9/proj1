import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/demo_data.dart';
import '../data/firebase_data_repository.dart';
import '../theme/app_colors.dart';

class DemoModeScreen extends StatefulWidget {
  const DemoModeScreen({required this.repository, super.key});

  final FirebaseDataRepository repository;

  @override
  State<DemoModeScreen> createState() => _DemoModeScreenState();
}

class _DemoModeScreenState extends State<DemoModeScreen> {
  final _selectedSections = DemoDataSection.values.toSet();

  bool _isLoading = true;
  bool _isWorking = false;
  bool _isEnabled = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  @override
  Widget build(BuildContext context) {
    if (kReleaseMode) {
      return const Scaffold(
        body: Center(child: Text('Demo Mode is unavailable.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Demo Mode')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.gold.withValues(alpha: .55)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.science_rounded, color: AppColors.gold),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Debug data',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),
                          if (!_isLoading) _DemoStatusPill(enabled: _isEnabled),
                        ],
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Example records are written to this signed-in Firebase account. Removing Demo Mode restores replaced profile values and keeps real records.',
                        style: TextStyle(
                          color: AppColors.softText,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Demo Areas',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          _DemoSectionTile(
            icon: Icons.home_rounded,
            title: 'Home & Profile',
            detail: 'Readiness, metrics, tips, and achievements',
            selected: _selectedSections.contains(DemoDataSection.home),
            onChanged: (selected) =>
                _setSelected(DemoDataSection.home, selected),
          ),
          const SizedBox(height: 10),
          _DemoSectionTile(
            icon: Icons.insert_chart_rounded,
            title: 'Statistics & Timeline',
            detail: 'Trends, sprint zones, matches, and session events',
            selected: _selectedSections.contains(DemoDataSection.statistics),
            onChanged: (selected) =>
                _setSelected(DemoDataSection.statistics, selected),
          ),
          const SizedBox(height: 10),
          _DemoSectionTile(
            icon: Icons.accessibility_new_rounded,
            title: 'Care & Body Maps',
            detail: 'Front and back load areas at several risk levels',
            selected: _selectedSections.contains(DemoDataSection.care),
            onChanged: (selected) =>
                _setSelected(DemoDataSection.care, selected),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 14),
            Text(
              _errorMessage!,
              style: const TextStyle(
                color: AppColors.red,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: _isLoading || _isWorking || _selectedSections.isEmpty
                ? null
                : _loadDemoData,
            icon: _isWorking
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.ink,
                    ),
                  )
                : const Icon(Icons.cloud_upload_rounded),
            label: Text(
              _isWorking
                  ? 'Updating...'
                  : _isEnabled
                  ? 'Update Demo Data'
                  : 'Load Demo Data',
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.pulse,
              foregroundColor: AppColors.ink,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          if (_isEnabled) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _isWorking ? null : _removeDemoData,
              icon: const Icon(Icons.delete_sweep_rounded),
              label: const Text('Remove Demo Data'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.red,
                side: const BorderSide(color: AppColors.red),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _loadStatus() async {
    try {
      final enabledSections = await widget.repository.enabledDemoSections();
      if (mounted) {
        setState(() {
          _isEnabled = enabledSections.isNotEmpty;
          if (_isEnabled) {
            _selectedSections
              ..clear()
              ..addAll(enabledSections);
          }
          _isLoading = false;
        });
      }
    } on FirebaseException catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = _firebaseMessage(
            error,
            fallback: 'Unable to check Demo Mode status.',
          );
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Unable to check Demo Mode status: $error';
        });
      }
    }
  }

  void _setSelected(DemoDataSection section, bool selected) {
    setState(() {
      if (selected) {
        _selectedSections.add(section);
      } else {
        _selectedSections.remove(section);
      }
      _errorMessage = null;
    });
  }

  Future<void> _loadDemoData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.panel,
        title: const Text('Load demo data?'),
        content: const Text(
          'Demo matches and sessions will appear alongside real records. Temporary dashboard values can be restored with Remove Demo Data.',
          style: TextStyle(color: AppColors.softText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Load'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isWorking = true;
      _errorMessage = null;
    });
    try {
      await widget.repository.enableDemoMode(Set.of(_selectedSections));
      if (mounted) {
        setState(() {
          _isWorking = false;
          _isEnabled = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Demo data is ready to view.')),
        );
      }
    } on FirebaseException catch (error) {
      if (mounted) {
        setState(() {
          _isWorking = false;
          _errorMessage = _firebaseMessage(
            error,
            fallback: 'Unable to load demo data into Firebase.',
          );
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isWorking = false;
          _errorMessage = 'Unable to load demo data: $error';
        });
      }
    }
  }

  Future<void> _removeDemoData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.panel,
        title: const Text('Remove demo data?'),
        content: const Text(
          'Reserved demo records will be deleted and the previous profile values will be restored.',
          style: TextStyle(color: AppColors.softText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: AppColors.ink,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isWorking = true;
      _errorMessage = null;
    });
    try {
      await widget.repository.disableDemoMode();
      if (mounted) {
        setState(() {
          _isWorking = false;
          _isEnabled = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Demo data removed.')));
      }
    } on FirebaseException catch (error) {
      if (mounted) {
        setState(() {
          _isWorking = false;
          _errorMessage = _firebaseMessage(
            error,
            fallback: 'Unable to remove demo data from Firebase.',
          );
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isWorking = false;
          _errorMessage = 'Unable to remove demo data: $error';
        });
      }
    }
  }

  String _firebaseMessage(FirebaseException error, {required String fallback}) {
    final detail = error.message?.trim();
    return detail == null || detail.isEmpty
        ? '$fallback (${error.code})'
        : '$fallback ${error.code}: $detail';
  }
}

class _DemoSectionTile extends StatelessWidget {
  const _DemoSectionTile({
    required this.icon,
    required this.title,
    required this.detail,
    required this.selected,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String detail;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.pulse.withValues(alpha: .12)
          : AppColors.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: selected ? AppColors.pulse : AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: CheckboxListTile(
        value: selected,
        onChanged: (value) => onChanged(value ?? false),
        controlAffinity: ListTileControlAffinity.trailing,
        activeColor: AppColors.pulse,
        checkColor: AppColors.ink,
        secondary: Icon(icon, color: AppColors.cyan),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(
          detail,
          style: const TextStyle(
            color: AppColors.muted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _DemoStatusPill extends StatelessWidget {
  const _DemoStatusPill({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: (enabled ? AppColors.pulse : AppColors.muted).withValues(
          alpha: .16,
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        enabled ? 'ACTIVE' : 'OFF',
        style: TextStyle(
          color: enabled ? AppColors.pulse : AppColors.muted,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
