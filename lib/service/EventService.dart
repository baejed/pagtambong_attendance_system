import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pagtambong_attendance_system/data/college_programs.dart';
import 'package:pagtambong_attendance_system/model/AttendanceItem.dart';
import 'package:pagtambong_attendance_system/model/Event.dart';

class EventService {
  
  static final CollectionReference _eventDb = FirebaseFirestore.instance.collection('events');
  static final CollectionReference _studentsDb = FirebaseFirestore.instance.collection('student-info');
  static final CollectionReference _attendanceItemDb = FirebaseFirestore.instance.collection('attendance-item');


  static Future<void> toggleOpenEvent(String eventName) async {
    final QuerySnapshot eventItemQuery = await _eventDb.where('event_name', isEqualTo: eventName).get();

    String eventDocId = eventItemQuery.docs.first.id;
    bool isOpen = eventItemQuery.docs.first['is_open'];
    await _eventDb.doc(eventDocId).update({'is_open': !isOpen});
  }

  static Future<void> updateEvent(Event event, DocumentReference docRef) async {
    await _eventDb.doc(docRef.id).update({
      'event_name': event.eventName,
      'venue': event.venue,
      'organizer': event.organizer,
      'date': event.date
    });
  }

  static Future<void> addEvent(Event event) async{
    final map = event.toMap();
    map.putIfAbsent('is_deleted', () => false);
    await _eventDb.add(map);
  }

  static Future<void> addParticipants(DocumentReference eventDocRef, List<String> participantsYrLvl, List<String> participantProgram) async {

    bool allProgram = participantProgram.contains(Programs.allProgram);
    bool allYrLvl = participantsYrLvl.contains('All Years');
    Query studentQuery = _studentsDb.where('is_deleted', isEqualTo: false);

    if(allProgram && allYrLvl) {
      studentQuery.get().then((value) {
        for(int i = 0; i < value.docs.length; i++){
          DocumentReference studentDocRef = value.docs[i].reference;
          AttendanceItem attendanceItemModel = AttendanceItem.fromMap({
            'event': eventDocRef,
            'is_present': false,
            'student': studentDocRef
          });

          _attendanceItemDb.add(attendanceItemModel.toMap());
        }
      });

      return;
    }

    for(String yrLvl in participantsYrLvl) {
      for(String program in participantProgram) {
        
        if(allYrLvl) {

          Query selectedProgramStudents = studentQuery.where('program', isEqualTo: program);
          
          selectedProgramStudents.get().then((value) {
            for(int i = 0; i < value.docs.length; i++) {
              DocumentReference studentDocRef = value.docs[i].reference;
              AttendanceItem attendanceItemModel = AttendanceItem.fromMap({
                'event': eventDocRef,
                'is_present': false,
                'student': studentDocRef
              });

              _attendanceItemDb.add(attendanceItemModel.toMap());
            }
          });

          continue;

        }

        if(allProgram) {

          Query selectedYearLevelStudents = studentQuery.where('year_level', isEqualTo: yrLvl);
          
          selectedYearLevelStudents.get().then((value) {
            for(int i = 0; i < value.docs.length; i++) {
              DocumentReference studentDocRef = value.docs[i].reference;
              AttendanceItem attendanceItemModel = AttendanceItem.fromMap({
                'event': eventDocRef,
                'is_present': false,
                'student': studentDocRef
              });
              
              _attendanceItemDb.add(attendanceItemModel.toMap());
            }
          });

          continue;

        }

        Query selectedStudents = studentQuery
          .where('program', isEqualTo: program)
          .where('year_level', isEqualTo: yrLvl);

        selectedStudents.get().then((value) {
          for(int i = 0; i < value.docs.length; i++) {
              DocumentReference studentDocRef = value.docs[i].reference;
              AttendanceItem attendanceItemModel = AttendanceItem.fromMap({
                'event': eventDocRef,
                'is_present': false,
                'student': studentDocRef
              });
              
              _attendanceItemDb.add(attendanceItemModel.toMap());
            }
        });

      }
    }

  }

}