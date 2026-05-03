import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/playlist_provider.dart';
import '../../providers/room_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/song_card.dart';
import '../../widgets/shimmer_loader.dart';
import '../search/song_search_screen.dart';
import 'mood_tag_sheet.dart';

class PlaylistScreen extends StatefulWidget {
  const PlaylistScreen({super.key});

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  @override
  void initState() {
    super.initState();
    final room = context.read<RoomProvider>().currentRoom;
    final user = context.read<AuthProvider>().user;
    final uid = user?.uid ?? '';
    if (room != null) {
      final isHost = room.hostUid == uid;
      context.read<PlaylistProvider>().attachRoom(
        room.id, uid,
        isHost: isHost,
        userName: user?.displayName ?? '',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final playlist = context.watch<PlaylistProvider>();
    final room = context.watch<RoomProvider>().currentRoom;
    final uid = context.read<AuthProvider>().user?.uid ?? '';

    return Scaffold(
      body: playlist.isLoading
          ? const PlaylistShimmer()
          : playlist.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.queue_music_outlined,
                        size: 72,
                        color: AppColors.onSurface.withAlpha(80),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Queue is empty',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap + to search and add songs',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: playlist.songs.length,
                  separatorBuilder: (context, i) => const SizedBox(height: 6),
                  itemBuilder: (context, i) {
                    final song = playlist.songs[i];
                    return SongCard(
                      song: song,
                      isHost: room?.hostUid == uid,
                      onTagTap: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: AppColors.surface,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                        ),
                        builder: (_) => MoodTagSheet(song: song),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SongSearchScreen()),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black,
        child: const Icon(Icons.add),
      ),
    );
  }
}
