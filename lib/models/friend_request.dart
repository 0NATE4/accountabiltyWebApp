import 'package:cloud_firestore/cloud_firestore.dart';

enum FriendRequestStatus {
  pending,
  accepted,
  rejected
}

class FriendRequest {
  final String id;
  final String senderId;
  final String receiverId;
  final DateTime createdAt;
  final FriendRequestStatus status;

  FriendRequest({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.createdAt,
    this.status = FriendRequestStatus.pending,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'createdAt': createdAt,
      'status': status.toString(),
    };
  }

  static FriendRequest fromMap(Map<String, dynamic> map) {
    return FriendRequest(
      id: map['id'],
      senderId: map['senderId'],
      receiverId: map['receiverId'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      status: FriendRequestStatus.values.firstWhere(
        (e) => e.toString() == map['status'],
        orElse: () => FriendRequestStatus.pending,
      ),
    );
  }

  FriendRequest copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    DateTime? createdAt,
    FriendRequestStatus? status,
  }) {
    return FriendRequest(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }
} 