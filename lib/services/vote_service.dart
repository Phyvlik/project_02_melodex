import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vote_model.dart';
import '../utils/constants.dart';

class VoteService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference _votesRef(String roomId) => _db
      .collection(AppConstants.roomsCollection)
      .doc(roomId)
      .collection(AppConstants.votesCollection);

  CollectionReference _playlistRef(String roomId) => _db
      .collection(AppConstants.roomsCollection)
      .doc(roomId)
      .collection(AppConstants.playlistCollection);

  // Atomic transaction: update the vote doc and adjust song counters together
  Future<void> castVote({
    required String roomId,
    required String userId,
    required String songId,
    required VoteType newVoteType,
  }) async {
    final voteId = VoteModel.makeId(userId, songId);
    final voteRef = _votesRef(roomId).doc(voteId);
    final songRef = _playlistRef(roomId).doc(songId);

    await _db.runTransaction((tx) async {
      final voteSnap = await tx.get(voteRef);
      final songSnap = await tx.get(songRef);

      if (!songSnap.exists) return;

      VoteType previousVote = VoteType.none;
      if (voteSnap.exists) {
        previousVote = VoteType.values.byName(
          voteSnap.data()! as dynamic == null
              ? 'none'
              : (voteSnap.data() as Map<String, dynamic>)['voteType'] as String,
        );
      }

      // No change needed
      if (previousVote == newVoteType) {
        newVoteType = VoteType.none; // toggle off
      }

      int upvoteDelta = 0;
      int downvoteDelta = 0;

      // Undo previous vote
      if (previousVote == VoteType.up) upvoteDelta -= 1;
      if (previousVote == VoteType.down) downvoteDelta -= 1;

      // Apply new vote
      if (newVoteType == VoteType.up) upvoteDelta += 1;
      if (newVoteType == VoteType.down) downvoteDelta += 1;

      if (newVoteType == VoteType.none) {
        tx.delete(voteRef);
      } else {
        final vote = VoteModel(
          id: voteId,
          userId: userId,
          songId: songId,
          voteType: newVoteType,
          votedAt: DateTime.now(),
        );
        tx.set(voteRef, vote.toFirestore());
      }

      tx.update(songRef, {
        'upvotes': FieldValue.increment(upvoteDelta),
        'downvotes': FieldValue.increment(downvoteDelta),
      });
    });
  }

  Future<VoteModel?> getUserVote(
    String roomId,
    String userId,
    String songId,
  ) async {
    final doc = await _votesRef(roomId)
        .doc(VoteModel.makeId(userId, songId))
        .get();
    if (!doc.exists) return null;
    return VoteModel.fromFirestore(doc);
  }

  Stream<Map<String, VoteType>> watchUserVotesForRoom(
    String roomId,
    String userId,
  ) {
    return _votesRef(roomId)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
      return {
        for (final doc in snap.docs)
          (doc.data() as Map<String, dynamic>)['songId'] as String:
              VoteType.values.byName(
            (doc.data() as Map<String, dynamic>)['voteType'] as String,
          ),
      };
    });
  }
}
