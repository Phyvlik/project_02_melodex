import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../utils/constants.dart';

// Top-level handler required by FCM for background messages
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background messages are handled by the OS notification tray
}

class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> initialize(String userId) async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized) return;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final token = await _messaging.getToken();
    if (token != null) {
      await _saveTokenToFirestore(userId, token);
    }

    // Refresh token when FCM rotates it
    _messaging.onTokenRefresh.listen((newToken) {
      _saveTokenToFirestore(userId, newToken);
    });

    // Foreground message handler
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification != null) {
        Fluttertoast.showToast(
          msg: '${notification.title}: ${notification.body}',
          toastLength: Toast.LENGTH_SHORT,
        );
      }
    });
  }

  Future<void> _saveTokenToFirestore(String userId, String token) async {
    await _db
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .update({'fcmToken': token});
  }

  Future<void> subscribeToRoom(String roomId) async {
    await _messaging.subscribeToTopic('room_$roomId');
  }

  Future<void> unsubscribeFromRoom(String roomId) async {
    await _messaging.unsubscribeFromTopic('room_$roomId');
  }
}
