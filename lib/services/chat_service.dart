import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message_model.dart';
import '../utils/constants.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference _messagesRef(String roomId) => _db
      .collection(AppConstants.roomsCollection)
      .doc(roomId)
      .collection(AppConstants.messagesCollection);

  Future<ChatMessageModel> sendMessage({
    required String roomId,
    required String senderUid,
    required String senderName,
    String? senderPhotoUrl,
    required String content,
    MessageType type = MessageType.text,
    String? linkedSongId,
  }) async {
    final docRef = _messagesRef(roomId).doc();
    final message = ChatMessageModel(
      id: docRef.id,
      roomId: roomId,
      senderUid: senderUid,
      senderName: senderName,
      senderPhotoUrl: senderPhotoUrl,
      content: content,
      type: type,
      sentAt: DateTime.now(),
      linkedSongId: linkedSongId,
    );
    await docRef.set(message.toFirestore());
    return message;
  }

  Future<void> postSystemMessage({
    required String roomId,
    required String content,
    required MessageType type,
    String? linkedSongId,
  }) async {
    await sendMessage(
      roomId: roomId,
      senderUid: 'system',
      senderName: 'Vibzcheck',
      content: content,
      type: type,
      linkedSongId: linkedSongId,
    );
  }

  Stream<List<ChatMessageModel>> watchMessages(
    String roomId, {
    int limit = 50,
  }) {
    return _messagesRef(roomId)
        .orderBy('sentAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) {
      return snap.docs
          .map(ChatMessageModel.fromFirestore)
          .toList()
          .reversed
          .toList();
    });
  }

  Future<void> deleteMessage(String roomId, String messageId) async {
    await _messagesRef(roomId).doc(messageId).delete();
  }
}
