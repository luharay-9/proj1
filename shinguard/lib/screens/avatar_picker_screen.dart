import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/firebase_data_repository.dart';
import '../models/app_data.dart';
import '../shared/shared_widgets.dart';
import '../theme/app_colors.dart';

const _avatarIcons = [
  ('soccer', Icons.sports_soccer_rounded, 'Soccer ball'),
  ('thumb_up', Icons.thumb_up_rounded, 'Thumbs up'),
  ('bolt', Icons.bolt_rounded, 'Bolt'),
  ('shield', Icons.shield_rounded, 'Shield'),
  ('star', Icons.star_rounded, 'Star'),
  ('person', Icons.person_rounded, 'Person'),
];

class AvatarPickerScreen extends StatefulWidget {
  const AvatarPickerScreen({required this.currentAvatar, super.key});

  final AvatarData currentAvatar;

  @override
  State<AvatarPickerScreen> createState() => _AvatarPickerScreenState();
}

class _AvatarPickerScreenState extends State<AvatarPickerScreen> {
  final _picker = ImagePicker();
  final _repository = FirebaseDataRepository();

  Uint8List? _pendingPhoto;
  String? _pendingContentType;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final hasPendingPhoto = _pendingPhoto != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile Photo')),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            Center(
              child: _AvatarPreview(
                currentAvatar: widget.currentAvatar,
                pendingPhoto: _pendingPhoto,
              ),
            ),
            const SizedBox(height: 28),
            _AvatarActionButton(
              icon: Icons.camera_alt_rounded,
              label: 'Take a photo',
              onPressed: _isSaving
                  ? null
                  : () => _pickPhoto(ImageSource.camera),
            ),
            const SizedBox(height: 12),
            _AvatarActionButton(
              icon: Icons.photo_library_rounded,
              label: 'Choose from photo library',
              onPressed: _isSaving
                  ? null
                  : () => _pickPhoto(ImageSource.gallery),
            ),
            const SizedBox(height: 12),
            _AvatarActionButton(
              icon: Icons.grid_view_rounded,
              label: 'Choose a built-in icon',
              onPressed: _isSaving ? null : _openIconLibrary,
            ),
            if (hasPendingPhoto) ...[
              const SizedBox(height: 18),
              const Text(
                'Photo selected',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.pulse,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 18),
              Text(
                _errorMessage!,
                style: const TextStyle(
                  color: AppColors.red,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 18),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSaving || !hasPendingPhoto ? null : _resetPhoto,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _isSaving || !hasPendingPhoto ? null : _savePhoto,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.pulse,
                    foregroundColor: AppColors.ink,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSaving
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.ink,
                          ),
                        )
                      : const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final image = await _picker.pickImage(
        source: source,
        imageQuality: 82,
        maxWidth: 1200,
        requestFullMetadata: false,
      );
      if (image == null) {
        return;
      }

      final bytes = await image.readAsBytes();
      if (!mounted) {
        return;
      }
      setState(() {
        _pendingPhoto = bytes;
        _pendingContentType = image.mimeType ?? _contentTypeForPath(image.path);
        _errorMessage = null;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'Unable to load that profile photo.');
      }
    }
  }

  void _resetPhoto() {
    setState(() {
      _pendingPhoto = null;
      _pendingContentType = null;
      _errorMessage = null;
    });
  }

  Future<void> _savePhoto() async {
    final photo = _pendingPhoto;
    final contentType = _pendingContentType;
    if (photo == null || contentType == null) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      await _repository.uploadProfilePhoto(photo, contentType: contentType);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'Unable to save that profile photo.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _openIconLibrary() async {
    final iconKey = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) =>
            BuiltInIconPickerScreen(currentAvatar: widget.currentAvatar),
      ),
    );
    if (iconKey == null || !mounted) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      await _repository.saveAvatarIcon(iconKey);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'Unable to save that icon.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _contentTypeForPath(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.heic') || lower.endsWith('.heif')) {
      return 'image/heic';
    }
    return 'image/jpeg';
  }
}

class BuiltInIconPickerScreen extends StatefulWidget {
  const BuiltInIconPickerScreen({required this.currentAvatar, super.key});

  final AvatarData currentAvatar;

  @override
  State<BuiltInIconPickerScreen> createState() =>
      _BuiltInIconPickerScreenState();
}

class _BuiltInIconPickerScreenState extends State<BuiltInIconPickerScreen> {
  late final String _initialIcon;
  late String _selectedIcon;

  @override
  void initState() {
    super.initState();
    _initialIcon = widget.currentAvatar.type == 'icon'
        ? widget.currentAvatar.value
        : 'person';
    _selectedIcon = _initialIcon;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Built-in Icons')),
      body: SafeArea(
        bottom: false,
        child: GridView.builder(
          padding: const EdgeInsets.all(22),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 1,
          ),
          itemCount: _avatarIcons.length,
          itemBuilder: (context, index) {
            final option = _avatarIcons[index];
            final selected = option.$1 == _selectedIcon;
            return Semantics(
              button: true,
              selected: selected,
              label: option.$3,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => setState(() => _selectedIcon = option.$1),
                child: Ink(
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.pulse.withValues(alpha: .18)
                        : AppColors.panel,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected ? AppColors.pulse : AppColors.line,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(
                          option.$2,
                          color: AppColors.pulse,
                          size: 38,
                        ),
                      ),
                      if (selected)
                        const Positioned(
                          top: 8,
                          right: 8,
                          child: Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.pulse,
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 18),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _selectedIcon = _initialIcon),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(_selectedIcon),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.pulse,
                    foregroundColor: AppColors.ink,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarPreview extends StatelessWidget {
  const _AvatarPreview({
    required this.currentAvatar,
    required this.pendingPhoto,
  });

  final AvatarData currentAvatar;
  final Uint8List? pendingPhoto;

  @override
  Widget build(BuildContext context) {
    final photo = pendingPhoto;
    if (photo == null) {
      return PulseAvatar(avatar: currentAvatar, size: 112);
    }

    return Container(
      width: 112,
      height: 112,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.pulse, width: 2),
      ),
      child: ClipOval(child: Image.memory(photo, fit: BoxFit.cover)),
    );
  }
}

class _AvatarActionButton extends StatelessWidget {
  const _AvatarActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
        side: const BorderSide(color: AppColors.line),
        foregroundColor: AppColors.text,
      ),
    );
  }
}
