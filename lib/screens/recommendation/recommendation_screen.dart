import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/recommendation_model.dart';
import '../../models/user_model.dart' show UserModel;
import '../../providers/auth_provider.dart';
import '../../providers/playlist_provider.dart';
import '../../providers/room_provider.dart';
import '../../utils/app_theme.dart';

class RecommendationScreen extends StatefulWidget {
  const RecommendationScreen({super.key});

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final room = context.read<RoomProvider>().currentRoom;
    if (room == null) return;

    // Fetch user profiles for all room members to power history scoring
    final auth = context.read<AuthProvider>();
    final List<UserModel> members =
        auth.user != null ? [auth.user!] : [];

    await context.read<PlaylistProvider>().loadRecommendations(
          currentMood: room.currentMood,
          roomMembers: members,
        );
  }

  @override
  Widget build(BuildContext context) {
    final playlist = context.watch<PlaylistProvider>();
    final room = context.watch<RoomProvider>().currentRoom;
    final isHost = room?.hostUid == context.read<AuthProvider>().user?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Up Next'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
            tooltip: 'Refresh suggestions',
          ),
        ],
      ),
      body: playlist.isLoadingRecs
          ? const Center(child: CircularProgressIndicator())
          : playlist.recommendations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome_outlined,
                        size: 64,
                        color: AppColors.onSurface.withAlpha(80),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No suggestions yet',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add songs and cast votes to get recommendations',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                      child: Text(
                        'Scored by: votes 50%, mood 30%, taste 20%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.onSurface,
                            ),
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: playlist.recommendations.length,
                        separatorBuilder: (context, i) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final rec = playlist.recommendations[i];
                          return _RecommendationCard(
                            rec: rec,
                            rank: i + 1,
                            isHost: isHost,
                            isPlaying: playlist.currentlyPlayingId == rec.songId,
                            onOverride: isHost
                                ? () => playlist.applyManualOverride(rec.songId)
                                : null,
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final RecommendationModel rec;
  final int rank;
  final bool isHost;
  final bool isPlaying;
  final VoidCallback? onOverride;

  const _RecommendationCard({
    required this.rec,
    required this.rank,
    required this.isHost,
    required this.isPlaying,
    this.onOverride,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: rec.isManualOverride
            ? Border.all(color: AppColors.primary, width: 1.5)
            : null,
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          isPlaying
              ? const Icon(Icons.equalizer, color: AppColors.primary, size: 26)
              : Text(
                  '$rank',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: rank == 1 ? AppColors.primary : AppColors.onSurface,
                  ),
                ),
          const SizedBox(width: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: CachedNetworkImage(
              imageUrl: rec.albumArtUrl,
              width: 52,
              height: 52,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: 52,
                height: 52,
                color: AppColors.surfaceVariant,
              ),
              errorWidget: (context, url, error) => Container(
                width: 52,
                height: 52,
                color: AppColors.surfaceVariant,
                child: const Icon(Icons.music_note),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rec.title,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  rec.artist,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  rec.reasoning,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.primary, fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (isHost && onOverride != null)
            IconButton(
              icon: const Icon(Icons.play_circle_outline,
                  color: AppColors.primary),
              onPressed: onOverride,
              tooltip: 'Play this next',
            ),
        ],
      ),
    );
  }
}
