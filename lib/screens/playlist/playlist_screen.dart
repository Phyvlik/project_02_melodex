import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/song_model.dart';
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
    final nowPlaying = playlist.currentlyPlayingSong;

    return Scaffold(
      body: playlist.isLoading
          ? const PlaylistShimmer()
          : Column(
              children: [
                if (nowPlaying != null)
                  _NowPlayingCard(song: nowPlaying),
                Expanded(
                  child: playlist.isEmpty
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
                          separatorBuilder: (context, i) =>
                              const SizedBox(height: 6),
                          itemBuilder: (context, i) {
                            final song = playlist.songs[i];
                            return TweenAnimationBuilder<double>(
                              key: ValueKey(song.id),
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration:
                                  Duration(milliseconds: 250 + i * 40),
                              curve: Curves.easeOut,
                              builder: (context, value, child) => Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(0, 16 * (1 - value)),
                                  child: child,
                                ),
                              ),
                              child: SongCard(
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
                              ),
                            );
                          },
                        ),
                ),
              ],
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

class _NowPlayingCard extends StatefulWidget {
  final SongModel song;
  const _NowPlayingCard({required this.song});

  @override
  State<_NowPlayingCard> createState() => _NowPlayingCardState();
}

class _NowPlayingCardState extends State<_NowPlayingCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(25),
        border: Border.all(color: AppColors.primary.withAlpha(100)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.network(
              widget.song.albumArtUrl,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 44,
                height: 44,
                color: AppColors.surface,
                child: const Icon(Icons.music_note,
                    color: AppColors.primary, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NOW PLAYING',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.song.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  widget.song.artist,
                  style: TextStyle(
                    color: AppColors.onSurface.withAlpha(160),
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _EqualizerBars(controller: _controller),
        ],
      ),
    );
  }
}

class _EqualizerBars extends StatelessWidget {
  final AnimationController controller;
  const _EqualizerBars({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _bar(height: 8 + 8 * ((t * 1.3) % 1.0)),
            const SizedBox(width: 2),
            _bar(height: 8 + 8 * ((t * 0.7 + 0.3) % 1.0)),
            const SizedBox(width: 2),
            _bar(height: 8 + 8 * ((t * 1.1 + 0.6) % 1.0)),
          ],
        );
      },
    );
  }

  Widget _bar({required double height}) => Container(
        width: 3,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(2),
        ),
      );
}
