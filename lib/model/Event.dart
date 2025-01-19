import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
      'date': date.toIso8601String(),
      'organizer': organizer,
      'venue': venue,
      'is_open': isOpen,
    };
  }
  // getFormatedTimeString() {
  //   return DateFormat('h:mm a').format(date);
  // }

  factory Event.fromMap(Map<String, dynamic> data) {
    try {
      return Event(
        eventName: data['event_name'] ?? 'Unnamed Event',
        date: data['date'] is Timestamp
            ? (data['date'] as Timestamp).toDate()
            : (data['date'] is String
            ? DateTime.parse(data['date'])
            : DateTime.now()),
        organizer: data['organizer'] ?? 'Unknown Organizer',
        venue: data['venue'] ?? 'Unknown Venue',
        isOpen: data['is_open'] ?? false,
      );
    } catch (e) {
      print('Error parsing event: $e');
      throw Exception('Invalid Event Data');
    }
  }

  getFormatedDateTimeString() {
    return DateFormat('MMMM d, yyyy, h:mm a').format(date); // Formats date like 'December 10, 2024'
  }

  getFormatedDateString() {
    return DateFormat('MMMM d, yyyy').format(date); // Formats date like 'December 10, 2024'
  }

  getFormatedTimeString() {
    return DateFormat('h:mm a').format(date); // Formats date like 'December 10, 2024'
  }
}
