import 'package:cloud_firestore/cloud_firestore.dart';

class ToDo {
  final String id;
  String title;
  bool isCompleted;
  DateTime? reminderTime;

  ToDo({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.reminderTime,
  });

  /// Converts the ToDo object into a Map for storing in Firestore.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
      'reminderTime':
          reminderTime?.toIso8601String(), // Converts DateTime to String
    };
  }

  /// Creates a ToDo object from a Firestore DocumentSnapshot.
  factory ToDo.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ToDo(
      id: data['id'],
      title: data['title'],
      isCompleted: data['isCompleted'] ?? false,
      reminderTime: data['reminderTime'] != null
          ? DateTime.parse(data['reminderTime'])
          : null,
    );
  }
}
