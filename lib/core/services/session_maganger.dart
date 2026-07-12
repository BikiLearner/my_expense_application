import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SessionManager {
  SessionManager._();

  static final SessionManager instance = SessionManager._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  DocumentReference<Map<String, dynamic>>? _userRef;
  StreamSubscription<User?>? _subscription;

  /// Call once after Firebase.initializeApp()
  Future<void> initialize() async {
    _setUser(_auth.currentUser);

    _subscription ??= _auth.authStateChanges().listen(_setUser);
  }

  void _setUser(User? user) {
    _user = user;

    _userRef = user == null
        ? null
        : _firestore.collection('users').doc(user.uid);
  }

  User? get user => _user;

  String? get uid => _user?.uid;

  /// Use this when the user must be logged in.
  String get requireUid {
    if (_user == null) {
      throw StateError('User is not logged in.');
    }
    return _user!.uid;
  }

  /// Cached reference to /users/{uid}
  DocumentReference<Map<String, dynamic>> get userRef {
    if (_userRef == null) {
      throw StateError('User is not logged in.');
    }
    return _userRef!;
  }

  bool get isLoggedIn => _user != null;

  bool get isEmailVerified => _user?.emailVerified ?? false;

  String? get email => _user?.email;

  String? get phoneNumber => _user?.phoneNumber;

  String? get displayName => _user?.displayName;

  String? get photoUrl => _user?.photoURL;

  Future<void> refreshUser() async {
    await _user?.reload();
    _setUser(_auth.currentUser);
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}