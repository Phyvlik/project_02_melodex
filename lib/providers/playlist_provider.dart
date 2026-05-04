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

// Central state layer for the room's song queue, voting, playback, and AI recommendations.
// All Firestore writes go through PlaylistService; this provider holds the in-memory view
// and drives Spotify playback via SpotifyPlaybackService.
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
  String? _currentlyPlayingId; // Firestore song ID currently playing (null = nothing playing)
  Timer? _pollTimer;           // polls Spotify /me/player every 4 s to detect track end
  bool _isHost = false;
  String _currentMood = '';
  int _queryVariantIndex = 0;  // rotates through query variants for fresh Spotify suggestions
  SongModel? _currentlyPlayingSong;
  bool _isSpotifyPlaying = false;

  // 10 search modifiers rotated per refresh so Spotify returns different result sets each time
  static const List<String> _queryVariants = [
    'music', 'hits', 'vibes', 'songs', 'playlist',
    'mix', 'classics', 'top tracks', 'favorites', 'essentials',
  ];

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
  SongModel? get currentlyPlayingSong => _currentlyPlayingSong;
  bool get isSpotifyPlaying => _isSpotifyPlaying;

  VoteType voteFor(String songId) =>
      _userVotes[songId] ?? VoteType.none;

  // Called once when the user enters a room. Subscribes to Firestore streams
  // for the queue and votes. If this user is the host and the queue was empty
  // before (first song just added), auto-play kicks off without requiring a tap.
  void attachRoom(String roomId, String userId, {bool isHost = false, String userName = ''}) {
    if (_roomId == roomId) return;
    _roomId = roomId;
    _userId = userId;
    _userName = userName;
    _isHost = isHost;

    // Reset playback state from any previous room so the auto-play condition
    // isn't blocked by a leftover timer or playing ID from the last session.
    _pollTimer?.cancel();
    _pollTimer = null;
    _currentlyPlayingId = null;
    _currentlyPlayingSong = null;
    _isSpotifyPlaying = false;

    _playlistSub?.cancel();
    _playlistSub = _playlistService.watchPlaylist(roomId).listen((songs) {
      final wasEmpty = _songs.isEmpty;
      _songs = songs;
      notifyListeners();

      // Auto-start: host gets playback going the moment the first song lands
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
    if (_currentMood != currentMood) {
      _queryVariantIndex = 0;
    }
    _currentMood = currentMood;
    await _fetchRecommendations();
  }

  Future<void> _fetchRecommendations() async {
    if (_currentMood.isEmpty) return;
    _isLoadingRecs = true;
    notifyListeners();

    try {
      final variant = _queryVariants[_queryVariantIndex % _queryVariants.length];
      _queryVariantIndex++;
      final query = '$_currentMood $variant';
      final fresh = await _recommendationService.getSpotifySuggestions(
        query: query,
      );
      _recommendations = fresh;
    } catch (_) {
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

  Future<void> playRecommendationNow(RecommendationModel rec) async {
    if (_roomId == null) return;
    _recommendations.remove(rec);
    if (_recommendations.isEmpty && _currentMood.isNotEmpty) {
      _fetchRecommendations();
    }
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
    _currentlyPlayingSong = saved;
    _isSpotifyPlaying = true;
    notifyListeners();
    _startPolling();
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

    // Refill in the background when the list is running low
    if (_recommendations.isEmpty && _currentMood.isNotEmpty) {
      _fetchRecommendations();
    }

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
    _currentlyPlayingSong = saved;
    _isSpotifyPlaying = true;
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
    _currentlyPlayingSong = song;
    _isSpotifyPlaying = true;
    notifyListeners();

    _startPolling();
  }

  // Polls Spotify /me/player every 4 seconds.
  // Spotify returns HTTP 204 (null state) when no track is active.
  // We only treat null as "track ended" after we have confirmed at least one
  // non-null state — this prevents a missing/expired token from cascade-wiping
  // the queue (token missing → getPlaybackState always null → infinite advance).
  void _startPolling() {
    _pollTimer?.cancel();
    var sawPlayback = false; // must see Spotify playing before advancing on null
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      final state = await _playbackService.getPlaybackState();

      if (state == null) {
        if (_currentlyPlayingId != null && sawPlayback) {
          _pollTimer?.cancel();
          _pollTimer = null;
          _currentlyPlayingId = null;
          await Future.delayed(const Duration(seconds: 1));
          await playTopSong();
        }
        return;
      }

      sawPlayback = true;

      if (state.isPlaying != _isSpotifyPlaying) {
        _isSpotifyPlaying = state.isPlaying;
        notifyListeners();
      }

      if (state.isNearEnd) {
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
