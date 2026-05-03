import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/room_model.dart';
import '../utils/constants.dart';

class RoomService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = List.generate(
      AppConstants.inviteCodeLength,
      (i) => chars[DateTime.now().microsecondsSinceEpoch * (i + 1) % chars.length],
    );
    return random.join();
  }

  Future<RoomModel> createRoom({
    required String hostUid,
    required String name,
    required List<String> preferredGenres,
    required String currentMood,
  }) async {
    final code = _generateInviteCode();
    final docRef = _db.collection(AppConstants.roomsCollection).doc();

    final room = RoomModel(
      id: docRef.id,
      name: name,
      inviteCode: code,
      hostUid: hostUid,
      memberUids: [hostUid],
      preferredGenres: preferredGenres,
      currentMood: currentMood,
      createdAt: DateTime.now(),
    );

    await docRef.set(room.toFirestore());

    // Add room to host's roomIds list
    await _db
        .collection(AppConstants.usersCollection)
        .doc(hostUid)
        .update({'roomIds': FieldValue.arrayUnion([docRef.id])});

    return room;
  }

  Future<RoomModel?> joinRoomByCode(String code, String userId) async {
    final query = await _db
        .collection(AppConstants.roomsCollection)
        .where('inviteCode', isEqualTo: code.toUpperCase())
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;

    final doc = query.docs.first;
    final room = RoomModel.fromFirestore(doc);

    if (room.memberUids.contains(userId)) return room;

    if (room.memberCount >= AppConstants.maxRoomMembers) {
      throw Exception('Room is full (max ${AppConstants.maxRoomMembers} members)');
    }

    await _db.runTransaction((tx) async {
      tx.update(doc.reference, {
        'memberUids': FieldValue.arrayUnion([userId]),
      });
      tx.update(
        _db.collection(AppConstants.usersCollection).doc(userId),
        {'roomIds': FieldValue.arrayUnion([doc.id])},
      );
    });

    return RoomModel.fromFirestore(await doc.reference.get());
  }

  Future<void> leaveRoom(String roomId, String userId) async {
    await _db.runTransaction((tx) async {
      tx.update(
        _db.collection(AppConstants.roomsCollection).doc(roomId),
        {'memberUids': FieldValue.arrayRemove([userId])},
      );
      tx.update(
        _db.collection(AppConstants.usersCollection).doc(userId),
        {'roomIds': FieldValue.arrayRemove([roomId])},
      );
    });
  }

  Future<void> closeRoom(String roomId) async {
    await _db
        .collection(AppConstants.roomsCollection)
        .doc(roomId)
        .update({'isActive': false});
  }

  Future<void> updateRoomMood(String roomId, String mood) async {
    await _db
        .collection(AppConstants.roomsCollection)
        .doc(roomId)
        .update({'currentMood': mood});
  }

  Stream<RoomModel?> watchRoom(String roomId) {
    return _db
        .collection(AppConstants.roomsCollection)
        .doc(roomId)
        .snapshots()
        .map((doc) => doc.exists ? RoomModel.fromFirestore(doc) : null);
  }

  Stream<List<RoomModel>> watchUserRooms(String userId) {
    return _db
        .collection(AppConstants.roomsCollection)
        .where('memberUids', arrayContains: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(RoomModel.fromFirestore).toList());
  }
  Future<void> markSongAsPlayed(String roomId, String songId) async {
  await FirebaseFirestore.instance
      .collection('rooms')
      .doc(roomId)
      .collection('songs')
      .doc(songId)
      .update({'isPlayed': true});
}
}
