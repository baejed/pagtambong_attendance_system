import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pagtambong_attendance_system/model/Student.dart';
import 'package:pagtambong_attendance_system/service/LogService.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/Event.dart';

LogService logger = LogService();

class PendingAttendance {
  final String studentId;
  final String eventId;
  final Student student;
  final String selectedEvent;

  PendingAttendance({
    required this.studentId,
    required this.eventId,
    required this.student,
    required this.selectedEvent,
  });

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'eventId': eventId,
      'student': student.toMap(),
      'selectedEvent': selectedEvent,
    };
  }

  factory PendingAttendance.fromMap(Map<String, dynamic> map) {
    return PendingAttendance(
      studentId: map['studentId'],
      eventId: map['eventId'],
      student: Student.fromMap(map['student']),
      selectedEvent: map['selectedEvent'],
    );
  }
}

// TODO: Add another DB function to get a Stream of Events and Users
class OfflineAttendanceService {
  static const String _pendingAttendanceKey = "pending_attendance";
  static const String _cachedStudentKey = "cached_students";
  static const String _cachedEventKey = "cached_events";

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final CollectionReference _studentsDb =
      FirebaseFirestore.instance.collection('student-info');
  final CollectionReference _eventsDB =
      FirebaseFirestore.instance.collection('events');

  // CACHE ALL THE MOTHERFUCKING STUDENTS FROM FIREBASE
  Future<void> fetchAndCacheAllStudents(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(_cachedStudentKey);

    if (cachedData != null) {
      logger.i("Student cache already exists");
      return;
    }

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please wait while caching students...',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );
      QuerySnapshot studentSnapshot = await _studentsDb.get();
      List<Student> students = studentSnapshot.docs.map((doc) {
        return Student.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
      // printStudentDetails(students);
      // logger.i("Fetched and cached ${students.length} students.");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Fetched and cached ${students.length} students.",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 3),
        ),
      );
      await cacheStudentDataList(students);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Some error occurred when caching students',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      logger.e("Error fetching students from Firebase: $e");
    }
  }

  // CACHE ALL THE MOTHERFUCKING EVENTS FROM FIREBASE
  Future<void> fetchAndCacheAllEvents(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(_cachedEventKey);

    if (cachedData != null) {
      logger.i("Event cache already exists");
      return;
    }

    try {
      QuerySnapshot eventSnapshot = await _eventsDB.get();
      List<Event> events = eventSnapshot.docs.map((doc) {
        return Event.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();

      await cacheEventData(events);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Some error occurred when caching events',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      logger.e("Error fetching events from Firebase: $e");
    }
  }

  void printStudentDetails(List<Student> students) {
    for (var student in students) {
      logger.i("Student ID: ${student.studentId}, "
          "First Name: ${student.firstName}, "
          "Last Name: ${student.lastName}, "
          "Year Level: ${student.yearLevel}");
    }
  }

  Future<void> cacheStudentDataList(List<Student> students) async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> studentsCache = {
      for (var student in students) student.studentId: student.toMap()
    };

    await prefs.setString(_cachedStudentKey, jsonEncode(studentsCache));
    logger.i("Student data cached successfully.");
  }

  // Cache the student data when online for offline use
  Future<void> cacheStudentData(Student student) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Retrieve existing data from SharedPreferences
      final existingData = prefs.getString(_cachedStudentKey);
      logger.i("Cached Students: $existingData");
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
        logger.i("Student not found");
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

      // Create/retrieve the ID-to-name mapping
      final existingData = prefs.getString("${_cachedEventKey}_map");
      Map<String, dynamic> eventsCache = {};

      if (existingData != null) {
        try {
          final decodedData = jsonDecode(existingData);
          if (decodedData is Map) {
            eventsCache = Map<String, dynamic>.from(decodedData);
          }
        } catch (e) {
          logger.e("Error decoding existing event cache data: $e");
        }
      }

      // Add the new event reference to the cache
      eventsCache[eventId] = eventName;

      // Save the updated cache with a different key to avoid conflicts
      await prefs.setString("${_cachedEventKey}_map", jsonEncode(eventsCache));
      logger.i("Updated event cache saved: $eventsCache");
    } catch (e, stackTrace) {
      logger.e("Error in cacheEventReference: $e");
      logger.e(stackTrace.toString());
    }
  }

  Future<void> cacheAllEventReference() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Create/retrieve the ID-to-name mapping
      final existingData = prefs.getString("${_cachedEventKey}");
      Map<String, dynamic> eventsCache = {};

      if (existingData != null) {
        try {
          final decodedData = jsonDecode(existingData);
          logger.i("Decoded Data: $decodedData");
          if (decodedData is Map) {
            eventsCache = Map<String, dynamic>.from(decodedData);
          }
        } catch (e) {
          logger.e("Error decoding existing event cache data: $e");
        }
      }

      // Query Firebase for open events
      QuerySnapshot eventSnapshot =
          await _eventsDB.where('is_open', isEqualTo: true).get();
      for (var doc in eventSnapshot.docs) {
        Event event = Event.fromMap(doc.data() as Map<String, dynamic>);
        eventsCache[doc.id] = event.eventName;
      }

      // Save the updated cache with a different key to avoid conflicts
      await prefs.setString("${_cachedEventKey}", jsonEncode(eventsCache));
      logger.i("Updated event cache saved: $eventsCache");
    } catch (e, stackTrace) {
      logger.e("Error in cacheEventReference: $e");
      logger.e(stackTrace.toString());
    }
  }

  /*Future<void> cacheEventReference(String eventId, String eventName) async {
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
            logger.e(
                "Existing cache data is not a valid Map<String, String>: $decodedData");
          }
        } catch (e) {
          // Handle JSON parsing errors
          logger.e("Error decoding existing event cache data: $e");
        }
      } else {
        logger.i("No existing event cache found.");
      }

      // Add the new event reference to the cache
      logger.i(
          "Adding event to cache: {eventId: $eventId, eventName: $eventName}");
      eventsCache[eventId] = eventName;

      // Save the updated cache
      await prefs.setString(_cachedEventKey, jsonEncode(eventsCache));
      logger.i("Updated event cache saved: $eventsCache");
    } catch (e, stackTrace) {
      // Log any unexpected errors
      logger.e("Error in cacheEventReference: $e");
      logger.e(stackTrace.toString());
    }
  }*/

  // New method to cache full event data
  Future<void> cacheEventData(List<Event> events) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final eventsList = events.map((event) => event.toMap()).toList();
      await prefs.setString(_cachedEventKey, jsonEncode(eventsList));
      logger.i("Cached ${events.length} events");
    } catch (e) {
      logger.e("Error caching event data: $e");
    }
  }

  Future<void> saveOfflineAttendance(
      Student student, String eventId, String selectedEvent) async {
    final prefs = await SharedPreferences.getInstance();
    List<PendingAttendance> pendingRecords = await getPendingAttendance();
    logger.i("Is Duplicate Result: $pendingRecords");

    // Check if this attendance was already recorded
    bool isDuplicate = pendingRecords.any((record) =>
        record.studentId == student.studentId && record.eventId == eventId);

    if (isDuplicate) return;

    // Add new record
    pendingRecords.add(PendingAttendance(
      studentId: student.studentId,
      eventId: eventId,
      student: student,
      selectedEvent: selectedEvent,
    ));

    // Save updated list
    final jsonData = pendingRecords.map((record) => record.toMap()).toList();
    await prefs.setString(_pendingAttendanceKey, jsonEncode(jsonData));

    // Cache student data for offline access
    await cacheStudentData(student);
  }

  Future<List<PendingAttendance>> getPendingAttendance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_pendingAttendanceKey);
      logger.i("Pending Attendance JSON String: $jsonString");
      if (jsonString == null) {
        return [];
      }
      final List<dynamic> jsonData = jsonDecode(jsonString);
      // logger.i("Pending Attendance JSON Data: $jsonData");

      return jsonData.map<PendingAttendance>((item) {
        try {
          return PendingAttendance.fromMap(item as Map<String, dynamic>);
        } catch (e) {
          logger.e("Error parsing individual attendance record: $e");
          logger.e("Problematic record: $item");
          rethrow;
        }
      }).toList();
    } catch (e, stackTrace) {
      logger.e("There is an error returning JSON of student: $e");
      logger.e(stackTrace.toString());
      return [];
    }
  }

  // Clear pending attendance records after successful sync
  Future<void> clearPendingAttendance() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingAttendanceKey);
  }

  // Sync offline attendance records with Firebase
  Future<void> syncPendingAttendance(BuildContext context) async {
    final List<PendingAttendance> pendingRecords = await getPendingAttendance();
    logger.i(
        "Pending Records: ${await getPendingAttendance().then((records) => records.map((record) => record.toMap()).toList())}");
    if (pendingRecords.isEmpty) {
      return;
    }

    final CollectionReference attendanceCollection =
        _firestore.collection('attendance-item');
    List<String> successfulSyncs = [];
    List<String> failedSyncs = [];

    for (var record in pendingRecords) {
      try {
        QuerySnapshot student = await _studentsDb
            .where('is_deleted', isEqualTo: false)
            .where('student_id', isEqualTo: record.studentId)
            .get();
        QuerySnapshot event = await _eventsDB
            .where('is_deleted', isEqualTo: false)
            .where('event_name', isEqualTo: record.selectedEvent)
            .get();
        QueryDocumentSnapshot studentQueryDoc = student.docs.first;
        QueryDocumentSnapshot eventQueryDoc = event.docs.first;
        DocumentReference studentDocRef = studentQueryDoc.reference;
        DocumentReference eventDocRef = eventQueryDoc.reference;

        // Verify both references exists
        final studentDoc = await studentDocRef.get();
        final eventDoc = await eventDocRef.get();

        if (!studentDoc.exists || !eventDoc.exists) {
          failedSyncs.add(record.studentId);
          logger.e(
              'Student or Event reference not found for ${record.studentId}');
          continue;
        }

        // Check for existing attendance
        QuerySnapshot existingAttendance = await attendanceCollection
            .where('student_id', isEqualTo: record.studentId)
            .where('event', isEqualTo: eventDocRef)
            .get();

        if (existingAttendance.docs.isNotEmpty) {
          // Update attendance
          await attendanceCollection
              .doc(existingAttendance.docs.first.id)
              .update({
            'is_present': true,
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No existing pending attendance'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        successfulSyncs.add(record.studentId);
      } catch (e) {
        failedSyncs.add(record.studentId);
        logger
            .e('Error syncing attendance for student ${record.studentId}: $e');
        continue;
      }
    }

    // Remove only successfully synced records
    if (successfulSyncs.isNotEmpty) {
      final remainingRecord = pendingRecords
          .where(
            (record) => !successfulSyncs.contains(record.studentId),
          )
          .toList();

      // Update pending records with only failed ones
      if (remainingRecord.isEmpty) {
        await clearPendingAttendance();
      } else {
        final prefs = await SharedPreferences.getInstance();
        final jsonData =
            remainingRecord.map((record) => record.toMap()).toList();
        await prefs.setString(_pendingAttendanceKey, jsonEncode(jsonData));
      }
    }
    // Log sync results
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Sync completed. Success: ${successfulSyncs.length}, Failed: ${failedSyncs.length}',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 3),
      ),
    );
    logger.i(
        'Sync completed. Success: ${successfulSyncs.length}, Failed: ${failedSyncs.length}');
  }

  // Get cached student data
  Future<Student?> getCachedStudent(String studentId) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(_cachedStudentKey);

    if (cachedData == null) return null;

    final studentsCache = Map<String, dynamic>.from(jsonDecode(cachedData));
    final studentData = studentsCache[studentId];

    if (studentData == null) return null;

    return Student.fromMap(studentData);
  }

  // For the event shit
  Future<String?> getCachedEventId(String eventName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final eventData = prefs.getString(_cachedEventKey);

      if (eventData != null) {
        final List<dynamic> eventsList = jsonDecode(eventData);
        final matchingEvent = eventsList.firstWhere(
          (event) => event['event_name'] == eventName,
          orElse: () => null,
        );

        if (matchingEvent != null) {
          // Since we found the matching event, we can generate a consistent ID
          // using a hash of the event details to ensure uniqueness
          final eventDetails =
              '${matchingEvent['event_name']}_${matchingEvent['date']}_${matchingEvent['organizer']}';
          return sha256
              .convert(utf8.encode(eventDetails))
              .toString()
              .substring(0, 16);
        }
      }

      return null;
    } catch (e) {
      logger.e("Error getting cached event ID: $e");
      return null;
    }
  }

  /*Future<String?> getCachedEventId(String eventName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_cachedEventKey);

      if (cachedData == null) return null;

      final eventsCache = Map<String, String>.from(jsonDecode(cachedData));

      // Find the event ID where the value (event name) matches
      final eventEntry = eventsCache.entries.firstWhere(
          (entry) => entry.value == eventName,
          orElse: () => MapEntry('', ''));
      return eventEntry.key.isEmpty ? null : eventEntry.key;
    } catch (e) {
      logger.e("Error getting cached event ID: $e");
      return null;
    }
  }*/

  Future<void> storePendingAttendance(
      {required String studentId,
      required String eventName,
      required String selectedEvent}) async {
    try {
      // Get cached student and event data
      final student = await getCachedStudent(studentId);
      final eventId = await getCachedEventId(eventName);

      logger.i("Cached Student: ${student!.firstName}");
      logger.i("Cached Event ID: ${eventId!}");
      if (student == null || eventId == null) {
        throw Exception("Required cached data not found");
      }

      // Create and save pending attendance
      await saveOfflineAttendance(student, eventId, selectedEvent);

      logger.i(
          "Stored pending attendance for student $studentId at event $eventName");
    } catch (e) {
      logger.e("Error storing pending attendance: $e");
      rethrow;
    }
  }

  Future<void> clearAllCaches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingAttendanceKey);
    await prefs.remove(_cachedStudentKey);
    await prefs.remove(_cachedEventKey);
    await prefs.remove("${_cachedEventKey}_map");
    logger.i("All caches cleared.");
  }
}
