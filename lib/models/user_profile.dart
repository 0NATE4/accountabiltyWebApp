import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String id;
  final String email;
  final String displayName;
  final int totalPoints;
  final List<String> friends;
  final List<String> pendingFriendRequests;
  final DateTime lastActive;

  UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    this.totalPoints = 0,
    this.friends = const [],
    this.pendingFriendRequests = const [],
    required this.lastActive,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'totalPoints': totalPoints,
      'friends': friends,
      'pendingFriendRequests': pendingFriendRequests,
      'lastActive': lastActive,
    };
  }

  static UserProfile fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'],
      email: map['email'],
      displayName: map['displayName'],
      totalPoints: map['totalPoints'] ?? 0,
      friends: List<String>.from(map['friends'] ?? []),
      pendingFriendRequests: List<String>.from(map['pendingFriendRequests'] ?? []),
      lastActive: (map['lastActive'] as Timestamp).toDate(),
    );
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? displayName,
    int? totalPoints,
    List<String>? friends,
    List<String>? pendingFriendRequests,
    DateTime? lastActive,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      totalPoints: totalPoints ?? this.totalPoints,
      friends: friends ?? this.friends,
      pendingFriendRequests: pendingFriendRequests ?? this.pendingFriendRequests,
      lastActive: lastActive ?? this.lastActive,
    );
  }
} 