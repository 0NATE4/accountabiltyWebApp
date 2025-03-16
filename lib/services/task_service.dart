import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task.dart';

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
      print('Updating task $taskId in Firestore - isCompleted: $isCompleted');
      
      // First get the current task to ensure we have the correct points
      final taskDoc = await _firestore.collection(_collection).doc(taskId).get();
      final currentTask = Task.fromMap({...taskDoc.data()!, 'id': taskDoc.id});
      print('Current task points: ${currentTask.points}');
      
      final updateData = {
        'isCompleted': isCompleted,
        'completedAt': isCompleted ? DateTime.now().toIso8601String() : null,
        'points': currentTask.points, // Ensure points are included in the update
      };
      print('Update data: $updateData');
      
      await _firestore
          .collection(_collection)
          .doc(taskId)
          .update(updateData);
      
      print('Task update successful');
    } catch (e) {
      print('Error updating task: $e');
      throw Exception('Failed to update task status: ${e.toString()}');
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
} 