import 'package:cloud_firestore/cloud_firestore.dart';

class RoomModel {
  final String id;
  final String name;
  final String inviteCode;
  final String hostUid;
  final List<String> memberUids;
  final List<String> preferredGenres;
  final String currentMood;
  final bool isActive;
  final DateTime createdAt;
  final String? currentSongId; // Firestore doc ID of the song currently playing

  const RoomModel({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.hostUid,
    this.memberUids = const [],
    this.preferredGenres = const [],
    this.currentMood = 'chill',
    this.isActive = true,
    required this.createdAt,
    this.currentSongId,
  });

  bool get isEmpty => memberUids.isEmpty;
  int get memberCount => memberUids.length;

  factory RoomModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RoomModel(
      id: doc.id,
      name: data['name'] as String,
      inviteCode: data['inviteCode'] as String,
      hostUid: data['hostUid'] as String,
      memberUids: List<String>.from(data['memberUids'] ?? []),
      preferredGenres: List<String>.from(data['preferredGenres'] ?? []),
      currentMood: data['currentMood'] as String? ?? 'chill',
      isActive: data['isActive'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      currentSongId: data['currentSongId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'inviteCode': inviteCode,
      'hostUid': hostUid,
      'memberUids': memberUids,
      'preferredGenres': preferredGenres,
      'currentMood': currentMood,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'currentSongId': currentSongId,
    };
  }

  RoomModel copyWith({
    String? name,
    List<String>? memberUids,
    List<String>? preferredGenres,
    String? currentMood,
    bool? isActive,
    String? currentSongId,
  }) {
    return RoomModel(
      id: id,
      name: name ?? this.name,
      inviteCode: inviteCode,
      hostUid: hostUid,
      memberUids: memberUids ?? this.memberUids,
      preferredGenres: preferredGenres ?? this.preferredGenres,
      currentMood: currentMood ?? this.currentMood,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      currentSongId: currentSongId ?? this.currentSongId,
    );
  }
}
