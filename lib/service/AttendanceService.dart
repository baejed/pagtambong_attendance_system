import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AttendanceService {

  static final CollectionReference _attendanceDb = FirebaseFirestore.instance.collection('attendance-item');

  static Future<void> makePresent(DocumentReference studentDocRef, DocumentReference eventDocRef) async {
    final QuerySnapshot attendanceItemQuery = await _attendanceDb
    .where('student', isEqualTo: studentDocRef)
    .where('event', isEqualTo: eventDocRef).get();

    String attendanceDocId = attendanceItemQuery.docs.first.id;
    await _attendanceDb.doc(attendanceDocId).update({"is_present": true});
  }

  static Future<void> makePresentByStudentId(DocumentReference studentDocRef, DocumentReference eventDocRef) async {
    final QuerySnapshot attendanceItemQuery = await _attendanceDb
        .where('student', isEqualTo: studentDocRef)
        .where('event', isEqualTo: eventDocRef)
        .get();

    String attendanceDocId = attendanceItemQuery.docs.first.id;
    await _attendanceDb.doc(attendanceDocId).update({"is_present": true});
  }
}