import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/song_model.dart';
import '../../providers/playlist_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';

class MoodTagSheet extends StatefulWidget {
  final SongModel song;

  const MoodTagSheet({super.key, required this.song});

  @override
  State<MoodTagSheet> createState() => _MoodTagSheetState();
}

class _MoodTagSheetState extends State<MoodTagSheet> {
  late String _mood;
  late List<String> _genres;

  @override
  void initState() {
    super.initState();
    _mood = widget.song.mood;
    _genres = List.from(widget.song.genres);
  }

  Future<void> _save() async {
    final room = context.read<PlaylistProvider>();
    await room.tagSong(widget.song.id, _mood, _genres);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Tag "${widget.song.title}"',
            style: Theme.of(context).textTheme.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20),
          Text('Mood', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppConstants.moodOptions.map((mood) {
              final selected = _mood == mood;
              return ChoiceChip(
                label: Text(mood),
                selected: selected,
                onSelected: (_) => setState(() => _mood = mood),
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: selected ? Colors.black : AppColors.onSurface,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
                backgroundColor: AppColors.surfaceVariant,
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Text('Genres', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppConstants.genreOptions.map((genre) {
              final selected = _genres.contains(genre);
              return FilterChip(
                label: Text(genre),
                selected: selected,
                onSelected: (on) => setState(() {
                  if (on) {
                    _genres.add(genre);
                  } else {
                    _genres.remove(genre);
                  }
                }),
                selectedColor: AppColors.primary.withAlpha(50),
                checkmarkColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: selected ? AppColors.primary : AppColors.onSurface,
                ),
                backgroundColor: AppColors.surfaceVariant,
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              child: const Text('Save Tags'),
            ),
          ),
        ],
      ),
    );
  }
}
