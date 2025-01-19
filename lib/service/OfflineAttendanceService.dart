import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pagtambong_attendance_system/model/Student.dart';
import 'package:pagtambong_attendance_system/service/LogService.dart';
import 'package:shared_preferences/shared_preferences.dart';

LogService logger = LogService();

class PendingAttendance {
  final String studentId;
  final String eventId;
  final DateTime timeStamp;
  final Student student;

  PendingAttendance({
    required this.studentId,
    required this.eventId,
    required this.timeStamp,
    required this.student,
  });

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'eventId': eventId,
      'timestamp': timeStamp.toIso8601String(),
      'student': student.toMap(),
    };
  }

  factory PendingAttendance.fromMap(Map<String, dynamic> map) {
    return PendingAttendance(
      studentId: map['studentId'],
      eventId: map['eventId'],
      timeStamp: DateTime.parse(map['timeStamp']),
      student: Student.fromMap(map['student']),
    );
  }
}

// TODO: Add another DB function to get a Stream of Events and Users
class OfflineAttendanceService {
  static const String _pendingAttendanceKey = "pending_attendance";
  static const String _cachedStudentKey = "cached_students";
  static const String _cachedEventKey = "cached_events";

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cache the student data when online for offline use
  Future<void> cacheStudentData(Student student) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Retrieve existing data from SharedPreferences
      final existingData = prefs.getString(_cachedStudentKey);
      Map<String, dynamic> studentsCache = {};

      if (existingData != null) {
        try {
          final decodedData = jsonDecode(existingData);

          if (decodedData is Map) {
            studentsCache = Map<String, dynamic>.from(decodedData);
          } else {
            // Log and reset cache if data is corrupted or not a Map
            logger.e("Existing cache data is not a valid Map: $decodedData");
          }
        } catch (e) {
          // Handle JSON parsing errors
          logger.e("Error decoding existing cache data: $e");
        }
      } else {
        logger.i("No existing student cache found.");
      }

      // Add the new student to the cache
      // logger.i("Adding student to cache: ${student.toMap()}");
      studentsCache[student.studentId] = student.toMap();

      // Save the updated cache
      await prefs.setString(_cachedStudentKey, jsonEncode(studentsCache));
      // logger.i("Updated student cache saved: $studentsCache");
    } catch (e, stackTrace) {
      // Log any unexpected errors
      logger.e("Error in cacheStudentData: $e");
      logger.e(stackTrace.toString());
    }
  }

  Future<void> cacheEventReference(String eventId, String eventName) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Retrieve existing event data
      final existingData = prefs.getString(_cachedEventKey);
      Map<String, String> eventsCache = {};

      if (existingData != null) {
        try {
          final decodedData = jsonDecode(existingData);

          if (decodedData is Map) {
            eventsCache = Map<String, String>.from(decodedData);
          } else {
            // Log and reset cache if data is corrupted or not a Map
            logger.e("Existing cache data is not a valid Map<String, String>: $decodedData");
          }
        } catch (e) {
          // Handle JSON parsing errors
          logger.e("Error decoding existing event cache data: $e");
        }
      } else {
        logger.i("No existing event cache found.");
      }

      // Add the new event reference to the cache
      logger.i("Adding event to cache: {eventId: $eventId, eventName: $eventName}");
      eventsCache[eventId] = eventName;

      // Save the updated cache
      await prefs.setString(_cachedEventKey, jsonEncode(eventsCache));
      logger.i("Updated event cache saved: $eventsCache");
    } catch (e, stackTrace) {
      // Log any unexpected errors
      logger.e("Error in cacheEventReference: $e");
      logger.e(stackTrace.toString());
    }
  }

  Future<void> saveOfflineAttendance(Student student, String eventId) async {
    final prefs = await SharedPreferences.getInstance();
    List<PendingAttendance> pendingRecords =
        await getPendingAttendance();

    // Check if this attendance was already recorded
    bool isDuplicate = pendingRecords.any((record) =>
        record.studentId == student.studentId && record.eventId == eventId);

    if (isDuplicate) return;

    // Add new record
    pendingRecords.add(PendingAttendance(
      studentId: student.studentId,
      eventId: eventId,
      timeStamp: DateTime.now(),
      student: student,
    ));

    // Save updated list
    final jsonData = pendingRecords.map((record) => record.toMap()).toList();
    await prefs.setString(_pendingAttendanceKey, jsonEncode(jsonData));

    // Cache student data for offline access
    await cacheStudentData(student);
  }

  Future<List<PendingAttendance>> getPendingAttendance() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_pendingAttendanceKey);

    if (jsonString == null) {
      return [];
    }
    final jsonData = jsonDecode(jsonString) as List;
    return jsonData
        .map((item) =>
            PendingAttendance.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  // Clear pending attendance records after successful sync
  Future<void> clearPendingAttendance() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingAttendanceKey);
  }

  // Sync offline attendance records with Firebase
  Future<void> syncPendingAttendance() async {
    final List<PendingAttendance> pendingRecords =
        await getPendingAttendance();

    if (pendingRecords.isEmpty) {
      return;
    }

    final CollectionReference attendanceCollection =
        _firestore.collection('attendance-item');

    for (var record in pendingRecords) {
      try {
        // Create DocumentReference
        DocumentReference studentRef =
            _firestore.collection('student-info').doc(record.studentId);

        DocumentReference eventRef =
            _firestore.collection('events').doc(record.eventId);

        QuerySnapshot existingAttendance = await attendanceCollection
            .where('student_id', isEqualTo: record.studentId)
            .where('event', isEqualTo: eventRef)
            .get();

        if (existingAttendance.docs.isNotEmpty) {
          // Update existing attendance record
          await attendanceCollection
              .doc(existingAttendance.docs.first.id)
              .update({'is_present': true});
        } else {
          // Create a new attendance record
          await attendanceCollection.add({
            'event': eventRef,
            'is_present': true,
            'student': studentRef,
            'student_id': record.studentId,
          });
        }
      } catch (e) {
        logger.i('Error syncing attendance for student ${record.studentId}: $e');
        return;
      }
    }

    // Clear pending records after successful sync
    await clearPendingAttendance();
  }

  // Get cached student data
  Future<Student?> getCachedStudent(String studentId) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(_cachedStudentKey);
    logger.i("Cached Data: $cachedData");

    if (cachedData == null) return null;

    final studentsCache = Map<String, dynamic>.from(jsonDecode(cachedData));
    final studentData = studentsCache[studentId];

    if (studentData == null) return null;
    
    return Student.fromMap(studentData);
  }
}
