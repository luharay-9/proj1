import 'package:flutter/material.dart';

import '../data/firebase_data_repository.dart';
import '../models/app_data.dart';
import '../models/contact.dart';
import '../shared/shared_widgets.dart';
import '../theme/app_colors.dart';

class ContactsScreen extends StatelessWidget {
  ContactsScreen({FirebaseDataRepository? repository, super.key})
    : repository = repository ?? FirebaseDataRepository();

  final FirebaseDataRepository repository;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Contacts'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.people_rounded), text: 'Friends'),
              Tab(icon: Icon(Icons.groups_rounded), text: 'Team / Coach'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _FriendsTab(repository: repository),
            const _TeamCoachTab(),
          ],
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: FilledButton.icon(
            onPressed: () => _openAddFriend(context),
            icon: const Icon(Icons.person_add_rounded),
            label: const Text('Add friend'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.pulse,
              foregroundColor: AppColors.ink,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openAddFriend(BuildContext context) async {
    final username = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => AddFriendScreen(repository: repository),
      ),
    );
    if (context.mounted && username != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Friend request sent to $username.')),
      );
    }
  }
}

class _FriendsTab extends StatelessWidget {
  const _FriendsTab({required this.repository});

  final FirebaseDataRepository repository;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ContactSummary>>(
      stream: repository.watchFriends(),
      builder: (context, friendSnapshot) {
        if (friendSnapshot.hasError) {
          return const AppMessage(
            title: 'Friends unavailable',
            detail: 'Check your Firebase permissions and try again.',
            icon: Icons.cloud_off_rounded,
          );
        }
        return StreamBuilder<List<FriendRequestData>>(
          stream: repository.watchFriendRequests(),
          builder: (context, requestSnapshot) {
            if (requestSnapshot.hasError) {
              return const AppMessage(
                title: 'Requests unavailable',
                detail: 'Check your Firebase permissions and try again.',
                icon: Icons.cloud_off_rounded,
              );
            }
            if ((!friendSnapshot.hasData || !requestSnapshot.hasData) &&
                (friendSnapshot.connectionState == ConnectionState.waiting ||
                    requestSnapshot.connectionState ==
                        ConnectionState.waiting)) {
              return const AppLoading();
            }

            final friends = friendSnapshot.data ?? const <ContactSummary>[];
            final requests =
                requestSnapshot.data ?? const <FriendRequestData>[];
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
              children: [
                const SectionTitle('Friends'),
                const SizedBox(height: 10),
                if (friends.isEmpty)
                  const SizedBox(
                    height: 110,
                    child: EmptyDataPanel(
                      title: 'No friends added yet',
                      detail: 'Add someone using their ShinGuard username.',
                      icon: Icons.people_outline_rounded,
                    ),
                  )
                else
                  ...friends.map(
                    (friend) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _FriendTile(
                        friend: friend,
                        repository: repository,
                      ),
                    ),
                  ),
                const SectionHeader(title: 'Friend Requests'),
                if (requests.isEmpty)
                  const SizedBox(
                    height: 96,
                    child: EmptyDataPanel(
                      title: 'No pending requests',
                      icon: Icons.mark_email_read_rounded,
                    ),
                  )
                else
                  ...requests.map(
                    (request) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _RequestTile(
                        request: request,
                        repository: repository,
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class _FriendTile extends StatelessWidget {
  const _FriendTile({required this.friend, required this.repository});

  final ContactSummary friend;
  final FirebaseDataRepository repository;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _showActions(context),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: panelDecoration(),
          child: Row(
            children: [
              PulseAvatar(avatar: friend.avatar, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      friend.displayName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (friend.profileSubtitle.isNotEmpty)
                      Text(
                        friend.profileSubtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.more_horiz_rounded, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showActions(BuildContext context) async {
    final action = await showModalBottomSheet<_FriendAction>(
      context: context,
      backgroundColor: AppColors.panel,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_rounded, color: AppColors.pulse),
              title: const Text('View profile'),
              onTap: () => Navigator.of(context).pop(_FriendAction.profile),
            ),
            ListTile(
              leading: const Icon(
                Icons.person_remove_rounded,
                color: AppColors.red,
              ),
              title: const Text('Remove friend'),
              onTap: () => Navigator.of(context).pop(_FriendAction.remove),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    if (action == _FriendAction.profile) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => FriendProfileScreen(
            friendUid: friend.uid,
            repository: repository,
          ),
        ),
      );
    } else if (action == _FriendAction.remove) {
      await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) =>
              RemoveFriendScreen(friend: friend, repository: repository),
        ),
      );
    }
  }
}

enum _FriendAction { profile, remove }

class _RequestTile extends StatefulWidget {
  const _RequestTile({required this.request, required this.repository});

  final FriendRequestData request;
  final FirebaseDataRepository repository;

  @override
  State<_RequestTile> createState() => _RequestTileState();
}

class _RequestTileState extends State<_RequestTile> {
  bool _isWorking = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: panelDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              PulseAvatar(avatar: widget.request.avatar, size: 46),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.request.fromUsername,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isWorking ? null : _ignore,
                  child: const Text('Ignore'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: _isWorking ? null : _accept,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.pulse,
                    foregroundColor: AppColors.ink,
                  ),
                  child: Text(_isWorking ? 'Working...' : 'Accept'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _accept() async {
    await _run(() => widget.repository.acceptFriendRequest(widget.request));
  }

  Future<void> _ignore() async {
    await _run(
      () => widget.repository.ignoreFriendRequest(widget.request.fromUid),
    );
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _isWorking = true);
    try {
      await action();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_contactError(error))));
        setState(() => _isWorking = false);
      }
    }
  }
}

class _TeamCoachTab extends StatelessWidget {
  const _TeamCoachTab();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(20),
      child: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          height: 120,
          child: EmptyDataPanel(
            title: 'No team or coach contacts yet',
            detail: 'Team and coach connections will appear here.',
            icon: Icons.groups_rounded,
          ),
        ),
      ),
    );
  }
}

class AddFriendScreen extends StatefulWidget {
  const AddFriendScreen({required this.repository, super.key});

  final FirebaseDataRepository repository;

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> {
  final _usernameController = TextEditingController();
  bool _isSending = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Friend')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Find by username',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter the exact ShinGuard username of the person you want to add.',
                style: TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _usernameController,
                autofocus: true,
                autocorrect: false,
                textCapitalization: TextCapitalization.none,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: const InputDecoration(
                  labelText: 'Username',
                  prefixIcon: Icon(Icons.alternate_email_rounded),
                  filled: true,
                  fillColor: AppColors.panel,
                  border: OutlineInputBorder(),
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
              const Spacer(),
              FilledButton.icon(
                onPressed: _isSending ? null : _send,
                icon: const Icon(Icons.send_rounded),
                label: Text(_isSending ? 'Sending...' : 'Send friend request'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.pulse,
                  foregroundColor: AppColors.ink,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _send() async {
    if (_isSending) return;
    final username = _usernameController.text.trim();
    setState(() {
      _isSending = true;
      _errorMessage = null;
    });
    try {
      await widget.repository.sendFriendRequest(username);
      if (mounted) Navigator.of(context).pop(username);
    } catch (error) {
      if (mounted) {
        setState(() {
          _isSending = false;
          _errorMessage = _contactError(error);
        });
      }
    }
  }
}

class FriendProfileScreen extends StatelessWidget {
  const FriendProfileScreen({
    required this.friendUid,
    required this.repository,
    super.key,
  });

  final String friendUid;
  final FirebaseDataRepository repository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Friend Profile')),
      body: FutureBuilder<FriendProfileData>(
        future: repository.getFriendProfile(friendUid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoading();
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return AppMessage(
              title: 'Profile unavailable',
              detail: snapshot.hasError ? _contactError(snapshot.error!) : null,
              icon: Icons.person_off_rounded,
            );
          }
          return _FriendProfileBody(data: snapshot.data!.data);
        },
      ),
    );
  }
}

class _FriendProfileBody extends StatelessWidget {
  const _FriendProfileBody({required this.data});

  final UserAppData data;

  @override
  Widget build(BuildContext context) {
    final details = [
      ('Position', data.athleteProfile.position),
      ('Dominant foot', data.athleteProfile.dominantFoot),
      ('Club', data.athleteProfile.club),
      ('Age group', data.athleteProfile.ageGroup),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 36),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: panelDecoration(),
          child: Column(
            children: [
              PulseAvatar(avatar: data.avatar, size: 76),
              const SizedBox(height: 12),
              Text(
                data.displayName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (data.profileSubtitle.isNotEmpty)
                Text(
                  data.profileSubtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
        const SectionHeader(title: 'Statistics'),
        Row(
          children: [
            Expanded(
              child: _OverviewStat(value: data.matches, label: 'MATCHES'),
            ),
            Expanded(
              child: _OverviewStat(value: data.goals, label: 'GOALS'),
            ),
            Expanded(
              child: _OverviewStat(value: data.avgScore, label: 'AVG SCORE'),
            ),
          ],
        ),
        const SectionHeader(title: 'Athlete Overview'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: panelDecoration(),
          child: Column(
            children: details
                .map(
                  (detail) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            detail.$1,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          detail.$2.isEmpty ? 'Not set' : detail.$2,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _OverviewStat extends StatelessWidget {
  const _OverviewStat({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$value',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.softText,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class RemoveFriendScreen extends StatefulWidget {
  const RemoveFriendScreen({
    required this.friend,
    required this.repository,
    super.key,
  });

  final ContactSummary friend;
  final FirebaseDataRepository repository;

  @override
  State<RemoveFriendScreen> createState() => _RemoveFriendScreenState();
}

class _RemoveFriendScreenState extends State<RemoveFriendScreen> {
  bool _isRemoving = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Remove Friend')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              PulseAvatar(avatar: widget.friend.avatar, size: 82),
              const SizedBox(height: 22),
              Text(
                'Remove ${widget.friend.displayName}?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Are you sure? You will be removed from each other\'s friends lists.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 14),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.red,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
              const Spacer(),
              OutlinedButton(
                onPressed: _isRemoving
                    ? null
                    : () => Navigator.of(context).pop(false),
                child: const Text('No, keep friend'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _isRemoving ? null : _remove,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.red,
                  foregroundColor: AppColors.ink,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(_isRemoving ? 'Removing...' : 'Yes, remove friend'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _remove() async {
    setState(() {
      _isRemoving = true;
      _errorMessage = null;
    });
    try {
      await widget.repository.removeFriend(widget.friend.uid);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _isRemoving = false;
          _errorMessage = _contactError(error);
        });
      }
    }
  }
}

String _contactError(Object error) {
  if (error is ContactException) return error.message;
  return 'Something went wrong. Please try again.';
}
