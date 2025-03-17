import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/friend_service.dart';
import '../services/auth_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  _LeaderboardScreenState createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final FriendService _friendService = FriendService();
  final AuthService _authService = AuthService();

  Stream<List<UserProfile>> _getLeaderboardData() {
    final currentUserId = _authService.getCurrentUser()?.uid;
    if (currentUserId == null) return Stream.value([]);

    return _friendService.getFriends(currentUserId).asyncMap((friends) async {
      final currentUser = await _friendService.getUserProfile(currentUserId);
      if (currentUser == null) return [];
      
      final allUsers = [...friends, currentUser];
      allUsers.sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
      
      return allUsers;
    });
  }

  Widget _buildRankBadge(int rank) {
    Color color;
    IconData icon;

    switch (rank) {
      case 1:
        color = Colors.amber;
        icon = Icons.emoji_events;
        break;
      case 2:
        color = Colors.grey[400]!;
        icon = Icons.emoji_events;
        break;
      case 3:
        color = Colors.brown[300]!;
        icon = Icons.emoji_events;
        break;
      default:
        return CircleAvatar(
          radius: 16,
          backgroundColor: Colors.grey[200],
          child: Text(
            rank.toString(),
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
    }

    return Icon(
      icon,
      color: color,
      size: 32,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Leaderboard',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<List<UserProfile>>(
        stream: _getLeaderboardData(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!;
          if (users.isEmpty) {
            return const Center(child: Text('No users found'));
          }

          final currentUserId = _authService.getCurrentUser()?.uid;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final rank = index + 1;
              final isCurrentUser = user.id == currentUserId;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: _buildRankBadge(rank),
                  title: Row(
                    children: [
                      Text(
                        user.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      if (isCurrentUser) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'You',
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${user.totalPoints} pts',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
} 