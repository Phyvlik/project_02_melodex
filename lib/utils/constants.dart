class AppConstants {
  // Firestore collection names
  static const String usersCollection = 'users';
  static const String roomsCollection = 'rooms';
  static const String playlistCollection = 'playlist';
  static const String votesCollection = 'votes';
  static const String messagesCollection = 'messages';
  static const String recommendationsCollection = 'recommendations';

  // Shared prefs keys
  static const String prefSpotifyToken = 'spotify_access_token';
  static const String prefSpotifyExpiry = 'spotify_token_expiry';
  static const String prefUserId = 'user_id';

  // Spotify API base
  static const String spotifyApiBase = 'https://api.spotify.com/v1';
  static const String spotifyTokenUrl = 'https://accounts.spotify.com/api/token';

  // Room settings
  static const int inviteCodeLength = 6;
  static const int maxRoomMembers = 20;
  static const int maxPlaylistSize = 100;

  // Recommendation scoring weights
  static const double weightVotes = 0.5;
  static const double weightMood = 0.3;
  static const double weightListenHistory = 0.2;

  // Mood options shown to users
  static const List<String> moodOptions = [
    'hype',
    'chill',
    'sad',
    'focus',
    'party',
    'romantic',
  ];

  // Genre options
  static const List<String> genreOptions = [
    'pop',
    'hip-hop',
    'r&b',
    'rock',
    'electronic',
    'latin',
    'country',
    'jazz',
    'classical',
    'indie',
  ];
}
