import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserModel> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await credential.user!.updateDisplayName(displayName);

    final now = DateTime.now();
    final user = UserModel(
      uid: credential.user!.uid,
      email: email,
      displayName: displayName,
      createdAt: now,
      lastActiveAt: now,
    );

    await _db
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .set(user.toFirestore());

    return user;
  }

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    await _db
        .collection(AppConstants.usersCollection)
        .doc(credential.user!.uid)
        .update({'lastActiveAt': Timestamp.now()});

    final doc = await _db
        .collection(AppConstants.usersCollection)
        .doc(credential.user!.uid)
        .get();

    return UserModel.fromFirestore(doc);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> updateFcmToken(String uid, String token) async {
    await _db
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({'fcmToken': token});
  }

  Future<UserModel?> fetchUserProfile(String uid) async {
    final doc = await _db
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .get();

    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Future<void> updateProfilePhoto(String uid, String photoUrl) async {
    await _db
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({'photoUrl': photoUrl});
  }

  Stream<UserModel?> watchUserProfile(String uid) {
    return _db
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }
}
