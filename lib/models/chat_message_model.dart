import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, songAdded, userJoined, userLeft }

class ChatMessageModel {
  final String id;
  final String roomId;
  final String senderUid;
  final String senderName;
  final String? senderPhotoUrl;
  final String content;
  final MessageType type;
  final DateTime sentAt;
  final String? linkedSongId; // set when type is songAdded

  const ChatMessageModel({
    required this.id,
    required this.roomId,
    required this.senderUid,
    required this.senderName,
    this.senderPhotoUrl,
    required this.content,
    this.type = MessageType.text,
    required this.sentAt,
    this.linkedSongId,
  });

  bool get isSystemMessage =>
      type == MessageType.userJoined || type == MessageType.userLeft;

  factory ChatMessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessageModel(
      id: doc.id,
      roomId: data['roomId'] as String,
      senderUid: data['senderUid'] as String,
      senderName: data['senderName'] as String,
      senderPhotoUrl: data['senderPhotoUrl'] as String?,
      content: data['content'] as String,
      type: MessageType.values.byName(data['type'] as String? ?? 'text'),
      sentAt: (data['sentAt'] as Timestamp).toDate(),
      linkedSongId: data['linkedSongId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'roomId': roomId,
      'senderUid': senderUid,
      'senderName': senderName,
      'senderPhotoUrl': senderPhotoUrl,
      'content': content,
      'type': type.name,
      'sentAt': Timestamp.fromDate(sentAt),
      'linkedSongId': linkedSongId,
    };
  }
}
