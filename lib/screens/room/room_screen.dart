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
            Tooltip(
              message: 'Copy invite code',
              triggerMode: TooltipTriggerMode.longPress,
              preferBelow: true,
              child: IconButton(
                icon: const Icon(Icons.person_add_outlined),
                tooltip: 'Copy invite code',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: room.inviteCode));
                  ScaffoldMessenger.of(context)
                    ..clearSnackBars()
                    ..showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle,
                                color: AppColors.primary, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              'Invite code copied: ${room.inviteCode}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: const Color(0xFF1E1E1E),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                              color: AppColors.primary.withAlpha(120)),
                        ),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                },
              ),
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

class _PulsingPlayButton extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onTap;

  const _PulsingPlayButton({required this.isPlaying, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: ElevatedButton.icon(
          key: ValueKey(isPlaying),
          icon: Icon(isPlaying ? Icons.skip_next : Icons.play_arrow),
          label: Text(
            isPlaying ? 'Skip to Next Song' : 'Play Top Voted Song',
          ),
          onPressed: onTap,
        ),
      ),
    );
  }
}
