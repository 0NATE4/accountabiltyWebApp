import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';
import '../models/friend_request.dart';

class FriendService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user profile
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserProfile.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Create or update user profile
  Future<void> updateUserProfile(UserProfile profile) async {
    try {
      await _firestore.collection('users').doc(profile.id).set(profile.toMap());
    } catch (e) {
      print('Error updating user profile: $e');
      throw e;
    }
  }

  // Send friend request
  Future<void> sendFriendRequest(String senderId, String receiverId) async {
    try {
      final request = FriendRequest(
        id: '${senderId}_${receiverId}',
        senderId: senderId,
        receiverId: receiverId,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('friendRequests').doc(request.id).set(request.toMap());

      // Update receiver's pending requests
      final receiverProfile = await getUserProfile(receiverId);
      if (receiverProfile != null) {
        final updatedProfile = receiverProfile.copyWith(
          pendingFriendRequests: [...receiverProfile.pendingFriendRequests, senderId],
        );
        await updateUserProfile(updatedProfile);
      }
    } catch (e) {
      print('Error sending friend request: $e');
      throw e;
    }
  }

  // Accept friend request
  Future<void> acceptFriendRequest(String requestId, String userId, String friendId) async {
    try {
      // Update request status
      await _firestore.collection('friendRequests').doc(requestId).update({
        'status': FriendRequestStatus.accepted.toString(),
      });

      // Update both users' friends lists
      final userProfile = await getUserProfile(userId);
      final friendProfile = await getUserProfile(friendId);

      if (userProfile != null && friendProfile != null) {
        // Update user's profile
        final updatedUserProfile = userProfile.copyWith(
          friends: [...userProfile.friends, friendId],
          pendingFriendRequests: userProfile.pendingFriendRequests
              .where((id) => id != friendId)
              .toList(),
        );
        await updateUserProfile(updatedUserProfile);

        // Update friend's profile
        final updatedFriendProfile = friendProfile.copyWith(
          friends: [...friendProfile.friends, userId],
        );
        await updateUserProfile(updatedFriendProfile);
      }
    } catch (e) {
      print('Error accepting friend request: $e');
      throw e;
    }
  }

  // Get friend requests
  Stream<List<FriendRequest>> getFriendRequests(String userId) {
    return _firestore
        .collection('friendRequests')
        .where('receiverId', isEqualTo: userId)
        .where('status', isEqualTo: FriendRequestStatus.pending.toString())
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FriendRequest.fromMap(doc.data()))
            .toList());
  }

  // Get friends list with profiles
  Stream<List<UserProfile>> getFriends(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .asyncMap((snapshot) async {
      if (!snapshot.exists) return [];
      
      final userProfile = UserProfile.fromMap(snapshot.data()!);
      final friendProfiles = await Future.wait(
        userProfile.friends.map((friendId) => getUserProfile(friendId)),
      );
      
      return friendProfiles.whereType<UserProfile>().toList();
    });
  }

  // Search users by email or display name
  Future<List<UserProfile>> searchUsers(String query) async {
    try {
      print('Searching users with query: $query');
      final lowercaseQuery = query.toLowerCase();
      
      // Get all users
      final usersSnapshot = await _firestore.collection('users').get();
      
      // Filter users locally for more flexible matching
      final users = usersSnapshot.docs
          .map((doc) => UserProfile.fromMap(doc.data()))
          .where((user) {
            final lowercaseEmail = user.email.toLowerCase();
            final lowercaseDisplayName = user.displayName.toLowerCase();
            
            return lowercaseEmail.contains(lowercaseQuery) ||
                   lowercaseDisplayName.contains(lowercaseQuery);
          })
          .toList();

      print('Found ${users.length} matching users');
      return users;
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }
} 