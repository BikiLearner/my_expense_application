import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

class SessionManager {
  SessionManager._();

  static final SessionManager instance = SessionManager._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? _user;
  StreamSubscription<User?>? _subscription;

  /// Call once after Firebase.initializeApp()
  Future<void> initialize() async {
    _user = _auth.currentUser;

    _subscription ??= _auth.authStateChanges().listen((user) {
      _user = user;
    });
  }

  User? get user => _user;

  String? get uid => _user?.uid;

  bool get isLoggedIn => _user != null;

  bool get isEmailVerified => _user?.emailVerified ?? false;

  String? get email => _user?.email;

  String? get phoneNumber => _user?.phoneNumber;

  String? get displayName => _user?.displayName;

  String? get photoUrl => _user?.photoURL;

  Future<void> refreshUser() async {
    await _user?.reload();
    _user = _auth.currentUser;
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}