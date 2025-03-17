import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/user_profile.dart';
import '../services/task_service.dart';
import '../services/friend_service.dart';
import '../services/auth_service.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({Key? key}) : super(key: key);

  @override
  _FeedScreenState createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final TaskService _taskService = TaskService();
  final FriendService _friendService = FriendService();
  final AuthService _authService = AuthService();

  Future<List<Map<String, dynamic>>> _getFriendsTasks() async {
    final currentUserId = _authService.getCurrentUser()?.uid;
    if (currentUserId == null) return [];

    final friends = await _friendService.getFriends(currentUserId).first;
    final allTasks = <Map<String, dynamic>>[];

    for (var friend in friends) {
      final tasks = await _taskService.getTasks(friend.id).first;
      for (var task in tasks) {
        if (task.isPublic && !task.votingClosed) {
          allTasks.add({
            'task': task,
            'user': friend,
          });
        }
      }
    }

    allTasks.sort((a, b) {
      final taskA = a['task'] as Task;
      final taskB = b['task'] as Task;
      return taskB.createdAt.compareTo(taskA.createdAt);
    });

    return allTasks;
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _voteOnTask(Task task, String difficulty) async {
    final currentUserId = _authService.getCurrentUser()?.uid;
    if (currentUserId == null) return;

    try {
      final vote = TaskVote(
        voterId: currentUserId,
        difficulty: difficulty,
        votedAt: DateTime.now(),
      );

      await _taskService.addVoteToTask(task.id, vote);
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Voted ${difficulty[0].toUpperCase() + difficulty.substring(1)} for "${task.title}"'),
            backgroundColor: _getDifficultyColor(difficulty),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error voting: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildVotingButtons(Task task) {
    final currentUserId = _authService.getCurrentUser()?.uid;
    final hasVoted = task.votes.any((vote) => vote.voterId == currentUserId);
    final userVote = task.votes.firstWhere(
      (vote) => vote.voterId == currentUserId,
      orElse: () => TaskVote(
        voterId: '',
        difficulty: '',
        votedAt: DateTime.now(),
      ),
    );

    if (hasVoted) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _getDifficultyColor(userVote.difficulty).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _getDifficultyColor(userVote.difficulty).withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.how_to_vote,
              size: 18,
              color: _getDifficultyColor(userVote.difficulty),
            ),
            const SizedBox(width: 8),
            Text(
              'Voted ${userVote.difficulty[0].toUpperCase() + userVote.difficulty.substring(1)}',
              style: TextStyle(
                color: _getDifficultyColor(userVote.difficulty),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: ['easy', 'medium', 'hard'].map((difficulty) {
        final color = _getDifficultyColor(difficulty);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Tooltip(
            message: 'Vote as $difficulty',
            child: ElevatedButton.icon(
              onPressed: () => _voteOnTask(task, difficulty),
              icon: Icon(
                difficulty == 'easy' ? Icons.sentiment_satisfied_alt :
                difficulty == 'medium' ? Icons.sentiment_neutral :
                Icons.sentiment_very_dissatisfied,
                size: 18,
              ),
              label: Text(
                difficulty[0].toUpperCase() + difficulty.substring(1),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: color.withOpacity(0.1),
                foregroundColor: color,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                side: BorderSide(
                  color: color.withOpacity(0.5),
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Friend Activity',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getFriendsTasks(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final tasks = snapshot.data!;
          if (tasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No friend activity yet',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add friends to see their tasks here',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index]['task'] as Task;
              final user = tasks[index]['user'] as UserProfile;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        child: Text(user.displayName[0].toUpperCase()),
                      ),
                      title: Text(
                        user.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        'Points: ${user.totalPoints}',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (task.description.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              task.description,
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${task.createdAt.year}-${task.createdAt.month.toString().padLeft(2, '0')}-${task.createdAt.day.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Vote on difficulty:',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Center(child: _buildVotingButtons(task)),
                          if (task.votes.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(
                              'Current votes: ${task.votes.length}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
} 