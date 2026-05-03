import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/song_model.dart';
import '../models/vote_model.dart';
import '../providers/auth_provider.dart';
import '../providers/playlist_provider.dart';
import '../utils/app_theme.dart';
import 'animated_equalizer.dart';

class SongCard extends StatelessWidget {
  final SongModel song;
  final bool isHost;
  final VoidCallback? onTagTap;

  const SongCard({
    super.key,
    required this.song,
    this.isHost = false,
    this.onTagTap,
  });

  @override
  Widget build(BuildContext context) {
    final playlist = context.watch<PlaylistProvider>();
    final uid = context.read<AuthProvider>().user?.uid ?? '';
    final currentVote = playlist.voteFor(song.id);
    final isPlaying = playlist.currentlyPlayingId == song.id;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: isPlaying
            ? AppColors.primary.withAlpha(20)
            : AppColors.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: isPlaying
            ? Border.all(color: AppColors.primary.withAlpha(120), width: 1.5)
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: CachedNetworkImage(
                  imageUrl: song.cachedAlbumArtPath ?? song.albumArtUrl,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => Container(
                    width: 52,
                    height: 52,
                    color: AppColors.surfaceVariant,
                    child: const Icon(Icons.music_note,
                        color: AppColors.onSurface),
                  ),
                  errorWidget: (_, _, _) => Container(
                    width: 52,
                    height: 52,
                    color: AppColors.surfaceVariant,
                    child: const Icon(Icons.broken_image,
                        color: AppColors.onSurface),
                  ),
                ),
              ),
              if (isPlaying)
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(120),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Center(
                    child: AnimatedEqualizer(size: 28),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isPlaying ? AppColors.primary : null,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  song.artist,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (song.mood.isNotEmpty)
                      _Tag(label: song.mood, color: AppColors.primary),
                    if (song.mood.isNotEmpty && song.genres.isNotEmpty)
                      const SizedBox(width: 4),
                    if (song.genres.isNotEmpty)
                      _Tag(
                        label: song.genres.first,
                        color: AppColors.onSurface,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              _VoteButton(
                icon: Icons.keyboard_arrow_up_rounded,
                active: currentVote == VoteType.up,
                activeColor: AppColors.vote,
                onTap: () => playlist.castVote(uid, song.id, VoteType.up),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) => SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, -0.5),
                    end: Offset.zero,
                  ).animate(animation),
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: Text(
                  '${song.voteScore}',
                  key: ValueKey(song.voteScore),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: song.voteScore > 0
                        ? AppColors.vote
                        : song.voteScore < 0
                            ? AppColors.downvote
                            : AppColors.onSurface,
                  ),
                ),
              ),
              _VoteButton(
                icon: Icons.keyboard_arrow_down_rounded,
                active: currentVote == VoteType.down,
                activeColor: AppColors.downvote,
                onTap: () => playlist.castVote(uid, song.id, VoteType.down),
              ),
            ],
          ),
          if (onTagTap != null) ...[
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.label_outline, size: 20),
              color: AppColors.onSurface,
              onPressed: onTagTap,
              tooltip: 'Tag mood/genre',
            ),
          ],
        ],
      ),
    );
  }
}

class _VoteButton extends StatefulWidget {
  final IconData icon;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  const _VoteButton({
    required this.icon,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  @override
  State<_VoteButton> createState() => _VoteButtonState();
}

class _VoteButtonState extends State<_VoteButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _scale = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTap() {
    _ctrl.forward().then((_) => _ctrl.reverse());
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: ScaleTransition(
        scale: _scale,
        child: Icon(
          widget.icon,
          size: 26,
          color: widget.active ? widget.activeColor : AppColors.onSurface,
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;

  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: color),
      ),
    );
  }
}
