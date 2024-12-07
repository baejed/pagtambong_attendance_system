import 'dart:ffi';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pagtambong_attendance_system/generic_component.dart';
import 'package:pagtambong_attendance_system/model/Event.dart';
import 'package:pagtambong_attendance_system/service/EventService.dart';
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
    _streamEventsDB = _eventsDB.where('is_deleted', isEqualTo: false).snapshots();
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
                  final Event eventModel = Event(
                    eventName: streamSnapshot.data!.docs[index]['event_name'],
                    date: (streamSnapshot.data!.docs[index]['date'] as Timestamp).toDate(),
                    isOpen: streamSnapshot.data!.docs[index]['is_open'],
                    organizer: streamSnapshot.data!.docs[index]['organizer'],
                    venue: streamSnapshot.data!.docs[index]['venue']
                  );

                  return Material(child: ListTile(
                    title: Text(eventModel.eventName),
                    subtitle: Row(
                      children: [
                        Icon(
                          Icons.circle,
                          color: eventModel.isOpen ? Colors.lightGreenAccent[400] : Colors.redAccent[700],
                          size: 10,
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8.0, 0, 0, 0),
                          child: Text(eventModel.isOpen ? "Open" : "Closed"),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      onPressed: () {
                        // EventForm(editMode: true, docRef: streamSnapshot.data!.docs[index].reference);
                        Navigator.push(context, MaterialPageRoute(builder: (context) => EventForm(
                          editMode: true, 
                          docRef: streamSnapshot.data!.docs[index].reference, 
                          event: eventModel
                        )));
                      }, 
                      icon: const Icon(Icons.edit)),
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
  const EventForm({super.key, this.editMode = false, this.docRef, this.event});

  final bool editMode;
  final DocumentReference? docRef;
  final Event? event;

  @override
  State<StatefulWidget> createState() => _EventFormState();

}

class _EventFormState extends State<EventForm> {

  final CollectionReference _eventsDB = FirebaseFirestore.instance.collection('events');
  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();
  final eventNameController = TextEditingController();
  final venueController = TextEditingController();
  final organizerController = TextEditingController();

  @override
  Widget build(BuildContext context) {

    final bool edit = (widget.editMode && widget.docRef != null && widget.event != null);

    if(edit){
      eventNameController.text = widget.event!.eventName;
      venueController.text = widget.event!.venue;
      organizerController.text = widget.event!.organizer;
      setState(() {
        _date = widget.event!.date;
        _time = TimeOfDay.fromDateTime(widget.event!.date);
      });
    }
    
    return Scaffold(
      appBar: const DefaultAppBar(),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(40, 20, 40, 0),
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
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.fromLTRB(10, 0, 10,0),
                    // hintText: editMode ?  : "dasda"
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
                    contentPadding: EdgeInsets.fromLTRB(10, 0, 10,0)
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
                    contentPadding: EdgeInsets.fromLTRB(10, 0, 10,0)
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
                      maxDate: DateTime(2100, 12, 31),
                    );
                    setState(() {
                      _date = date!;
                    });
                  },
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    hintText: "${_date.year}-${_date.month}-${_date.day}",
                    contentPadding: const EdgeInsets.fromLTRB(10, 0, 10,0)
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(0,20,0,0),
                child: Row(
                  children: [
                    Text(
                      "Time",
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
                    
                    showTimePicker(
                      initialTime: TimeOfDay.now(),
                      context: context,
                    ).then((value) {
                      setState(() {
                        _time = value!;
                      });
                    });
          
                  },
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    hintText: _time.format(context),
                    contentPadding: const EdgeInsets.fromLTRB(10, 0, 10,0)
                  ),
                ),
              ),
              OutlinedButton(
                onPressed: () {

                  if(
                      eventNameController.text.isEmpty || 
                      venueController.text.isEmpty ||
                      organizerController.text.isEmpty
                    ) return;

                  Event event = Event(
                      eventName: eventNameController.text, 
                      date: setTime(_date, _time), 
                      organizer: organizerController.text, 
                      venue: venueController.text, 
                      isOpen: false
                  );
          
                  edit ? EventService.updateEvent(event, widget.docRef!) : _eventsDB.add(event.toMap());
                  
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

DateTime setTime(DateTime dateTime, TimeOfDay time) {
  return DateTime(dateTime.year, dateTime.month, dateTime.day, time.hour, time.minute);
}