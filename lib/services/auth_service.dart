import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      print('Attempting to sign in with email: $email');
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Sign in error: $e');
      throw Exception('Failed to sign in: ${e.toString()}');
    }
  }

  // Register with email and password
  Future<UserCredential> registerWithEmailAndPassword(
      String email, String password) async {
    try {
      print('Attempting to register with email: $email');
      print('Firebase Auth instance available: ${_auth != null}');
      print('Current initialization options: ${_auth.app.options.asMap}');
      
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('Registration successful for user: ${result.user?.uid}');
      return result;
    } catch (e) {
      print('Registration error: $e');
      throw Exception('Failed to register: ${e.toString()}');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Sign out error: $e');
      throw Exception('Failed to sign out: ${e.toString()}');
    }
  }
} 