import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/Event.dart';

class CacheEventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _cachedEventsKey = 'cached_events';

  Stream<List<Event>> get allEventsStream => _firestore.collection('events').snapshots().map((snapshot) {
    return snapshot.docs.map((doc) => Event.fromMap(doc.data())).toList();
  });

  Stream<List<Event>> get openEventsStream => _firestore
      .collection('events')
      .where('is_open', isEqualTo: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) => Event.fromMap(doc.data())).toList();
  });

  Stream<List<Event>> get closedEventsStream => _firestore
      .collection('events')
      .where('is_open', isEqualTo: false)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) => Event.fromMap(doc.data())).toList();
  });

  Future<void> fetchAndCacheAllEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(_cachedEventsKey);

    if (cachedData != null) {
      print("Event cache already exists");
      return;
    }

    try {
      QuerySnapshot eventSnapshot = await _firestore.collection('events').get();
      List<Event> events = eventSnapshot.docs.map((doc) {
        return Event.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
      await cacheEventData(events);
    } catch (e) {
      print("Error fetching events from Firebase: $e");
    }
  }

  Future<void> cacheEventData(List<Event> events) async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> eventCache = {
      for (var event in events) event.eventName: event.toMap()
    };
    await prefs.setString(_cachedEventsKey, jsonEncode(eventCache));
    print("Event data cached successfully. $eventCache");
  }

  Stream<List<Event>> cacheEventChecker() async* {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(_cachedEventsKey);
    List<Event> cachedEvents = [];

    if (cachedData != null) {
      Map<String, dynamic> decodedData = jsonDecode(cachedData);
      cachedEvents = decodedData.values.map((e) => Event.fromMap(e)).toList();
    }

    await for (var snapshot in _firestore.collection('events').snapshots()) {
      List<Event> fetchedEvents = snapshot.docs.map((doc) => Event.fromMap(doc.data())).toList();
      if (!listEquals(fetchedEvents, cachedEvents)) {
        await cacheEventData(fetchedEvents);
        cachedEvents = fetchedEvents;
      }
      yield cachedEvents;
    }
  }

  bool listEquals(List<Event> list1, List<Event> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i].eventName != list2[i].eventName || list1[i].isOpen != list2[i].isOpen) {
        return false;
      }
    }
    return true;
  }
}
