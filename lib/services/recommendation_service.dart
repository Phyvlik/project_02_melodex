import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/song_model.dart';
import '../models/recommendation_model.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

// Scoring rules (transparent if/then logic as required by must-solve challenge):
//
//   totalScore = (voteScore * weightVotes)
//              + (moodMatchScore * weightMood)
//              + (historyBoostScore * weightListenHistory)
//
// weightVotes   = 0.50
// weightMood    = 0.30
// weightHistory = 0.20

class RecommendationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<RecommendationModel>> getSuggestions({
    required String roomId,
    required String currentMood,
    required List<UserModel> roomMembers,
    int topN = 3,
  }) async {
    final snap = await _db
        .collection(AppConstants.roomsCollection)
        .doc(roomId)
        .collection(AppConstants.playlistCollection)
        .where('isPlayed', isEqualTo: false)
        .get();

    if (snap.docs.isEmpty) return [];

    final songs = snap.docs.map(SongModel.fromFirestore).toList();
    final memberHistories = roomMembers.expand((m) => m.listenHistory).toList();
    final memberGenreCounts = <String, int>{};
    for (final m in roomMembers) {
      m.genrePlayCounts.forEach((genre, plays) {
        memberGenreCounts[genre] = (memberGenreCounts[genre] ?? 0) + plays;
      });
    }

    final maxVote = songs
        .map((s) => s.voteScore.abs())
        .fold(1, (a, b) => a > b ? a : b)
        .toDouble();

    final recommendations = songs.map((song) {
      return _score(
        song: song,
        currentMood: currentMood,
        memberHistories: memberHistories,
        memberGenreCounts: memberGenreCounts,
        maxVote: maxVote,
      );
    }).toList();

    recommendations.sort((a, b) => b.totalScore.compareTo(a.totalScore));
    return recommendations.take(topN).toList();
  }

  RecommendationModel _score({
    required SongModel song,
    required String currentMood,
    required List<String> memberHistories,
    required Map<String, int> memberGenreCounts,
    required double maxVote,
  }) {
    // --- Vote component ---
    // Normalize vote score to [0, 1] range using max observed vote
    final normalizedVote = maxVote > 0
        ? ((song.voteScore + maxVote) / (2 * maxVote)).clamp(0.0, 1.0)
        : 0.5;
    final voteContrib = normalizedVote * AppConstants.weightVotes;

    // --- Mood component ---
    // 1.0 if mood matches exactly, 0.5 if song has no mood tag, else 0.0
    double moodMatch;
    if (song.mood == currentMood) {
      moodMatch = 1.0;
    } else if (song.mood.isEmpty || song.mood == 'chill') {
      moodMatch = 0.5;
    } else {
      moodMatch = 0.0;
    }
    final moodContrib = moodMatch * AppConstants.weightMood;

    // --- History component ---
    // Boost songs whose genres the group listens to frequently
    // If song was already played by a member, reduce score (avoid repeats)
    double historyBoost = 0.0;
    if (memberHistories.contains(song.spotifyId)) {
      historyBoost = -0.5; // penalty for recently heard song
    } else {
      final genreHits = song.genres
          .where((g) => memberGenreCounts.containsKey(g))
          .fold(0, (total, g) => total + memberGenreCounts[g]!);
      final maxGenreHits = memberGenreCounts.values.fold(1, (a, b) => a > b ? a : b);
      historyBoost = (genreHits / maxGenreHits).clamp(0.0, 1.0);
    }
    final historyContrib = historyBoost * AppConstants.weightListenHistory;

    final total = (voteContrib + moodContrib + historyContrib).clamp(0.0, 1.0);

    return RecommendationModel(
      songId: song.id,
      spotifyId: song.spotifyId,
      title: song.title,
      artist: song.artist,
      albumArtUrl: song.albumArtUrl,
      totalScore: total,
      voteScore: voteContrib,
      moodScore: moodContrib,
      historyScore: historyContrib,
      reasoning: _buildReasoning(
        song: song,
        currentMood: currentMood,
        voteScore: song.voteScore,
        moodMatch: moodMatch,
        historyBoost: historyBoost,
      ),
    );
  }

  String _buildReasoning({
    required SongModel song,
    required String currentMood,
    required int voteScore,
    required double moodMatch,
    required double historyBoost,
  }) {
    final parts = <String>[];

    if (voteScore > 0) {
      parts.add('votes +$voteScore');
    } else if (voteScore < 0) {
      parts.add('votes $voteScore');
    } else {
      parts.add('votes neutral');
    }

    if (moodMatch == 1.0) {
      parts.add('mood matches ($currentMood)');
    } else if (moodMatch == 0.5) {
      parts.add('mood untagged');
    } else {
      parts.add('mood mismatch');
    }

    if (historyBoost < 0) {
      parts.add('recently played');
    } else if (historyBoost > 0.5) {
      parts.add('genre fits taste');
    } else if (historyBoost > 0) {
      parts.add('some genre overlap');
    } else {
      parts.add('no genre data');
    }

    return parts.join(' | ');
  }

  // Persist a manual override to Firestore so all clients see it
  Future<void> saveManualOverride(String roomId, String songId) async {
    await _db
        .collection(AppConstants.roomsCollection)
        .doc(roomId)
        .update({'currentSongId': songId});
  }
}
