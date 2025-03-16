import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../services/auth_service.dart';
import '../services/task_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  final _taskService = TaskService();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _selectedDifficulty = 'easy';
  late TabController _tabController;
  int _lastKnownPoints = 0;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool _isInCurrentWeek(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sunday = today.subtract(Duration(days: today.weekday % 7));
    final nextSunday = sunday.add(const Duration(days: 7));
    
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final isInWeek = normalizedDate.isAfter(sunday.subtract(const Duration(days: 1))) && 
                     normalizedDate.isBefore(nextSunday);
    
    print('Checking if date $date is in current week:');
    print('  Sunday: $sunday');
    print('  Next Sunday: $nextSunday');
    print('  Is in week: $isInWeek');
    
    return isInWeek;
  }

  void _showAddTaskDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Add New Task',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedDifficulty,
                decoration: const InputDecoration(
                  labelText: 'Difficulty',
                  border: OutlineInputBorder(),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                ),
                items: ['easy', 'medium', 'hard'].map((difficulty) {
                  return DropdownMenuItem(
                    value: difficulty,
                    child: Text(
                      difficulty[0].toUpperCase() + difficulty.substring(1),
                      style: TextStyle(
                        color: _getDifficultyColor(difficulty),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedDifficulty = value!);
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() => _selectedDate = date);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[400]!),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.grey[600]),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Due Date',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetForm();
            },
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (_titleController.text.isNotEmpty) {
                final task = Task(
                  id: const Uuid().v4(),
                  title: _titleController.text,
                  description: _descriptionController.text,
                  dueDate: _selectedDate,
                  userId: _authService.currentUser!.uid,
                  difficulty: _selectedDifficulty,
                );
                _taskService.createTask(task);
                _resetForm();
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
            child: const Text(
              'Add Task',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _resetForm() {
    _titleController.clear();
    _descriptionController.clear();
    setState(() {
      _selectedDate = DateTime.now();
      _selectedDifficulty = 'easy';
    });
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

  Widget _buildPointsBar(int points) {
    const int weeklyGoal = 1000; // Adjust this value as needed
    final double progress = (points / weeklyGoal).clamp(0.0, 1.0);
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly Points',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$points / $weeklyGoal',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                progress < 0.3
                    ? Colors.red
                    : progress < 0.7
                        ? Colors.orange
                        : Colors.green,
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Reset every Sunday at 11:59 PM',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(List<Task> tasks, bool showCompleted) {
    print('Building task list. ShowCompleted: $showCompleted');
    print('Total tasks: ${tasks.length}');
    
    final filteredTasks = tasks.where((task) {
      if (showCompleted) {
        final isVisible = task.isCompleted && task.completedAt != null;
        print('Task ${task.title} - isCompleted: ${task.isCompleted}, completedAt: ${task.completedAt}, isVisible: $isVisible');
        return isVisible;
      } else {
        final isVisible = !task.isCompleted;
        print('Task ${task.title} - isCompleted: ${task.isCompleted}, isVisible: $isVisible');
        return isVisible;
      }
    }).toList();

    print('Filtered tasks: ${filteredTasks.length}');

    // Sort tasks by completion status and date
    filteredTasks.sort((a, b) {
      if (showCompleted) {
        // For completed tasks, show most recently completed first
        return (b.completedAt ?? b.dueDate).compareTo(a.completedAt ?? a.dueDate);
      } else {
        // For current tasks, show closest due date first
        return a.dueDate.compareTo(b.dueDate);
      }
    });

    if (filteredTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              showCompleted ? Icons.task_alt : Icons.assignment_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              showCompleted
                  ? 'No completed tasks this week'
                  : 'No pending tasks',
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
      padding: const EdgeInsets.all(16),
      itemCount: filteredTasks.length,
      itemBuilder: (context, index) {
        final task = filteredTasks[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
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
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
            title: Text(
              task.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                color: task.isCompleted ? Colors.grey : Colors.black87,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (task.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    task.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getDifficultyColor(task.difficulty)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getDifficultyColor(task.difficulty)
                              .withOpacity(0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${task.difficulty[0].toUpperCase()}${task.difficulty.substring(1)}',
                            style: TextStyle(
                              color: _getDifficultyColor(task.difficulty),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${task.points} pts',
                            style: TextStyle(
                              color: _getDifficultyColor(task.difficulty),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: task.dueDate.isBefore(DateTime.now())
                          ? Colors.red[400]
                          : Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${task.dueDate.year}-${task.dueDate.month.toString().padLeft(2, '0')}-${task.dueDate.day.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: task.dueDate.isBefore(DateTime.now())
                            ? Colors.red[400]
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!showCompleted) ...[
                  Transform.scale(
                    scale: 1.2,
                    child: Checkbox(
                      value: task.isCompleted,
                      onChanged: (value) async {
                        print('Checkbox changed to: $value');
                        print('Before update - Task ${task.title}: isCompleted=${task.isCompleted}, completedAt=${task.completedAt}');
                        
                        // Update the task's completion status locally first
                        task.markCompleted(value!);
                        print('After local update - Task ${task.title}: isCompleted=${task.isCompleted}, completedAt=${task.completedAt}');
                        
                        // Then update in Firestore
                        await _taskService.updateTaskStatus(task.id, value);
                        print('After Firestore update - Task ${task.title} marked as completed');
                        
                        // If task is completed, switch to completed tab
                        if (value) {
                          _tabController.animateTo(1);
                        }
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      activeColor: Colors.green,
                    ),
                  ),
                ],
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: Colors.red[300],
                  ),
                  onPressed: () => _taskService.deleteTask(task.id),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'My Tasks',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.black54),
            onPressed: () => _authService.signOut(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: Theme.of(context).primaryColor,
          tabs: const [
            Tab(
              icon: Icon(Icons.assignment_outlined),
              text: 'Current',
            ),
            Tab(
              icon: Icon(Icons.task_alt),
              text: 'Completed',
            ),
          ],
        ),
      ),
      body: StreamBuilder<List<Task>>(
        stream: _taskService.getTasks(_authService.currentUser!.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final tasks = snapshot.data!;
          print('Total tasks received: ${tasks.length}');
          
          // Calculate weekly points
          final weeklyPoints = tasks
              .where((task) {
                final isCountable = task.isCompleted && task.completedAt != null && _isInCurrentWeek(task.completedAt!);
                print('Task "${task.title}" - Points: ${task.points}, isCompleted: ${task.isCompleted}, completedAt: ${task.completedAt}, isInCurrentWeek: ${task.completedAt != null ? _isInCurrentWeek(task.completedAt!) : false}, isCountable: $isCountable');
                return isCountable;
              })
              .fold(0, (sum, task) {
                print('Adding ${task.points} points from task "${task.title}"');
                return sum + task.points;
              });
          
          // Update last known points only if we have a non-zero value
          if (weeklyPoints > 0) {
            _lastKnownPoints = weeklyPoints;
          }
          
          // Use either current points or last known points, whichever is higher
          final displayPoints = weeklyPoints > 0 ? weeklyPoints : _lastKnownPoints;
          
          print('Total weekly points calculated: $displayPoints (raw: $weeklyPoints, last known: $_lastKnownPoints)');

          return Column(
            children: [
              _buildPointsBar(displayPoints),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTaskList(tasks, false),
                    _buildTaskList(tasks, true),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTaskDialog,
        backgroundColor: Theme.of(context).primaryColor,
        icon: const Icon(Icons.add),
        label: const Text(
          'Add Task',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
} 