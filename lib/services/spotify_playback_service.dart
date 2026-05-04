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

  // Returns a valid PKCE user token, refreshing it if near expiry.
  // Returns null if the user has never connected Spotify.
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.prefSpotifyUserToken);
    final expiryMs = prefs.getInt(AppConstants.prefSpotifyUserTokenExpiry);

    if (token == null) return null;

    if (expiryMs != null) {
      final expiry = DateTime.fromMillisecondsSinceEpoch(expiryMs);
      if (DateTime.now().isAfter(expiry.subtract(const Duration(minutes: 2)))) {
        return await _refreshToken(prefs);
      }
    }

    return token;
  }

  Future<String?> _refreshToken(SharedPreferences prefs) async {
    final refreshToken = prefs.getString(AppConstants.prefSpotifyRefreshToken);
    if (refreshToken == null) return null;

    try {
      final response = await _dio.post(
        AppConstants.spotifyTokenUrl,
        data: {
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
          'client_id': AppConstants.spotifyClientId,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          validateStatus: (s) => s != null && s < 500,
        ),
      );

      if (response.statusCode != 200) return null;

      final data = response.data as Map<String, dynamic>;
      final newToken = data['access_token'] as String;
      final expiresIn = data['expires_in'] as int;
      final newExpiry = DateTime.now().add(Duration(seconds: expiresIn));

      await prefs.setString(AppConstants.prefSpotifyUserToken, newToken);
      await prefs.setInt(
        AppConstants.prefSpotifyUserTokenExpiry,
        newExpiry.millisecondsSinceEpoch,
      );

      if (data['refresh_token'] != null) {
        await prefs.setString(
          AppConstants.prefSpotifyRefreshToken,
          data['refresh_token'] as String,
        );
      }

      return newToken;
    } catch (_) {
      return null;
    }
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
