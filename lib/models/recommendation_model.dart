class RecommendationModel {
  final String songId;
  final String spotifyId;
  final String title;
  final String artist;
  final String albumArtUrl;
  final double totalScore;
  final double voteScore; // contribution from vote weight
  final double moodScore; // contribution from mood match weight
  final double historyScore; // contribution from listen history weight
  final String reasoning; // human-readable explanation shown in UI
  final bool isManualOverride;

  const RecommendationModel({
    required this.songId,
    required this.spotifyId,
    required this.title,
    required this.artist,
    required this.albumArtUrl,
    required this.totalScore,
    required this.voteScore,
    required this.moodScore,
    required this.historyScore,
    required this.reasoning,
    this.isManualOverride = false,
  });

  RecommendationModel asOverride() {
    return RecommendationModel(
      songId: songId,
      spotifyId: spotifyId,
      title: title,
      artist: artist,
      albumArtUrl: albumArtUrl,
      totalScore: totalScore,
      voteScore: voteScore,
      moodScore: moodScore,
      historyScore: historyScore,
      reasoning: 'Manually selected by host',
      isManualOverride: true,
    );
  }
}
