import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:pagtambong_attendance_system/model/Event.dart';

class Eventdatabase with ChangeNotifier {
  final CollectionReference _eventCollection = FirebaseFirestore.instance.collection('events');

  Stream<List<Event>> getEvents() {
    return _eventCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Event.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }
}