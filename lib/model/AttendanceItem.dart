import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceItem {
  final DocumentReference event;     // Reference to the event
  final bool isPresent;      // Boolean value indicating presence
  final DocumentReference student;   // Reference to the student

  AttendanceItem({
    required this.event,
    required this.isPresent,
    required this.student,
  });

  factory AttendanceItem.fromMap(Map<String, dynamic> data) {
    return AttendanceItem(
      event: data['event'] ?? '',
      isPresent: data['is_present'] ?? false,
      student: data['student'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'event': event,
      'is_present': isPresent,
      'student': student,
    };
  }
}