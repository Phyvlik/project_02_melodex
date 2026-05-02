import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final List<String> roomIds;
  final List<String> listenHistory; // track IDs listened to in rooms
  final Map<String, int> genrePlayCounts; // genre -> count for recommendations
  final DateTime createdAt;
  final DateTime lastActiveAt;
  final String? fcmToken;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.roomIds = const [],
    this.listenHistory = const [],
    this.genrePlayCounts = const {},
    required this.createdAt,
    required this.lastActiveAt,
    this.fcmToken,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] as String,
      displayName: data['displayName'] as String,
      photoUrl: data['photoUrl'] as String?,
      roomIds: List<String>.from(data['roomIds'] ?? []),
      listenHistory: List<String>.from(data['listenHistory'] ?? []),
      genrePlayCounts: Map<String, int>.from(data['genrePlayCounts'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastActiveAt: (data['lastActiveAt'] as Timestamp).toDate(),
      fcmToken: data['fcmToken'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'roomIds': roomIds,
      'listenHistory': listenHistory,
      'genrePlayCounts': genrePlayCounts,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActiveAt': Timestamp.fromDate(lastActiveAt),
      'fcmToken': fcmToken,
    };
  }

  UserModel copyWith({
    String? displayName,
    String? photoUrl,
    List<String>? roomIds,
    List<String>? listenHistory,
    Map<String, int>? genrePlayCounts,
    DateTime? lastActiveAt,
    String? fcmToken,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      roomIds: roomIds ?? this.roomIds,
      listenHistory: listenHistory ?? this.listenHistory,
      genrePlayCounts: genrePlayCounts ?? this.genrePlayCounts,
      createdAt: createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }
}
