import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../models/friend_request.dart';
import '../models/task.dart';
import '../services/friend_service.dart';
import '../services/auth_service.dart';
import '../services/task_service.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({Key? key}) : super(key: key);

  @override
  _FriendsScreenState createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> with SingleTickerProviderStateMixin {
  final FriendService _friendService = FriendService();
  final AuthService _authService = AuthService();
  final TaskService _taskService = TaskService();
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  List<UserProfile> _searchResults = [];
  bool _isSearching = false;
  bool _showSearchResults = false;
  String? _expandedFriendId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _createUserProfileIfNeeded();
  }

  Future<void> _createUserProfileIfNeeded() async {
    try {
      await _authService.createProfileForExistingUser();
    } catch (e) {
      print('Error ensuring user profile exists: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _showSearchResults = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _showSearchResults = true;
    });
    
    final results = await _friendService.searchUsers(query);
    
    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'Search for friends by email or name',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Enter email or name...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _searchUsers('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            onChanged: (value) {
              if (value.length >= 3) {
                _searchUsers(value);
              } else {
                setState(() {
                  _showSearchResults = false;
                  _searchResults = [];
                });
              }
            },
          ),
          if (_isSearching)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (!_showSearchResults && !_isSearching && _searchController.text.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.people_outline, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'Start typing to search for friends',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_showSearchResults && _searchResults.isEmpty && !_isSearching && _searchController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'No users found for "${_searchController.text}"',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFriendsList() {
    final currentUserId = _authService.getCurrentUser()?.uid;
    if (currentUserId == null) return const Center(child: Text('Please log in'));

    return StreamBuilder<List<UserProfile>>(
      stream: _friendService.getFriends(currentUserId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final friends = snapshot.data!;
        if (friends.isEmpty) {
          return const Center(child: Text('No friends yet'));
        }

        return ListView.builder(
          itemCount: friends.length,
          itemBuilder: (context, index) {
            final friend = friends[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      child: Text(friend.displayName[0].toUpperCase()),
                    ),
                    title: Text(
                      friend.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text('Points: ${friend.totalPoints}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () {
                            // TODO: Implement remove friend functionality
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.expand_more),
                          onPressed: () {
                            setState(() {
                              if (_expandedFriendId == friend.id) {
                                _expandedFriendId = null;
                              } else {
                                _expandedFriendId = friend.id;
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  if (_expandedFriendId == friend.id)
                    StreamBuilder<List<Task>>(
                      stream: _taskService.getTasks(friend.id),
                      builder: (context, taskSnapshot) {
                        if (taskSnapshot.hasError) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('Error loading tasks'),
                          );
                        }

                        if (!taskSnapshot.hasData) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          );
                        }

                        final tasks = taskSnapshot.data!
                            .where((task) => task.isPublic)
                            .toList();

                        if (tasks.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('No tasks available'),
                          );
                        }

                        return Column(
                          children: tasks.map((task) => Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        task.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: task.isCompleted
                                            ? Colors.green.withOpacity(0.1)
                                            : task.votingClosed
                                                ? Colors.orange.withOpacity(0.1)
                                                : Colors.blue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        task.isCompleted
                                            ? 'Completed (${task.points} pts)'
                                            : task.votingClosed
                                                ? 'Voting Closed - ${task.finalDifficulty.isEmpty ? 'Pending' : task.finalDifficulty[0].toUpperCase() + task.finalDifficulty.substring(1)} (${task.points} pts)'
                                                : 'Open for Voting',
                                        style: TextStyle(
                                          color: task.isCompleted
                                              ? Colors.green
                                              : task.votingClosed
                                                  ? Colors.orange
                                                  : Colors.blue,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (task.description.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    task.description,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Text(
                                  task.isWeeklyTask ? 'Weekly Task' : 'Daily Task',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (!task.votingClosed) _buildVotingButtons(task),
                                if (task.votingClosed && task.finalDifficulty.isNotEmpty) Text(
                                  'Final Difficulty: ${task.finalDifficulty}',
                                  style: TextStyle(
                                    color: _getDifficultyColor(task.finalDifficulty),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          )).toList(),
                        );
                      },
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFriendRequests() {
    final currentUserId = _authService.getCurrentUser()?.uid;
    if (currentUserId == null) return const Center(child: Text('Please log in'));

    return StreamBuilder<List<FriendRequest>>(
      stream: _friendService.getFriendRequests(currentUserId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final requests = snapshot.data!;
        if (requests.isEmpty) {
          return const Center(child: Text('No friend requests'));
        }

        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return FutureBuilder<UserProfile?>(
              future: _friendService.getUserProfile(request.senderId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const ListTile(
                    title: Text('Loading...'),
                  );
                }

                final sender = snapshot.data!;
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(sender.displayName[0].toUpperCase()),
                  ),
                  title: Text(sender.displayName),
                  subtitle: Text('Sent: ${request.createdAt.toString()}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () async {
                          await _friendService.acceptFriendRequest(
                            request.id,
                            currentUserId,
                            request.senderId,
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          // TODO: Implement reject friend request
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSearchResults() {
    final currentUserId = _authService.getCurrentUser()?.uid;
    if (currentUserId == null) return const SizedBox.shrink();

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No users found',
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        if (user.id == currentUserId) return const SizedBox.shrink();

        final bool isPending = user.pendingFriendRequests.contains(currentUserId);
        final bool isFriend = user.friends.contains(currentUserId);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: CircleAvatar(
              child: Text(user.displayName[0].toUpperCase()),
            ),
            title: Text(user.displayName),
            subtitle: Text(user.email),
            trailing: isFriend
                ? const Chip(
                    label: Text('Friend'),
                    backgroundColor: Colors.green,
                    labelStyle: TextStyle(color: Colors.white),
                  )
                : isPending
                    ? const Chip(
                        label: Text('Pending'),
                        backgroundColor: Colors.orange,
                        labelStyle: TextStyle(color: Colors.white),
                      )
                    : ElevatedButton(
                        onPressed: () async {
                          try {
                            await _friendService.sendFriendRequest(
                              currentUserId,
                              user.id,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Friend request sent to ${user.displayName}',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: ${e.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Add Friend'),
                      ),
          ),
        );
      },
    );
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

    // If voting is closed, show the final result
    if (task.votingClosed) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _getDifficultyColor(task.finalDifficulty).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _getDifficultyColor(task.finalDifficulty).withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 18,
              color: _getDifficultyColor(task.finalDifficulty),
            ),
            const SizedBox(width: 8),
            Text(
              'Final Difficulty: ${task.finalDifficulty[0].toUpperCase() + task.finalDifficulty.substring(1)}',
              style: TextStyle(
                color: _getDifficultyColor(task.finalDifficulty),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    // If user has voted but voting is still open
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
              'You voted ${userVote.difficulty[0].toUpperCase() + userVote.difficulty.substring(1)}',
              style: TextStyle(
                color: _getDifficultyColor(userVote.difficulty),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    // If user hasn't voted and voting is still open
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Friends',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey[600],
          tabs: const [
            Tab(text: 'Friends'),
            Tab(text: 'Requests'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          if (_showSearchResults)
            Expanded(child: _buildSearchResults())
          else
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildFriendsList(),
                  _buildFriendRequests(),
                ],
              ),
            ),
        ],
      ),
    );
  }
} 