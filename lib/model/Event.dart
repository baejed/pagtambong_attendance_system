import 'package:flutter/material.dart';

class Event {
  String eventName;
  DateTime date;
  bool isOpen = false;
  String organizer;
  String venue;

  Event({
    required this.eventName,
    required this.date,
    required this.organizer,
    required this.venue,
    required this.isOpen,
  });

  Map<String, dynamic> toMap() {
    return {
      'event_name': eventName,
      'date': date,
      'organizer': organizer,
      'venue': venue,
      'is_open': isOpen,
    };
  }

  factory Event.fromMap(Map<String, dynamic> data) {
    return Event(
      eventName: data['event_name'] ?? '',
      date: data['date'] ?? '',
      organizer: data['organizer'] ?? '',
      venue: data['venue'] ?? '',
      isOpen: data['is_open'] ?? '',
    );
  }

}