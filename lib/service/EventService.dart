import 'package:cloud_firestore/cloud_firestore.dart';

class EventService{
  
  static final CollectionReference _eventDb = FirebaseFirestore.instance.collection('events');

  static Future<void> toggleOpenEvent(String eventName) async {
    final QuerySnapshot eventItemQuery = await _eventDb.where('event_name', isEqualTo: eventName).get();

    String eventDocId = eventItemQuery.docs.first.id;
    bool isOpen = eventItemQuery.docs.first['is_open'];
    await _eventDb.doc(eventDocId).update({"is_open": !isOpen});
  }

}