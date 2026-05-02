import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/fcm_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FCMService _fcmService = FCMService();

  UserModel? _user;
  AuthStatus _status = AuthStatus.unknown;
  String? _errorMessage;
  bool _isLoading = false;

  UserModel? get user => _user;
  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  AuthProvider() {
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _user = null;
      _status = AuthStatus.unauthenticated;
    } else {
      _user = await _authService.fetchUserProfile(firebaseUser.uid);
      _status = AuthStatus.authenticated;
      await _fcmService.initialize(firebaseUser.uid);
    }
    notifyListeners();
  }

  Future<bool> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _setLoading(true);
    try {
      _user = await _authService.register(
        email: email,
        password: password,
        displayName: displayName,
      );
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _friendlyAuthError(e.code);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    try {
      _user = await _authService.signIn(email: email, password: password);
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _friendlyAuthError(e.code);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _friendlyAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with that email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
