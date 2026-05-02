import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/song_model.dart';
import '../models/vote_model.dart';
import '../models/recommendation_model.dart';
import '../models/user_model.dart';
import '../services/playlist_service.dart';
import '../services/vote_service.dart';
import '../services/recommendation_service.dart';
import '../services/storage_service.dart';
import '../services/chat_service.dart';
import '../models/chat_message_model.dart';

class PlaylistProvider extends ChangeNotifier {
  final PlaylistService _playlistService = PlaylistService();
  final VoteService _voteService = VoteService();
  final RecommendationService _recommendationService = RecommendationService();
  final StorageService _storageService = StorageService();
  final ChatService _chatService = ChatService();

  List<SongModel> _songs = [];
  Map<String, VoteType> _userVotes = {};
  List<RecommendationModel> _recommendations = [];
  bool _isLoading = false;
  bool _isLoadingRecs = false;
  String? _errorMessage;
  String? _roomId;

  StreamSubscription<List<SongModel>>? _playlistSub;
  StreamSubscription<Map<String, VoteType>>? _votesSub;

  List<SongModel> get songs => _songs;
  Map<String, VoteType> get userVotes => _userVotes;
  List<RecommendationModel> get recommendations => _recommendations;
  bool get isLoading => _isLoading;
  bool get isLoadingRecs => _isLoadingRecs;
  String? get errorMessage => _errorMessage;
  bool get isEmpty => _songs.isEmpty;

  VoteType voteFor(String songId) =>
      _userVotes[songId] ?? VoteType.none;

  void attachRoom(String roomId, String userId) {
    if (_roomId == roomId) return;
    _roomId = roomId;

    _playlistSub?.cancel();
    _playlistSub = _playlistService.watchPlaylist(roomId).listen((songs) {
      _songs = songs;
      notifyListeners();
    });

    _votesSub?.cancel();
    _votesSub = _voteService
        .watchUserVotesForRoom(roomId, userId)
        .listen((votes) {
      _userVotes = votes;
      notifyListeners();
    });
  }

  Future<void> addSong(SongModel song, UserModel addedBy) async {
    if (_roomId == null) return;
    _setLoading(true);
    try {
      final saved = await _playlistService.addSong(_roomId!, song);

      // Fire-and-forget album art caching to Firebase Storage
      _storageService
          .cacheAlbumArt(song.spotifyId, song.albumArtUrl)
          .then((cachedUrl) {
        if (cachedUrl != null) {
          _playlistService.updateCachedArtPath(_roomId!, saved.id, cachedUrl);
        }
      });

      await _chatService.postSystemMessage(
        roomId: _roomId!,
        content: '${addedBy.displayName} added "${song.title}" by ${song.artist}',
        type: MessageType.songAdded,
        linkedSongId: saved.id,
      );
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to add song. Please try again.';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> castVote(String userId, String songId, VoteType type) async {
    if (_roomId == null) return;
    await _voteService.castVote(
      roomId: _roomId!,
      userId: userId,
      songId: songId,
      newVoteType: type,
    );
  }

  Future<void> removeSong(String songId) async {
    if (_roomId == null) return;
    await _playlistService.removeSong(_roomId!, songId);
  }

  Future<void> markPlayed(String songId) async {
    if (_roomId == null) return;
    await _playlistService.markSongPlayed(_roomId!, songId);
  }

  Future<void> tagSong(
    String songId,
    String mood,
    List<String> genres,
  ) async {
    if (_roomId == null) return;
    await _playlistService.updateSongMood(_roomId!, songId, mood);
    await _playlistService.updateSongGenres(_roomId!, songId, genres);
  }

  Future<void> loadRecommendations({
    required String currentMood,
    required List<UserModel> roomMembers,
  }) async {
    if (_roomId == null) return;
    _isLoadingRecs = true;
    notifyListeners();
    try {
      _recommendations = await _recommendationService.getSuggestions(
        roomId: _roomId!,
        currentMood: currentMood,
        roomMembers: roomMembers,
      );
    } finally {
      _isLoadingRecs = false;
      notifyListeners();
    }
  }

  Future<void> applyManualOverride(String songId) async {
    if (_roomId == null) return;
    await _recommendationService.saveManualOverride(_roomId!, songId);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _playlistSub?.cancel();
    _votesSub?.cancel();
    super.dispose();
  }
}
