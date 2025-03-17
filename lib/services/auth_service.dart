import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import 'friend_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FriendService _friendService = FriendService();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get current user method
  User? getCurrentUser() => _auth.currentUser;

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
      
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print('Registration successful for user: ${result.user?.uid}');
      
      // Create user profile in Firestore
      if (result.user != null) {
        final userProfile = UserProfile(
          id: result.user!.uid,
          email: email,
          displayName: email.split('@')[0], // Use part before @ as display name
          lastActive: DateTime.now(),
        );
        
        await _friendService.updateUserProfile(userProfile);
        print('User profile created in Firestore');
      }
      
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

  // Create profile for existing user
  Future<void> createProfileForExistingUser() async {
    final user = currentUser;
    if (user == null) {
      throw Exception('No user is currently signed in');
    }

    try {
      // Check if profile already exists
      final existingProfile = await _friendService.getUserProfile(user.uid);
      if (existingProfile != null) {
        print('User profile already exists');
        return;
      }

      // Create new profile
      final userProfile = UserProfile(
        id: user.uid,
        email: user.email!,
        displayName: user.email!.split('@')[0],
        lastActive: DateTime.now(),
      );
      
      await _friendService.updateUserProfile(userProfile);
      print('Created profile for existing user: ${user.email}');
    } catch (e) {
      print('Error creating profile for existing user: $e');
      throw e;
    }
  }
} 