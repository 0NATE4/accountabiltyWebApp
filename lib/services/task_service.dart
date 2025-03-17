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
      
      // Create a batch to update both task and user documents
      final batch = _firestore.batch();
      final taskRef = _firestore.collection('tasks').doc(taskId);
      
      // Calculate final difficulty and points after one vote
      String finalDifficulty = vote.difficulty.toLowerCase();
      int potentialPoints = Task.calculatePoints(finalDifficulty);
      
      print('Final difficulty: $finalDifficulty, Potential points: $potentialPoints');
      
      batch.update(taskRef, {
        'votes': updatedVotes.map((v) => v.toMap()).toList(),
        'finalDifficulty': finalDifficulty,
        'votingClosed': true,
        'points': task.isCompleted ? potentialPoints : potentialPoints,
      });
      
      // If task is completed, update user's points
      if (task.isCompleted && potentialPoints > 0) {
        final userRef = _firestore.collection('users').doc(task.userId);
        batch.update(userRef, {
          'totalPoints': FieldValue.increment(potentialPoints),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
      
      print('Voting closed with final difficulty: $finalDifficulty, points: $potentialPoints');
      
      // Commit all updates atomically
      await batch.commit();
    } catch (e) {
      print('Error adding vote to task: $e');
      throw e;
    }
  }

  // Close voting and accept current difficulty
  Future<void> acceptCurrentDifficulty(String taskId) async {
    try {
      final taskDoc = await _firestore.collection('tasks').doc(taskId).get();
      if (!taskDoc.exists) throw Exception('Task not found');

      final task = Task.fromMap({...taskDoc.data()!, 'id': taskDoc.id});
      
      if (task.votes.isEmpty) {
        throw Exception('No votes available to accept');
      }

      // Calculate final difficulty based on current votes
      String finalDifficulty = task.calculateFinalDifficulty();
      int potentialPoints = Task.calculatePoints(finalDifficulty);
      
      // Create a batch to update task
      final batch = _firestore.batch();
      final taskRef = _firestore.collection('tasks').doc(taskId);
      
      batch.update(taskRef, {
        'finalDifficulty': finalDifficulty,
        'votingClosed': true,
        'points': task.isCompleted ? potentialPoints : potentialPoints,
      });
      
      // If task is completed, update user's points
      if (task.isCompleted && potentialPoints > 0) {
        final userRef = _firestore.collection('users').doc(task.userId);
        batch.update(userRef, {
          'totalPoints': FieldValue.increment(potentialPoints),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
    } catch (e) {
      print('Error accepting current difficulty: $e');
      throw e;
    }
  }
} 