import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/playlist_provider.dart';
import '../../services/spotify_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SongSearchScreen extends StatefulWidget {
  const SongSearchScreen({super.key});

  @override
  State<SongSearchScreen> createState() => _SongSearchScreenState();
}

class _SongSearchScreenState extends State<SongSearchScreen> {
  final _searchController = TextEditingController();
  final SpotifyService _spotify = SpotifyService();
  List<SpotifyTrack> _results = [];
  bool _isSearching = false;
  String? _error;
  String _selectedMood = 'chill';
  final List<String> _selectedGenres = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _isSearching = true;
      _error = null;
    });
    try {
      final results = await _spotify.searchTracks(query.trim());
      setState(() => _results = results);
    } catch (e) {
      setState(() => _error = 'Search failed. Check your connection.');
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _addTrack(SpotifyTrack track) async {
    final auth = context.read<AuthProvider>();
    final playlist = context.read<PlaylistProvider>();
    final user = auth.user!;

    final song = _spotify.trackToSong(
      track,
      addedByUid: user.uid,
      addedByName: user.displayName,
      mood: _selectedMood,
      genres: _selectedGenres,
    );

    await playlist.addSong(song, user);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          onSubmitted: _search,
          style: const TextStyle(color: AppColors.onBackground),
          decoration: InputDecoration(
            hintText: 'Search songs, artists...',
            hintStyle: const TextStyle(color: AppColors.onSurface),
            border: InputBorder.none,
            filled: false,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _results = []);
                    },
                  )
                : null,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _search(_searchController.text),
          ),
        ],
      ),
      body: Column(
        children: [
          _MoodGenreBar(
            selectedMood: _selectedMood,
            onMoodChanged: (m) => setState(() => _selectedMood = m),
          ),
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Text(
                          _error!,
                          style: TextStyle(color: AppColors.error),
                        ),
                      )
                    : _results.isEmpty
                        ? Center(
                            child: Text(
                              'Search for a song to add to the room',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            itemCount: _results.length,
                            separatorBuilder: (context, i) =>
                                const SizedBox(height: 4),
                            itemBuilder: (context, i) {
                              final track = _results[i];
                              return _TrackTile(
                                track: track,
                                onAdd: () => _addTrack(track),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class _MoodGenreBar extends StatelessWidget {
  final String selectedMood;
  final ValueChanged<String> onMoodChanged;

  const _MoodGenreBar({
    required this.selectedMood,
    required this.onMoodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: AppConstants.moodOptions.map((mood) {
          final selected = selectedMood == mood;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(mood),
              selected: selected,
              onSelected: (_) => onMoodChanged(mood),
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: selected ? Colors.black : AppColors.onSurface,
                fontSize: 12,
              ),
              backgroundColor: AppColors.surfaceVariant,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TrackTile extends StatelessWidget {
  final SpotifyTrack track;
  final VoidCallback onAdd;

  const _TrackTile({required this.track, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: AppColors.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: CachedNetworkImage(
          imageUrl: track.albumArtUrl,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            width: 48,
            height: 48,
            color: AppColors.surfaceVariant,
          ),
          errorWidget: (context, url, error) => Container(
            width: 48,
            height: 48,
            color: AppColors.surfaceVariant,
            child: const Icon(Icons.music_note, color: AppColors.onSurface),
          ),
        ),
      ),
      title: Text(
        track.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context)
            .textTheme
            .bodyLarge
            ?.copyWith(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        track.artistNames.join(', '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
        onPressed: onAdd,
      ),
    );
  }
}
