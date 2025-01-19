import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pagtambong_attendance_system/auth/login.dart';
import 'package:pagtambong_attendance_system/model/UserRoles.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/Event.dart';
import '../model/Student.dart';

class StudentCache {
  static const String _cacheKey = "students_cache";
  static const Duration _cacheValidDuration = Duration(hours: 24);

  Future<void> saveStudents(List<Student> students) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = students.map((s) => s.toMap()).toList();
    await prefs.setString(_cacheKey, jsonEncode(jsonData));
    await prefs.setString("${_cacheKey}_timestamp", DateTime.now().toIso8601String());
  }

  Future<List<Student>> getStudents() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_cacheKey);
    final timeStampString = prefs.getString("${_cacheKey}_timestamp");

    if (jsonString == null || timeStampString == null) {
      return [];
    }

    final timeStamp = DateTime.parse(timeStampString);

    if (DateTime.now().difference(timeStamp) > _cacheValidDuration) {
      return []; // Cache expired
    }

    final jsonData = jsonDecode(jsonString) as List;

    return jsonData
        .map((item) => Student.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    await prefs.remove('${_cacheKey}_timestamp');
  }
}

class UserCache {
  static const String _cacheKey = "users_cache";
  static const Duration _cacheValidDuration = Duration(hours: 24);

  Future<void> saveUsers(List<AppUser> users) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = users.map((u) => u.toMap()).toList();
    await prefs.setString(_cacheKey, jsonEncode(jsonData));
    await prefs.setString("${_cacheKey}_timestamp", DateTime.now().toIso8601String());
  }

  Future<List<AppUser>> getUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_cacheKey);
    final timeStampString = prefs.getString("${_cacheKey}_timestamp");

    if (jsonString == null || timeStampString == null) {
      return [];
    }

    final timeStamp = DateTime.parse(timeStampString);

    if (DateTime.now().difference(timeStamp) > _cacheValidDuration) {
      return []; // Cache expired
    }

    final jsonData = jsonDecode(jsonString) as List;

    return jsonData
        .map((item) => AppUser.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    await prefs.remove("${_cacheKey}_timestamp");
  }
}

class EventCacheService {
  static const String _eventsKey = 'cached_events';
  static const Duration _cacheValidDuration = Duration(hours: 24);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _eventController = StreamController<List<Event>>.broadcast();
  StreamSubscription? _firestoreSubscription;

  // Initialize the service with online/offline capability
  void initialize(bool? isOnline) {
    logger.i("Initializing Event Cache... isOnline: $isOnline");
    if (isOnline == true) {
      _subscribeToFirestore();
    } else if (isOnline == false) {
      _loadCachedEvents();
    } else {
      logger.w("Unknown connectivity state. Loading cached events by default.");
      _loadCachedEvents();
    }
  }

  // Get the stream of events (works both online and offline)
  Stream<List<Event>> getEventStream() async* {
    // Yield cached events first to ensure immediate data availability
    yield await getCachedEvents();

    // Listen to Firestore updates for live data
    if (_firestoreSubscription == null) {
      _subscribeToFirestore();
    }

    yield* _eventController.stream;
  }

  // Subscribe to Firestore updates when online
  void _subscribeToFirestore() {
    if (_firestoreSubscription != null) {
      // logger.w("Firestore subscription already active. Cancelling existing subscription...");
      _firestoreSubscription?.cancel();
    }
    // logger.i("Subscribing to Firestore...");
    _firestoreSubscription = _firestore
        .collection('events')
        .where('is_open', isEqualTo: true)
        .snapshots()
        .listen(
          (snapshot) {
        if (snapshot.docs.isEmpty) {
          logger.i("No events found in Firestore.");
          _eventController.add([]);
          return;
        }

        final events = snapshot.docs.map((doc) {
          // logger.i("Fetched event: ${doc.data()}");
          return Event.fromMap(doc.data());
        }).toList();

        _eventController.add(events);
        _cacheOpenEvents(events);
        // logger.i("Event Controller: ${_eventController.stream.first}");
      },
      onError: (error) {
        logger.e("Error during Firestore subscription: $error");
        _loadCachedEvents();
      },
    );
  }

  // Load and emit cached events
  Future<void> _loadCachedEvents() async {
    logger.i("Attempting to load cached events...");
    try {
      final events = await getCachedEvents();
      if (events.isEmpty) {
        logger.w("No cached events found.");
      } else {
        logger.i("Loaded cached events: $events");
      }
      _eventController.add(events); // Emit data regardless of whether it's empty or not
    } catch (e) {
      logger.e("Error loading cached events: $e");
      _eventController.add([]); // Ensure an empty list is emitted if loading fails
    }
  }

  // Handle online/offline transitions
  void handleConnectivityChange(bool isOnline) {
    if (isOnline) {
      _subscribeToFirestore();
    } else {
      _firestoreSubscription?.cancel();
      _loadCachedEvents();
    }
  }

  // Cache events
  Future<void> _cacheOpenEvents(List<Event> events) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = events.map((event) {
      var eventMap = event.toMap();
      // Convert DateTime to ISO string for storage
      eventMap['date'] = event.date.toIso8601String();
      return eventMap;
    }).toList();

    await prefs.setString(_eventsKey, jsonEncode(jsonData));
    // logger.i("Cached Open Events: ${jsonEncode(jsonData)}");
    await prefs.setString("${_eventsKey}_timestamp", DateTime.now().toIso8601String());
  }

  // Get cached events
  Future<List<Event>> getCachedEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_eventsKey);
    final timeStampString = prefs.getString("${_eventsKey}_timestamp");

    if (jsonString == null || timeStampString == null) {
      return [];
    }

    final timeStamp = DateTime.parse(timeStampString);
    if (DateTime.now().difference(timeStamp) > _cacheValidDuration) {
      return []; // Cache expired
    }

    final jsonData = jsonDecode(jsonString) as List;
    return jsonData.map((item) {
      Map<String, dynamic> eventMap = item as Map<String, dynamic>;
      // Convert the ISO date string back to DateTime
      eventMap['date'] = DateTime.parse(eventMap['date']);
      return Event.fromMap(eventMap);
    }).toList();
  }

  // Clean up resources
  void dispose() {
    _firestoreSubscription?.cancel();
    _eventController.close();
  }
}