import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class PlaybackState {
  final String? trackId;
  final int progressMs;
  final int durationMs;
  final bool isPlaying;

  const PlaybackState({
    this.trackId,
    required this.progressMs,
    required this.durationMs,
    required this.isPlaying,
  });

  bool get isNearEnd => durationMs > 0 && progressMs >= durationMs - 4000;
}

class SpotifyPlaybackService {
  final Dio _dio = Dio();

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.prefSpotifyToken);
  }

  Future<void> play(String spotifyId) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not connected to Spotify');

    await _dio.put(
      'https://api.spotify.com/v1/me/player/play',
      data: {
        'uris': ['spotify:track:$spotifyId'],
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        validateStatus: (s) => s != null && s < 500,
      ),
    );
  }

  Future<PlaybackState?> getPlaybackState() async {
    final token = await _getToken();
    if (token == null) return null;

    try {
      final response = await _dio.get(
        'https://api.spotify.com/v1/me/player',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (s) => s != null && s < 500,
        ),
      );

      if (response.statusCode == 204 || response.data == null) return null;

      final data = response.data as Map<String, dynamic>;
      final item = data['item'] as Map<String, dynamic>?;
      final progress = data['progress_ms'] as int? ?? 0;
      final playing = data['is_playing'] as bool? ?? false;
      final trackId = item?['id'] as String?;
      final duration = item?['duration_ms'] as int? ?? 0;

      return PlaybackState(
        trackId: trackId,
        progressMs: progress,
        durationMs: duration,
        isPlaying: playing,
      );
    } catch (_) {
      return null;
    }
  }
}
