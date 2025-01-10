import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceItem {
  final DocumentReference event;     // Reference to the event
  final bool isPresent;              // Boolean value indicating presence
  final DocumentReference student;   // Reference to the student
  final String studentId;            // Student ID

  AttendanceItem({
    required this.event,
    required this.isPresent,
    required this.student,
    required this.studentId,
  });

  // Factory constructor to create an AttendanceItem from a map (Firestore document)
  factory AttendanceItem.fromMap(Map<String, dynamic> data) {
    return AttendanceItem(
      event: data['event'] as DocumentReference,             // Assuming it's a Firestore DocumentReference
      isPresent: data['is_present'] ?? false,                // Defaults to false if not present
      student: data['student'] as DocumentReference,         // Assuming it's a Firestore DocumentReference
      studentId: data['student_id'] ?? '',                   // Defaults to an empty string if studentId is not present
    );
  }

  // Converts AttendanceItem object to a map (for storing/updating Firestore document)
  Map<String, dynamic> toMap() {
    return {
      'event': event,
      'is_present': isPresent,
      'student': student,
      'student_id': studentId,
    };
  }
}
