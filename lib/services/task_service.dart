import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task.dart';
import '../services/friend_service.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'tasks';

  // Create a new task
  Future<void> createTask(Task task) async {
    try {
      await _firestore.collection(_collection).doc(task.id).set(task.toMap());
    } catch (e) {
      throw Exception('Failed to create task: ${e.toString()}');
    }
  }

  // Get all tasks for a user
  Stream<List<Task>> getTasks(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Task.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    });
  }

  // Update task completion status
  Future<void> updateTaskStatus(String taskId, bool isCompleted) async {
    try {
      print('Updating task status - taskId: $taskId, isCompleted: $isCompleted');
      
      final taskDoc = await _firestore.collection(_collection).doc(taskId).get();
      if (!taskDoc.exists) throw Exception('Task not found');

      final task = Task.fromMap({...taskDoc.data()!, 'id': taskDoc.id});
      
      // Calculate points based on final difficulty if voting is closed
      int points = 0;
      if (isCompleted && task.votingClosed) {
        points = Task.calculatePoints(task.finalDifficulty);
        print('Calculated points for completed task: $points (difficulty: ${task.finalDifficulty})');
      }
      
      // Create a batch for atomic updates
      final batch = _firestore.batch();
      final taskRef = _firestore.collection(_collection).doc(taskId);
      
      // Update the task
      batch.update(taskRef, {
        'isCompleted': isCompleted,
        'completedAt': isCompleted ? FieldValue.serverTimestamp() : null,
        'points': points,
      });
      
      // If task is completed and has points, update user's total points
      if (isCompleted && points > 0) {
        final userRef = _firestore.collection('users').doc(task.userId);
        batch.update(userRef, {
          'totalPoints': FieldValue.increment(points),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
        print('Updating user points: +$points');
      }
      
      // Commit all updates atomically
      await batch.commit();
      print('Task status update successful');
    } catch (e) {
      print('Error updating task status: $e');
      throw e;
    }
  }

  // Delete a task
  Future<void> deleteTask(String taskId) async {
    try {
      await _firestore.collection(_collection).doc(taskId).delete();
    } catch (e) {
      throw Exception('Failed to delete task: ${e.toString()}');
    }
  }

  // Add vote to task
  Future<void> addVoteToTask(String taskId, TaskVote vote) async {
    try {
      final taskDoc = await _firestore.collection('tasks').doc(taskId).get();
      if (!taskDoc.exists) throw Exception('Task not found');

      final task = Task.fromMap({...taskDoc.data()!, 'id': taskDoc.id});
      
      // Check if user has already voted
      if (task.votes.any((v) => v.voterId == vote.voterId)) {
        throw Exception('You have already voted on this task');
      }
      
      final updatedVotes = [...task.votes, vote];
      
      // Get friend count for task owner
      final friendService = FriendService();
      final friendCount = (await friendService.getFriends(task.userId).first).length;
      final requiredVotes = friendCount > 0 ? friendCount : 1;  // If no friends, only need 1 vote
      
      print('Friend count: $friendCount, Required votes: $requiredVotes, Current votes: ${updatedVotes.length}');
      
      // Create a batch to update both task and user documents
      final batch = _firestore.batch();
      final taskRef = _firestore.collection('tasks').doc(taskId);
      
      // If we have enough votes, calculate final difficulty and points
      if (updatedVotes.length >= requiredVotes) {
        // Count votes for each difficulty
        Map<String, int> voteCounts = {
          'easy': 0,
          'medium': 0,
          'hard': 0,
        };
        
        for (var v in updatedVotes) {
          voteCounts[v.difficulty.toLowerCase()] = 
              (voteCounts[v.difficulty.toLowerCase()] ?? 0) + 1;
        }
        
        // Find the difficulty with the most votes
        String finalDifficulty = voteCounts.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;
            
        // Calculate points based on difficulty
        int points = 0;
        if (task.isCompleted) {
          switch (finalDifficulty) {
            case 'easy':
              points = 10;
              break;
            case 'medium':
              points = 20;
              break;
            case 'hard':
              points = 30;
              break;
          }
        }
        
        print('Final difficulty: $finalDifficulty, Points: $points');
        
        // Calculate potential points based on difficulty (even if not completed yet)
        int potentialPoints = 0;
        switch (finalDifficulty) {
          case 'easy':
            potentialPoints = 10;
            break;
          case 'medium':
            potentialPoints = 20;
            break;
          case 'hard':
            potentialPoints = 30;
            break;
        }
        
        batch.update(taskRef, {
          'votes': updatedVotes.map((v) => v.toMap()).toList(),
          'finalDifficulty': finalDifficulty,
          'votingClosed': true,
          'points': task.isCompleted ? points : potentialPoints,
        });
        
        // If task is completed, update user's points
        if (task.isCompleted && points > 0) {
          final userRef = _firestore.collection('users').doc(task.userId);
          batch.update(userRef, {
            'totalPoints': FieldValue.increment(points),
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }
        
        print('Voting closed with final difficulty: $finalDifficulty, points: $points, potential points: $potentialPoints');
      } else {
        batch.update(taskRef, {
          'votes': updatedVotes.map((v) => v.toMap()).toList(),
        });
        print('Vote added, waiting for more votes');
      }
      
      // Commit all updates atomically
      await batch.commit();
    } catch (e) {
      print('Error adding vote to task: $e');
      throw e;
    }
  }
} 