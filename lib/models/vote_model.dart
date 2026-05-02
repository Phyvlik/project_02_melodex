import 'package:cloud_firestore/cloud_firestore.dart';

enum VoteType { up, down, none }

class VoteModel {
  final String id; // '{userId}_{songId}'
  final String userId;
  final String songId;
  final VoteType voteType;
  final DateTime votedAt;

  const VoteModel({
    required this.id,
    required this.userId,
    required this.songId,
    required this.voteType,
    required this.votedAt,
  });

  static String makeId(String userId, String songId) => '${userId}_$songId';

  factory VoteModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VoteModel(
      id: doc.id,
      userId: data['userId'] as String,
      songId: data['songId'] as String,
      voteType: VoteType.values.byName(data['voteType'] as String),
      votedAt: (data['votedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'songId': songId,
      'voteType': voteType.name,
      'votedAt': Timestamp.fromDate(votedAt),
    };
  }
}
