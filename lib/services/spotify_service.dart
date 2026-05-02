import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song_model.dart';
import '../utils/constants.dart';

class SpotifyService {
  // Client credentials - set these from your Spotify developer dashboard
  // In production these should come from a secure backend/Cloud Function
  static const String _clientId = 'b5824514187b4a2181a04c36d6b180e5';
  static const String _clientSecret = '7285f049050941d4bef4615241b985f4';

  String? _accessToken;
  DateTime? _tokenExpiry;

  Future<String> _getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();

    final saved = prefs.getString(AppConstants.prefSpotifyToken);
    final expiry = prefs.getInt(AppConstants.prefSpotifyExpiry);

    if (saved != null && expiry != null) {
      final expiryDate = DateTime.fromMillisecondsSinceEpoch(expiry);
      if (DateTime.now().isBefore(expiryDate.subtract(const Duration(minutes: 2)))) {
        _accessToken = saved;
        return saved;
      }
    }

    return _refreshToken(prefs);
  }

  Future<String> _refreshToken(SharedPreferences prefs) async {
    final credentials = base64Encode(utf8.encode('$_clientId:$_clientSecret'));

    final response = await http.post(
      Uri.parse(AppConstants.spotifyTokenUrl),
      headers: {
        'Authorization': 'Basic $credentials',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {'grant_type': 'client_credentials'},
    );

    if (response.statusCode != 200) {
      throw Exception('Spotify token fetch failed: ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final token = body['access_token'] as String;
    final expiresIn = body['expires_in'] as int;
    final expiry = DateTime.now().add(Duration(seconds: expiresIn));

    await prefs.setString(AppConstants.prefSpotifyToken, token);
    await prefs.setInt(
      AppConstants.prefSpotifyExpiry,
      expiry.millisecondsSinceEpoch,
    );

    _accessToken = token;
    _tokenExpiry = expiry;
    return token;
  }

  Future<List<SpotifyTrack>> searchTracks(String query) async {
    final token = await _getAccessToken();
    final dio = Dio();

    try {
      final response = await dio.get(
        'https://api.spotify.com/v1/search',
        queryParameters: {
          'q': query,
          'type': 'track',
          'limit': 20,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );
      return _parseSearchResults(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        final prefs = await SharedPreferences.getInstance();
        final newToken = await _refreshToken(prefs);
        final retry = await dio.get(
          'https://api.spotify.com/v1/search',
          queryParameters: {
            'q': query,
            'type': 'track',
            'limit': 20,
          },
          options: Options(
            headers: {
              'Authorization': 'Bearer $newToken',
              'Accept': 'application/json',
            },
          ),
        );
        return _parseSearchResults(retry.data);
      }
      throw Exception('Spotify search failed: ${e.response?.statusCode}');
    }
  }

  List<SpotifyTrack> _parseSearchResults(dynamic body) {
    final data = (body is String ? jsonDecode(body) : body) as Map<String, dynamic>;
    final items = (data['tracks']['items'] as List<dynamic>);

    return items
        .where((item) => item != null)
        .map((item) => SpotifyTrack.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  // Convert a SpotifyTrack to a SongModel ready to add to a room playlist
  SongModel trackToSong(
    SpotifyTrack track, {
    required String addedByUid,
    required String addedByName,
    String mood = 'chill',
    List<String> genres = const [],
  }) {
    return SongModel(
      id: '',
      spotifyId: track.id,
      title: track.name,
      artist: track.artistNames.join(', '),
      album: track.albumName,
      albumArtUrl: track.albumArtUrl,
      previewUrl: track.previewUrl,
      durationMs: track.durationMs,
      addedByUid: addedByUid,
      addedByName: addedByName,
      addedAt: DateTime.now(),
      mood: mood,
      genres: genres,
    );
  }
}

class SpotifyTrack {
  final String id;
  final String name;
  final List<String> artistNames;
  final String albumName;
  final String albumArtUrl;
  final String? previewUrl;
  final int durationMs;
  final String spotifyUrl;

  const SpotifyTrack({
    required this.id,
    required this.name,
    required this.artistNames,
    required this.albumName,
    required this.albumArtUrl,
    this.previewUrl,
    required this.durationMs,
    required this.spotifyUrl,
  });

  factory SpotifyTrack.fromJson(Map<String, dynamic> json) {
    final artists = json['artists'] as List<dynamic>;
    final album = json['album'] as Map<String, dynamic>;
    final images = album['images'] as List<dynamic>;
    final artUrl = images.isNotEmpty
        ? (images.first as Map<String, dynamic>)['url'] as String
        : '';

    return SpotifyTrack(
      id: json['id'] as String,
      name: json['name'] as String,
      artistNames:
          artists.map((a) => (a as Map<String, dynamic>)['name'] as String).toList(),
      albumName: album['name'] as String,
      albumArtUrl: artUrl,
      previewUrl: json['preview_url'] as String?,
      durationMs: json['duration_ms'] as int,
      spotifyUrl: (json['external_urls'] as Map<String, dynamic>)['spotify'] as String,
    );
  }
}
