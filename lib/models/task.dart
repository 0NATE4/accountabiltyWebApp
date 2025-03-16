class Task {
  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  bool isCompleted;
  final String userId;
  final int points;
  final String difficulty; // 'easy', 'medium', 'hard'
  DateTime? completedAt;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    this.isCompleted = false,
    required this.userId,
    required this.difficulty,
    int? points,
    this.completedAt,
  }) : points = points ?? _calculatePoints(difficulty);

  static int _calculatePoints(String difficulty) {
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
      'dueDate': dueDate.toIso8601String(),
      'isCompleted': isCompleted,
      'userId': userId,
      'points': points,
      'difficulty': difficulty,
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      dueDate: DateTime.parse(map['dueDate']),
      isCompleted: map['isCompleted'] ?? false,
      userId: map['userId'] ?? '',
      points: map['points'] ?? _calculatePoints(map['difficulty'] ?? 'easy'),
      difficulty: map['difficulty'] ?? 'easy',
      completedAt: map['completedAt'] != null ? DateTime.parse(map['completedAt']) : null,
    );
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