import 'dart:ffi';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pagtambong_attendance_system/generic_component.dart';
import 'package:pagtambong_attendance_system/model/Event.dart';
import 'package:pagtambong_attendance_system/service/EventDatabase.dart';
import 'package:provider/provider.dart';
import 'package:date_picker_plus/date_picker_plus.dart';

// TODO: add feedback when adding an event, properly dispose the controllers

class EventsPage extends StatefulWidget {

  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();

}

class _EventsPageState extends State<EventsPage>{

  final CollectionReference _eventsDB = FirebaseFirestore.instance.collection('events');
  late Stream<QuerySnapshot> _streamEventsDB;

  @override
  void initState() {
    super.initState();
    _streamEventsDB = _eventsDB.snapshots();
  }
  @override
  Widget build(BuildContext context){

    return Scaffold(
      appBar: const DefaultAppBar(),
      body: Center(
        child: StreamBuilder(
          stream: _streamEventsDB,
          builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {

            if(streamSnapshot.hasData) {
              return ListView.builder(
                itemCount: streamSnapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final DocumentSnapshot documentSnapshot = streamSnapshot.data!.docs[index];
                  return Material(child: ListTile(
                    title: Text(documentSnapshot['event_name']),
                    subtitle: Text(documentSnapshot['venue']),  
                  ));
              });
            }

            return const Center(child: CircularProgressIndicator(),);

          },
        )
      ),
      bottomNavigationBar: const DefaultBottomNavbar(
        index: 1
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const EventForm()));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class EventForm extends StatefulWidget {

  const EventForm({super.key});

  @override
  State<StatefulWidget> createState() => _EventFormState();

}

class _EventFormState extends State<EventForm> {

  final CollectionReference _eventsDB = FirebaseFirestore.instance.collection('events');
  DateTime _date = DateTime.now();
  final eventNameController = TextEditingController();
  final venueController = TextEditingController();
  final organizerController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: const DefaultAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Row(
                children: [
                  Text(
                    "Event Name",
                    textAlign: TextAlign.left,
                    style: TextStyle(fontSize: 24),
                  ),
                ],
              ),
              SizedBox(
                width: 1000,
                child: TextField(
                  controller: eventNameController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(0,20,0,0),
                child: Row(
                  children: [
                    Text(
                      "Venue",
                      textAlign: TextAlign.left,
                      style: TextStyle(fontSize: 24),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 1000,
                child: TextField(
                  controller: venueController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(0,20,0,0),
                child: Row(
                  children: [
                    Text(
                      "Organizer",
                      textAlign: TextAlign.left,
                      style: TextStyle(fontSize: 24),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 1000,
                child: TextField(
                  controller: organizerController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(0,20,0,0),
                child: Row(
                  children: [
                    Text(
                      "Date",
                      textAlign: TextAlign.left,
                      style: TextStyle(fontSize: 24),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 1000,
                child: TextField(
                  readOnly: true,
                  onTap: () async {
                    final date = await showDatePickerDialog(
                      context: context,
                      minDate: DateTime(2021, 1, 1),
                      maxDate: DateTime(2023, 12, 31),
                    );
                    setState(() {
                      _date = date!;
                    });
                  },
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    hintText: "${_date.year}-${_date.month}-${_date.day}"
                  ),
                ),
              ),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    if(
                      eventNameController.text.isEmpty || 
                      venueController.text.isEmpty ||
                      organizerController.text.isEmpty
                    ) return;

                    Event event = Event(
                      eventName: eventNameController.text, 
                      date: _date, 
                      organizer: organizerController.text, 
                      venue: venueController.text, 
                      isOpen: false
                    );

                    _eventsDB.add(event.toMap());

                  });
                }, 
                child: const Text("Submit")
              ),
            ],
          ),
        )
      ),
      bottomNavigationBar: const DefaultBottomNavbar(
        index: 1
      ),
    );
    
  }

}

void showAddEventModal(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const EventForm())
  );
}
