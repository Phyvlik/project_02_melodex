import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/song_model.dart';
import '../utils/constants.dart';

class PlaylistService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference _playlistRef(String roomId) => _db
      .collection(AppConstants.roomsCollection)
      .doc(roomId)
      .collection(AppConstants.playlistCollection);

  Future<SongModel> addSong(String roomId, SongModel song) async {
    final docRef = _playlistRef(roomId).doc();
    final songWithId = SongModel(
      id: docRef.id,
      spotifyId: song.spotifyId,
      title: song.title,
      artist: song.artist,
      album: song.album,
      albumArtUrl: song.albumArtUrl,
      previewUrl: song.previewUrl,
      durationMs: song.durationMs,
      addedByUid: song.addedByUid,
      addedByName: song.addedByName,
      addedAt: DateTime.now(),
      mood: song.mood,
      genres: song.genres,
    );
    await docRef.set(songWithId.toFirestore());
    return songWithId;
  }

  Future<void> removeSong(String roomId, String songId) async {
    await _playlistRef(roomId).doc(songId).delete();
  }

  Future<void> markSongPlayed(String roomId, String songId) async {
    await _playlistRef(roomId).doc(songId).update({'isPlayed': true});
  }

  Future<void> updateSongMood(String roomId, String songId, String mood) async {
    await _playlistRef(roomId).doc(songId).update({'mood': mood});
  }

  Future<void> updateSongGenres(
    String roomId,
    String songId,
    List<String> genres,
  ) async {
    await _playlistRef(roomId).doc(songId).update({'genres': genres});
  }

  Future<void> updateCachedArtPath(
    String roomId,
    String songId,
    String storagePath,
  ) async {
    await _playlistRef(roomId)
        .doc(songId)
        .update({'cachedAlbumArtPath': storagePath});
  }

  // Songs ordered by vote score descending, unplayed first
  Stream<List<SongModel>> watchPlaylist(String roomId) {
    return _playlistRef(roomId)
        .where('isPlayed', isEqualTo: false)
        .snapshots()
        .map((snap) {
      final songs = snap.docs.map(SongModel.fromFirestore).toList();
      songs.sort((a, b) => b.voteScore.compareTo(a.voteScore));
      return songs;
    });
  }

  Future<List<SongModel>> getPlayedHistory(String roomId) async {
    final snap = await _playlistRef(roomId)
        .where('isPlayed', isEqualTo: true)
        .orderBy('addedAt', descending: true)
        .get();
    return snap.docs.map(SongModel.fromFirestore).toList();
  }

  Future<SongModel?> fetchSong(String roomId, String songId) async {
    final doc = await _playlistRef(roomId).doc(songId).get();
    if (!doc.exists) return null;
    return SongModel.fromFirestore(doc);
  }
}
