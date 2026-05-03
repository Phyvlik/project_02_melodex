import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/room_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/room_provider.dart';
import '../../providers/playlist_provider.dart';
import '../../utils/app_theme.dart';
import '../playlist/playlist_screen.dart';
import '../chat/chat_screen.dart';
import '../recommendation/recommendation_screen.dart';

class RoomScreen extends StatefulWidget {
  final RoomModel room;

  const RoomScreen({super.key, required this.room});

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    final uid = user?.uid ?? '';
    final isHost = widget.room.hostUid == uid;
    context.read<PlaylistProvider>().attachRoom(
      widget.room.id, uid,
      isHost: isHost,
      userName: user?.displayName ?? '',
    );
    final roomProvider = context.read<RoomProvider>();
    if (roomProvider.currentRoom == null) {
      roomProvider.setCurrentRoom(widget.room);
    }
  }

  Future<bool> _onWillPop() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Leave Room?'),
        content: const Text('You will leave the room and return to home.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Leave',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

if (confirmed == true && mounted) {
  Navigator.pop(context);
}
return false;
  }

  @override
  Widget build(BuildContext context) {
    final room = context.watch<RoomProvider>().currentRoom ?? widget.room;
    final uid = context.read<AuthProvider>().user?.uid ?? '';
    final isHost = room.hostUid == uid;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) await _onWillPop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(room.name),
              Text(
                '${room.memberCount} listening - ${room.currentMood}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.onSurface),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: room.inviteCode));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Invite code "${room.inviteCode}" copied to clipboard'),
                    backgroundColor: AppColors.surface,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              tooltip: 'Share invite code',
            ),
            if (isHost)
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'close') {
                    final user = context.read<AuthProvider>().user!;
                    final rp = context.read<RoomProvider>();
                    await rp.leaveRoom(user);
                    if (mounted) Navigator.pop(context);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'close',
                    child: Text('Close Room'),
                  ),
                ],
              ),
          ],
        ),
        body: Column(
          children: [
            if (isHost)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: _PulsingPlayButton(
                  isPlaying: context
                          .watch<PlaylistProvider>()
                          .currentlyPlayingId !=
                      null,
                  onTap: () =>
                      context.read<PlaylistProvider>().playTopSong(),
                ),
              ),
            Expanded(
      child: IndexedStack(
        index: _tabIndex,
        children: const [
          PlaylistScreen(),
          ChatScreen(),
          RecommendationScreen(),
        ],
      ),
    ),
  ],
),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _tabIndex,
          onTap: (i) => setState(() => _tabIndex = i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.queue_music),
              label: 'Queue',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_awesome_outlined),
              label: 'Up Next',
            ),
          ],
        ),
      ),
    );
  }
}

class _PulsingPlayButton extends StatefulWidget {
  final bool isPlaying;
  final VoidCallback onTap;

  const _PulsingPlayButton({required this.isPlaying, required this.onTap});

  @override
  State<_PulsingPlayButton> createState() => _PulsingPlayButtonState();
}

class _PulsingPlayButtonState extends State<_PulsingPlayButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _pulse = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    if (widget.isPlaying) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_PulsingPlayButton old) {
    super.didUpdateWidget(old);
    if (widget.isPlaying && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.isPlaying && _ctrl.isAnimating) {
      _ctrl.stop();
      _ctrl.reset();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _pulse,
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: Icon(widget.isPlaying ? Icons.skip_next : Icons.play_arrow),
          label: Text(
            widget.isPlaying ? 'Skip to Next Song' : 'Play Top Voted Song',
          ),
          onPressed: widget.onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.isPlaying
                ? AppColors.primary.withAlpha(220)
                : AppColors.primary,
          ),
        ),
      ),
    );
  }
}
