import 'package:cloud_firestore/cloud_firestore.dart';

class SongModel {
  final String id; // Firestore document ID
  final String spotifyId;
  final String title;
  final String artist;
  final String album;
  final String albumArtUrl;
  final String? previewUrl; // 30-second Spotify preview
  final int durationMs;
  final int upvotes;
  final int downvotes;
  final String addedByUid;
  final String addedByName;
  final DateTime addedAt;
  final bool isPlayed;
  final String mood; // one of AppConstants.moodOptions
  final List<String> genres;
  final String? cachedAlbumArtPath; // Firebase Storage path after caching

  const SongModel({
    required this.id,
    required this.spotifyId,
    required this.title,
    required this.artist,
    required this.album,
    required this.albumArtUrl,
    this.previewUrl,
    required this.durationMs,
    this.upvotes = 0,
    this.downvotes = 0,
    required this.addedByUid,
    required this.addedByName,
    required this.addedAt,
    this.isPlayed = false,
    this.mood = 'chill',
    this.genres = const [],
    this.cachedAlbumArtPath,
  });

  int get voteScore => upvotes - downvotes;

  String get durationFormatted {
    final minutes = durationMs ~/ 60000;
    final seconds = (durationMs % 60000) ~/ 1000;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  factory SongModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SongModel(
      id: doc.id,
      spotifyId: data['spotifyId'] as String,
      title: data['title'] as String,
      artist: data['artist'] as String,
      album: data['album'] as String,
      albumArtUrl: data['albumArtUrl'] as String,
      previewUrl: data['previewUrl'] as String?,
      durationMs: data['durationMs'] as int,
      upvotes: data['upvotes'] as int? ?? 0,
      downvotes: data['downvotes'] as int? ?? 0,
      addedByUid: data['addedByUid'] as String,
      addedByName: data['addedByName'] as String,
      addedAt: (data['addedAt'] as Timestamp).toDate(),
      isPlayed: data['isPlayed'] as bool? ?? false,
      mood: data['mood'] as String? ?? 'chill',
      genres: List<String>.from(data['genres'] ?? []),
      cachedAlbumArtPath: data['cachedAlbumArtPath'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'spotifyId': spotifyId,
      'title': title,
      'artist': artist,
      'album': album,
      'albumArtUrl': albumArtUrl,
      'previewUrl': previewUrl,
      'durationMs': durationMs,
      'upvotes': upvotes,
      'downvotes': downvotes,
      'addedByUid': addedByUid,
      'addedByName': addedByName,
      'addedAt': Timestamp.fromDate(addedAt),
      'isPlayed': isPlayed,
      'mood': mood,
      'genres': genres,
      'cachedAlbumArtPath': cachedAlbumArtPath,
    };
  }

  SongModel copyWith({
    int? upvotes,
    int? downvotes,
    bool? isPlayed,
    String? mood,
    List<String>? genres,
    String? cachedAlbumArtPath,
  }) {
    return SongModel(
      id: id,
      spotifyId: spotifyId,
      title: title,
      artist: artist,
      album: album,
      albumArtUrl: albumArtUrl,
      previewUrl: previewUrl,
      durationMs: durationMs,
      upvotes: upvotes ?? this.upvotes,
      downvotes: downvotes ?? this.downvotes,
      addedByUid: addedByUid,
      addedByName: addedByName,
      addedAt: addedAt,
      isPlayed: isPlayed ?? this.isPlayed,
      mood: mood ?? this.mood,
      genres: genres ?? this.genres,
      cachedAlbumArtPath: cachedAlbumArtPath ?? this.cachedAlbumArtPath,
    );
  }
}
