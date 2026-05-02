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
    final uid = context.read<AuthProvider>().user?.uid ?? '';
    context.read<PlaylistProvider>().attachRoom(widget.room.id, uid);
    final roomProvider = context.read<RoomProvider>();
    if (roomProvider.currentRoom == null) {
      roomProvider.setCurrentRoom(widget.room);
    }
  }

  Future<bool> _onWillPop() async {
    final auth = context.read<AuthProvider>();
    final roomProvider = context.read<RoomProvider>();
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

    if (confirmed == true) {
      final user = auth.user!;
      if (mounted) await roomProvider.leaveRoom(user);
    }
    return confirmed ?? false;
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
        body: IndexedStack(
          index: _tabIndex,
          children: const [
            PlaylistScreen(),
            ChatScreen(),
            RecommendationScreen(),
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
