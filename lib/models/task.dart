import 'package:cloud_firestore/cloud_firestore.dart';

class TaskVote {
  final String voterId;
  final String difficulty;
  final DateTime votedAt;

  TaskVote({
    required this.voterId,
    required this.difficulty,
    required this.votedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'voterId': voterId,
      'difficulty': difficulty,
      'votedAt': Timestamp.fromDate(votedAt),
    };
  }

  static TaskVote fromMap(Map<String, dynamic> map) {
    DateTime parseVotedAt() {
      final votedAt = map['votedAt'];
      if (votedAt is Timestamp) {
        return votedAt.toDate();
      } else if (votedAt is String) {
        return DateTime.parse(votedAt);
      }
      throw Exception('Invalid votedAt format');
    }

    return TaskVote(
      voterId: map['voterId'],
      difficulty: map['difficulty'],
      votedAt: parseVotedAt(),
    );
  }
}

class Task {
  final String id;
  final String title;
  final String description;
  final DateTime createdAt;
  final bool isWeeklyTask;  // true if it's for the whole week, false if it's for today
  bool isCompleted;
  final String userId;
  int points;
  DateTime? completedAt;
  final bool isPublic;
  final List<TaskVote> votes;
  final String finalDifficulty;
  final bool votingClosed;

  Task({
    required this.id,
    required this.title,
    required this.description,
    DateTime? createdAt,
    required this.isWeeklyTask,
    this.isCompleted = false,
    required this.userId,
    this.points = 0,
    this.completedAt,
    this.isPublic = true,
    this.votes = const [],
    this.finalDifficulty = '',
    this.votingClosed = false,
  }) : this.createdAt = createdAt ?? DateTime.now();

  static int calculatePoints(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return 10;
      case 'medium':
        return 20;
      case 'hard':
        return 30;
      default:
        return 10;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'isWeeklyTask': isWeeklyTask,
      'isCompleted': isCompleted,
      'userId': userId,
      'points': points,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'isPublic': isPublic,
      'votes': votes.map((v) => v.toMap()).toList(),
      'finalDifficulty': finalDifficulty,
      'votingClosed': votingClosed,
    };
  }

  static Task fromMap(Map<String, dynamic> map) {
    DateTime parseCreatedAt() {
      final createdAt = map['createdAt'];
      if (createdAt is Timestamp) {
        return createdAt.toDate();
      } else if (createdAt is String) {
        return DateTime.parse(createdAt);
      }
      return DateTime.now();
    }

    DateTime? parseCompletedAt() {
      final completedAt = map['completedAt'];
      if (completedAt == null) return null;
      if (completedAt is Timestamp) {
        return completedAt.toDate();
      } else if (completedAt is String) {
        return DateTime.parse(completedAt);
      }
      return null;
    }

    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      createdAt: parseCreatedAt(),
      isWeeklyTask: map['isWeeklyTask'] ?? false,
      isCompleted: map['isCompleted'] ?? false,
      userId: map['userId'],
      points: map['points'] ?? 0,
      completedAt: parseCompletedAt(),
      isPublic: map['isPublic'] ?? true,
      votes: (map['votes'] as List<dynamic>? ?? [])
          .map((v) => TaskVote.fromMap(v as Map<String, dynamic>))
          .toList(),
      finalDifficulty: map['finalDifficulty'] ?? '',
      votingClosed: map['votingClosed'] ?? false,
    );
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? createdAt,
    bool? isWeeklyTask,
    bool? isCompleted,
    String? userId,
    int? points,
    DateTime? completedAt,
    bool? isPublic,
    List<TaskVote>? votes,
    String? finalDifficulty,
    bool? votingClosed,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      isWeeklyTask: isWeeklyTask ?? this.isWeeklyTask,
      isCompleted: isCompleted ?? this.isCompleted,
      userId: userId ?? this.userId,
      points: points ?? this.points,
      completedAt: completedAt ?? this.completedAt,
      isPublic: isPublic ?? this.isPublic,
      votes: votes ?? this.votes,
      finalDifficulty: finalDifficulty ?? this.finalDifficulty,
      votingClosed: votingClosed ?? this.votingClosed,
    );
  }

  String calculateFinalDifficulty() {
    if (votes.isEmpty) return '';
    
    Map<String, int> voteCounts = {
      'easy': 0,
      'medium': 0,
      'hard': 0,
    };

    for (var vote in votes) {
      voteCounts[vote.difficulty.toLowerCase()] = 
          (voteCounts[vote.difficulty.toLowerCase()] ?? 0) + 1;
    }

    String maxDifficulty = 'easy';
    int maxCount = voteCounts['easy'] ?? 0;

    voteCounts.forEach((diff, count) {
      if (count > maxCount) {
        maxCount = count;
        maxDifficulty = diff;
      }
    });

    return maxDifficulty;
  }

  int calculateFinalPoints() {
    if (!isCompleted) return 0;
    String finalDiff = finalDifficulty.isEmpty ? 
        calculateFinalDifficulty() : finalDifficulty;
    return calculatePoints(finalDiff);
  }

  // Add a method to update completion status
  void markCompleted(bool completed) {
    print('Marking task $id as ${completed ? "completed" : "incomplete"}');
    print('Before update - isCompleted: $isCompleted, completedAt: $completedAt');
    
    isCompleted = completed;
    completedAt = completed ? DateTime.now() : null;
    
    print('After update - isCompleted: $isCompleted, completedAt: $completedAt');
  }
} 