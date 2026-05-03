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
import '../services/spotify_playback_service.dart';
import '../models/chat_message_model.dart';

class PlaylistProvider extends ChangeNotifier {
  final PlaylistService _playlistService = PlaylistService();
  final VoteService _voteService = VoteService();
  final RecommendationService _recommendationService = RecommendationService();
  final StorageService _storageService = StorageService();
  final ChatService _chatService = ChatService();
  final SpotifyPlaybackService _playbackService = SpotifyPlaybackService();

  List<SongModel> _songs = [];
  Map<String, VoteType> _userVotes = {};
  List<RecommendationModel> _recommendations = [];
  bool _isLoading = false;
  bool _isLoadingRecs = false;
  String? _errorMessage;
  String? _roomId;
  String? _userId;
  String _userName = '';
  String? _currentlyPlayingId;
  Timer? _pollTimer;
  bool _isHost = false;

  StreamSubscription<List<SongModel>>? _playlistSub;
  StreamSubscription<Map<String, VoteType>>? _votesSub;

  List<SongModel> get songs => _songs;
  Map<String, VoteType> get userVotes => _userVotes;
  List<RecommendationModel> get recommendations => _recommendations;
  bool get isLoading => _isLoading;
  bool get isLoadingRecs => _isLoadingRecs;
  String? get errorMessage => _errorMessage;
  bool get isEmpty => _songs.isEmpty;
  String? get currentlyPlayingId => _currentlyPlayingId;

  VoteType voteFor(String songId) =>
      _userVotes[songId] ?? VoteType.none;

  void attachRoom(String roomId, String userId, {bool isHost = false, String userName = ''}) {
    if (_roomId == roomId) return;
    _roomId = roomId;
    _userId = userId;
    _userName = userName;
    _isHost = isHost;

    _playlistSub?.cancel();
    _playlistSub = _playlistService.watchPlaylist(roomId).listen((songs) {
      final wasEmpty = _songs.isEmpty;
      _songs = songs;
      notifyListeners();

      if (_isHost &&
          wasEmpty &&
          songs.isNotEmpty &&
          _currentlyPlayingId == null &&
          _pollTimer == null) {
        playTopSong();
      }
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
Future<void> loadSpotifyRecommendations({
  required String currentMood,
}) async {
  _isLoadingRecs = true;
  notifyListeners();

  try {
    final query = '$currentMood music';

    _recommendations =
        await _recommendationService.getSpotifySuggestions(query: query);
  } catch (e) {
    _recommendations = [];
  } finally {
    _isLoadingRecs = false;
    notifyListeners();
  }
}
  Future<void> applyManualOverride(String songId) async {
    if (_roomId == null) return;
    await _recommendationService.saveManualOverride(_roomId!, songId);
    await _playSong(songId);
  }

  Future<void> playTopSong() async {
    if (_songs.isEmpty) {
      if (_recommendations.isNotEmpty) {
        await _playFromRecommendation();
      }
      return;
    }
    final top = _songs.first;
    await _playSong(top.id);
  }

  Future<void> _playFromRecommendation() async {
    if (_recommendations.isEmpty || _roomId == null) return;
    final rec = _recommendations.first;
    _recommendations.removeAt(0);
    notifyListeners();

    final song = SongModel(
      id: '',
      spotifyId: rec.spotifyId,
      title: rec.title,
      artist: rec.artist,
      album: '',
      albumArtUrl: rec.albumArtUrl,
      durationMs: 0,
      addedByUid: _userId ?? '',
      addedByName: _userName,
      addedAt: DateTime.now(),
    );

    final saved = await _playlistService.addSong(_roomId!, song);

    try {
      await _playbackService.play(rec.spotifyId);
    } catch (_) {}

    await _playlistService.markSongPlayed(_roomId!, saved.id);
    _currentlyPlayingId = saved.id;
    notifyListeners();
    _startPolling();
  }

  Future<void> _playSong(String songId) async {
    if (_roomId == null) return;
    final song = _songs.firstWhere(
      (s) => s.id == songId,
      orElse: () => _songs.first,
    );

    try {
      await _playbackService.play(song.spotifyId);
    } catch (_) {
      // Spotify not connected or no active device -- still mark played
    }

    await _playlistService.markSongPlayed(_roomId!, songId);
    _currentlyPlayingId = songId;
    notifyListeners();

    _startPolling();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      final state = await _playbackService.getPlaybackState();

      // 204 / null while we own a playing song means the track ended
      if (state == null) {
        if (_currentlyPlayingId != null) {
          _pollTimer?.cancel();
          _pollTimer = null;
          _currentlyPlayingId = null;
          await Future.delayed(const Duration(seconds: 1));
          await playTopSong();
        }
        return;
      }

      if (state.isNearEnd || (!state.isPlaying && _currentlyPlayingId != null)) {
        _pollTimer?.cancel();
        _pollTimer = null;
        _currentlyPlayingId = null;

        await Future.delayed(const Duration(seconds: 2));
        await playTopSong();
      }
    });
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
    _pollTimer?.cancel();
    _playlistSub?.cancel();
    _votesSub?.cancel();
    super.dispose();
  }
}
