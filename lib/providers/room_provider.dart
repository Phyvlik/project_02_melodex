import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/room_model.dart';
import '../models/user_model.dart';
import '../services/room_service.dart';
import '../services/fcm_service.dart';
import '../services/chat_service.dart';
import '../models/chat_message_model.dart';

class RoomProvider extends ChangeNotifier {
  final RoomService _roomService = RoomService();
  final FCMService _fcmService = FCMService();
  final ChatService _chatService = ChatService();

  RoomModel? _currentRoom;
  List<RoomModel> _userRooms = [];
  bool _isLoading = false;
  String? _errorMessage;

  StreamSubscription<RoomModel?>? _roomSub;
  StreamSubscription<List<RoomModel>>? _userRoomsSub;

  RoomModel? get currentRoom => _currentRoom;
  List<RoomModel> get userRooms => _userRooms;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isInRoom => _currentRoom != null;

  void watchUserRooms(String userId) {
    _userRoomsSub?.cancel();
    _userRoomsSub = _roomService.watchUserRooms(userId).listen((rooms) {
      _userRooms = rooms;
      notifyListeners();
    });
  }

  Future<bool> createRoom({
    required String hostUid,
    required String hostName,
    required String name,
    required List<String> preferredGenres,
    required String currentMood,
  }) async {
    _setLoading(true);
    try {
      final room = await _roomService.createRoom(
        hostUid: hostUid,
        name: name,
        preferredGenres: preferredGenres,
        currentMood: currentMood,
      );
      await _enterRoom(room, hostUid, hostName);
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> joinRoom(String code, UserModel user) async {
    _setLoading(true);
    try {
      final room = await _roomService.joinRoomByCode(code, user.uid);
      if (room == null) {
        _errorMessage = 'Room not found. Check the invite code and try again.';
        return false;
      }
      await _enterRoom(room, user.uid, user.displayName);
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _enterRoom(RoomModel room, String uid, String displayName) async {
    _currentRoom = room;
    _roomSub?.cancel();
    _roomSub = _roomService.watchRoom(room.id).listen((updated) {
      if (updated != null) {
        _currentRoom = updated;
        notifyListeners();
      }
    });

    await _fcmService.subscribeToRoom(room.id);
    await _chatService.postSystemMessage(
      roomId: room.id,
      content: '$displayName joined the room',
      type: MessageType.userJoined,
    );
    notifyListeners();
  }

  Future<void> leaveRoom(UserModel user) async {
    if (_currentRoom == null) return;
    final roomId = _currentRoom!.id;

    await _chatService.postSystemMessage(
      roomId: roomId,
      content: '${user.displayName} left the room',
      type: MessageType.userLeft,
    );
    await _roomService.leaveRoom(roomId, user.uid);
    await _fcmService.unsubscribeFromRoom(roomId);

    _roomSub?.cancel();
    _currentRoom = null;
    notifyListeners();
  }

  Future<void> updateMood(String mood) async {
    if (_currentRoom == null) return;
    await _roomService.updateRoomMood(_currentRoom!.id, mood);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _roomSub?.cancel();
    _userRoomsSub?.cancel();
    super.dispose();
  }
}
