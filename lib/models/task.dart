// models/task.dart
class Task {
  final String id;
  final String appointmentId; // Link to which appointment this task belongs
  final String description;
  bool isCompleted;
  DateTime? completionTime; // Auto-log time of completion

  Task({
    required this.id,
    required this.appointmentId,
    required this.description,
    this.isCompleted = false,
    this.completionTime,
  });

  // Factory constructor for creating a Task from a map
  factory Task.fromMap(Map<String, dynamic> data, String id) {
    return Task(
      id: id,
      appointmentId: data['appointmentId'] ?? '',
      description: data['description'] ?? '',
      isCompleted: data['isCompleted'] ?? false,
      completionTime: data['completionTime'] != null
          ? DateTime.parse(data['completionTime'])
          : null,
    );
  }

  // Method to convert Task to a map
  Map<String, dynamic> toMap() {
    return {
      'appointmentId': appointmentId,
      'description': description,
      'isCompleted': isCompleted,
      'completionTime': completionTime?.toIso8601String(),
    };
  }
}
