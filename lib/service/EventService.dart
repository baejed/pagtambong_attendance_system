import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pagtambong_attendance_system/data/college_programs.dart';
import 'package:pagtambong_attendance_system/model/AttendanceItem.dart';
import 'package:pagtambong_attendance_system/model/Event.dart';
import 'package:pagtambong_attendance_system/model/PaginatedResult.dart';
import 'package:pagtambong_attendance_system/model/Student.dart';

import 'CacheService.dart';

class EventService {
  static final CollectionReference _eventDb =
      FirebaseFirestore.instance.collection('events');
  static final CollectionReference _attendanceItemDb =
  FirebaseFirestore.instance.collection('attendance-item');

  static final CollectionReference _studentsDb =
      FirebaseFirestore.instance.collection('student-info');

  // For Cache and Paginating variables
  static const int _batchSize = 100;
  static final _cache = StudentCache();

  static final _studentsController =
      StreamController<PaginatedResult<Student>>.broadcast();
  static final _searchController =
      StreamController<PaginatedResult<Student>>.broadcast();

  static Future<void> toggleOpenEvent(String eventName) async {
    final QuerySnapshot eventItemQuery =
        await _eventDb.where('event_name', isEqualTo: eventName).get();

    String eventDocId = eventItemQuery.docs.first.id;
    bool isOpen = eventItemQuery.docs.first['is_open'];
    await _eventDb.doc(eventDocId).update({'is_open': !isOpen});
  }

  // INITIALIIIIIIIIIIIIIIIIIIIIIIIZEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEERSSSSSS \\
  static Future<void> _loadStudents(
      int page, int pageSize, String searchQuery) async {
    try {
      // First load from cache
      var cachedData = await _cache.getStudents();
      if (cachedData.isNotEmpty) {
        _emitPaginatedResults(cachedData, page, pageSize, searchQuery);
      }

      // Fetch fresh data from API
      var freshData = await getAllStudentNotStream();

      // Update caches with new data
      await _cache.saveStudents(freshData);

      // Emit new results
      _emitPaginatedResults(freshData, page, pageSize, searchQuery);
    } catch (e) {
      _studentsController.addError(e);
    }
  }

  // GEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEETTEEEEEEEEEEEEEEEEEEEEEEEEEEEEERSSSSSS \\
  static Stream<PaginatedResult<Student>> getAllPaginatedStudents({
    int page = 1,
    int pageSize = 20,
    String searchQuery = '',
  }) {
    _loadStudents(page, pageSize, searchQuery);
    return _studentsController.stream;
  }

  static Stream<PaginatedResult<Student>> getSearchResults({
    required String query,
    int page = 1,
    int pageSize = 20,
  }) {
    _performSearch(query, page, pageSize);
    return _searchController.stream;
  }

  static void _emitPaginatedResults(
    List<Student> students,
    int page,
    int pageSize,
    String searchQuery,
  ) {
    // Filter if search query exists
    if (searchQuery.isNotEmpty) {
      students = _filterStudents(students, searchQuery);
    }

    final startIndex = (page - 1) * pageSize;
    final endIndex = startIndex + pageSize;
    final paginatedItems = students.length > startIndex
        ? students.sublist(
            startIndex,
            endIndex > students.length ? students.length : endIndex,
          )
        : <Student>[];

    final result = PaginatedResult<Student>(
        items: paginatedItems,
        total: students.length,
        page: page,
        pageSize: pageSize,
        hasMore: endIndex < students.length);

    _studentsController.add(result);
  }

  static List<Student> _filterStudents(List<Student> students, String query) {
    final lowerCaseQuery = query.toLowerCase();
    return students
        .where((student) =>
            student.firstName.toLowerCase().contains(lowerCaseQuery) ||
            student.lastName.toLowerCase().contains(lowerCaseQuery) ||
            student.studentId.toLowerCase().contains(lowerCaseQuery))
        .toList();
  }

  static Future<void> _performSearch(
      String query, int page, int pageSize) async {
    try {
      final students = await _cache.getStudents();
      final filteredStudents = _filterStudents(students, query);

      final startIndex = (page - 1) * pageSize;
      final endIndex = startIndex + pageSize;
      final paginatedItems = filteredStudents.length > startIndex
          ? filteredStudents.sublist(
              startIndex,
              endIndex > filteredStudents.length
                  ? filteredStudents.length
                  : endIndex,
            )
          : <Student>[];

      final result = PaginatedResult<Student>(
          items: paginatedItems,
          total: filteredStudents.length,
          page: page,
          pageSize: pageSize,
          hasMore: endIndex < filteredStudents.length);

      _searchController.add(result);
    } catch (e) {
      _searchController.addError(e);
    }
  }

  static Future<void> addStudentsByBatch(List<Student> newStudents) async {
    // Process in batches
    for (var i = 0; i < newStudents.length; i += _batchSize) {
      final end = (i + _batchSize < newStudents.length)
          ? i + _batchSize
          : newStudents.length;
      final batch = newStudents.sublist(i, end);

      // Update Cache
      var cachedStudents = await _cache.getStudents();
      cachedStudents.addAll(batch);
      await _cache.saveStudents(cachedStudents);

      // Update
      _emitPaginatedResults(cachedStudents, 1, 20, '');

      // Allow UI to update between batches
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  static void dispose() {
    _studentsController.close();
    _searchController.close();
  }

  static Future<List<Student>> getAllStudentNotStream() async {
    await Future.delayed(const Duration(seconds: 1));
    try {
      final snapshot = await _studentsDb.get();
      final students = snapshot.docs.map((doc) {
        return Student.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
      return students;
    } catch (e) {
      // Log sum shit
      return [];
    }
  }

  //=============== OLD SHIT =============== \\
  static Stream<List<Student>> getAllStudents() {
    try {
      final studentStream = _studentsDb.snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          return Student.fromMap(doc.data() as Map<String, dynamic>);
        }).toList();
      });
      return studentStream;
    } catch (e) {
      // Log sum shit
      return Stream.value([]);
    }
  }

  // SEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEETTEEEEEEEEEEEEEEEEEEEEEEEEEEEEERSSSSSS \\
  static Future<void> updateEvent(Event event, DocumentReference docRef) async {
    await _eventDb.doc(docRef.id).update({
      'event_name': event.eventName,
      'venue': event.venue,
      'organizer': event.organizer,
      'date': event.date
    });
  }

  static Future<void> addEvent(Event event) async {
    final map = event.toMap();
    map.putIfAbsent('is_deleted', () => false);
    await _eventDb.add(map);
  }

  static Future<void> addParticipantWithId(
      DocumentReference eventDocRef, String idNumber) async {
    DocumentReference? studentDocRef;
    bool attendanceItemExists = false;

    await _studentsDb
        .where("student_id", isEqualTo: idNumber)
        .get()
        .then((val) {
      if (val.docs.isEmpty) {
        studentDocRef = null;
        return;
      }
      studentDocRef = val.docs.first.reference;
    });

    await _attendanceItemDb
        .where('event', isEqualTo: eventDocRef)
        .where('student', isEqualTo: studentDocRef)
        .get()
        .then((val) {
      if (val.docs.isNotEmpty) {
        attendanceItemExists = true;
      }
    });

    if (attendanceItemExists) {
      Fluttertoast.showToast(
          msg: "Participant already added",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.blue,
          textColor: Colors.white,
          fontSize: 16.0);
      return;
    }

    if (studentDocRef == null) {
      Fluttertoast.showToast(
          msg: "Student not found",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.blue,
          textColor: Colors.white,
          fontSize: 16.0);
      return;
    }

    AttendanceItem attendanceItem = AttendanceItem(event: eventDocRef, isPresent: false, student: studentDocRef!, studentId: idNumber);
    
    await _attendanceItemDb.add(attendanceItem.toMap());

    Fluttertoast.showToast(
        msg: "Participant successfuly added",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.blue,
        textColor: Colors.white,
        fontSize: 16.0);
  }

  static Future<void> addParticipantWithStudentReference(
      DocumentReference eventDocRef, DocumentReference studentDocRef) async {
    bool attendanceItemExists = false;
    String? idNumber;

    await _attendanceItemDb
        .where('event', isEqualTo: eventDocRef)
        .where('student', isEqualTo: studentDocRef)
        .get()
        .then((val) {
      if (val.docs.isNotEmpty) {
        attendanceItemExists = true;
      }
    });

    if (attendanceItemExists) return;

    await studentDocRef.get().then((onValue) {
        idNumber = onValue['student_id'];
    });

    AttendanceItem attendanceItem = AttendanceItem(event: eventDocRef, isPresent: false, student: studentDocRef, studentId: idNumber!);
    await _attendanceItemDb.add(attendanceItem.toMap());
  }

  static Future<void> addParticipants(DocumentReference eventDocRef,
      List<String> participantsYrLvl, List<String> participantProgram) async {
    bool allProgram = participantProgram.contains(Programs.allProgram);
    bool allYrLvl = participantsYrLvl.contains('All Years');
    Query studentQuery = _studentsDb.where('is_deleted', isEqualTo: false);

    if (allProgram && allYrLvl) {
      studentQuery.get().then((value) {
        for (int i = 0; i < value.docs.length; i++) {
          DocumentReference studentDocRef = value.docs[i].reference;
          addParticipantWithStudentReference(eventDocRef, studentDocRef);
        }
      });

      return;
    }

    for (String yrLvl in participantsYrLvl) {
      for (String program in participantProgram) {
        if (allYrLvl) {
          Query selectedProgramStudents =
              studentQuery.where('program', isEqualTo: program);

          selectedProgramStudents.get().then((value) {
            for (int i = 0; i < value.docs.length; i++) {
              DocumentReference studentDocRef = value.docs[i].reference;
              addParticipantWithStudentReference(eventDocRef, studentDocRef);
            }
          });

          continue;
        }

        if (allProgram) {
          Query selectedYearLevelStudents =
              studentQuery.where('year_level', isEqualTo: yrLvl);

          selectedYearLevelStudents.get().then((value) {
            for (int i = 0; i < value.docs.length; i++) {
              DocumentReference studentDocRef = value.docs[i].reference;
              addParticipantWithStudentReference(eventDocRef, studentDocRef);
            }
          });

          continue;
        }

        Query selectedStudents = studentQuery
            .where('program', isEqualTo: program)
            .where('year_level', isEqualTo: yrLvl);

        selectedStudents.get().then((value) {
          for (int i = 0; i < value.docs.length; i++) {
            DocumentReference studentDocRef = value.docs[i].reference;
            addParticipantWithStudentReference(eventDocRef, studentDocRef);
          }
        });
      }
    }
  }
}
