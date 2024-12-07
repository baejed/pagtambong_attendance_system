import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pagtambong_attendance_system/model/Event.dart';

class EventService{
  
  static final CollectionReference _eventDb = FirebaseFirestore.instance.collection('events');

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

}