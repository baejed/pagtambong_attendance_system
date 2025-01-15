import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceService {

  static final CollectionReference _attendanceDb = FirebaseFirestore.instance.collection('attendance-item');

  static Future<void> makePresent(DocumentReference studentDocRef, DocumentReference eventDocRef) async {
    final QuerySnapshot attendanceItemQuery = await _attendanceDb
    .where('student', isEqualTo: studentDocRef)
    .where('event', isEqualTo: eventDocRef).get();

    String attendanceDocId = attendanceItemQuery.docs.first.id;
    await _attendanceDb.doc(attendanceDocId).update({"is_present": true});
  }

  static Future<void> makePresentByStudentId(DocumentReference studentDocRef, DocumentReference eventDocRef, String studentID) async {
    // TODO: Replace this block into getting doc by ID number of the student from parameter
    final QuerySnapshot attendanceItemQuery = await _attendanceDb
        .where('student', isEqualTo: studentDocRef)
        .where('event', isEqualTo: eventDocRef)
        .get();

    String attendanceDocId = attendanceItemQuery.docs.first.id;
    await _attendanceDb.doc(attendanceDocId).update({"is_present": true});
  }
}