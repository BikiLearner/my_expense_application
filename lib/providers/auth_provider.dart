import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 🔹 Controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool _loading = false;
  bool get loading => _loading;

  User? get currentUser => _auth.currentUser;

  // Listen to auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  // 🔹 Login
  Future<void> login(BuildContext context) async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    // Validation
    if (email.isEmpty || password.isEmpty) {
      _showError(context, "Please fill in all fields");
      return;
    }

    if (!_isValidEmail(email)) {
      _showError(context, "Please enter a valid email");
      return;
    }

    try {
      _setLoading(true);
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      // Clear controllers after successful login
      emailController.clear();
      passwordController.clear();

      // Show success message
      if (context.mounted) {
        _showSuccess(context, "Welcome back!");
      }
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        _showError(context, _getAuthErrorMessage(e.code));
      }
    } catch (e) {
      if (context.mounted) {
        _showError(context, "Login failed. Please try again.");
      }
    } finally {
      _setLoading(false);
    }
  }

  // 🔹 Register
  Future<void> register(BuildContext context) async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    // Validation
    if (email.isEmpty || password.isEmpty) {
      _showError(context, "Please fill in all fields");
      return;
    }

    if (!_isValidEmail(email)) {
      _showError(context, "Please enter a valid email");
      return;
    }

    if (password.length < 6) {
      _showError(context, "Password must be at least 6 characters");
      return;
    }

    try {
      _setLoading(true);
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Clear controllers after successful registration
      emailController.clear();
      passwordController.clear();

      // Show success message and navigate
      if (context.mounted) {
        _showSuccess(context, "Account created successfully!");
        // Pop the register screen to go back to login/expense screen
        Navigator.of(context).pop();
      }
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        _showError(context, _getAuthErrorMessage(e.code));
      }
    } catch (e) {
      if (context.mounted) {
        _showError(context, "Registration failed. Please try again.");
      }
    } finally {
      _setLoading(false);
    }
  }

  // 🔹 Logout
  Future<void> logout() async {
    try {
      await _auth.signOut();
      emailController.clear();
      passwordController.clear();
      notifyListeners();
    } catch (e) {
      debugPrint("Logout error: $e");
    }
  }

  // 🔹 Email Validation
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  // 🔹 Get user-friendly error messages
  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'invalid-email':
        return 'Invalid email address';
      case 'weak-password':
        return 'Password is too weak';
      case 'network-request-failed':
        return 'Network error. Please check your connection';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'invalid-credential':
        return 'Invalid email or password';
      default:
        return 'Authentication failed. Please try again';
    }
  }

  // 🔹 Show Error Message
  void _showError(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(msg, style: const TextStyle(fontSize: 14))),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // 🔹 Show Success Message
  void _showSuccess(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(msg, style: const TextStyle(fontSize: 14))),
          ],
        ),
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
