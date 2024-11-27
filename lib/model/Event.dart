class Event {
  String docId;
  String eventName;
  DateTime date;
  bool isOpen;
  String organizer;
  String venue;

  Event({
    required this.eventName,
    required this.date,
    required this.organizer,
    required this.venue,
    required this.isOpen,
    required this.docId,
  });

  Map<String, dynamic> toMap() {
    return {
      'event_name': eventName,
      'date': date,
      'organizer': organizer,
      'venue': venue,
      'is_open': isOpen,
      'doc_id': docId
    };
  }

  factory Event.fromMap(Map<String, dynamic> data, String id) {
    return Event(
      eventName: data['event_name'] ?? '',
      date: data['date'] ?? '',
      organizer: data['organizer'] ?? '',
      venue: data['venue'] ?? '',
      isOpen: data['is_open'] ?? '',
      docId: id
    );
  }

}