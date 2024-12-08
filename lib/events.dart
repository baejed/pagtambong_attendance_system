import 'dart:ffi';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pagtambong_attendance_system/data/college_programs.dart';
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
                  final DocumentReference eventDocRef = streamSnapshot.data!.docs[index].reference;
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
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => EventForm(
                              editMode: true, 
                              docRef: eventDocRef, 
                              event: eventModel
                            )));
                          }, 
                          icon: const Icon(Icons.edit)
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => EventParticipantManager(event: eventModel, eventDocRef: eventDocRef)));
                          }, 
                          icon: const Icon(Icons.people_alt_outlined)
                        ),
                      ],
                    ),
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
  final TextStyle labelTextStyle = const TextStyle(fontSize: 16,);
  final EdgeInsets labelTextPaddingInsets = const EdgeInsets.fromLTRB(0, 15, 0, 0);

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
              Row(
                children: [
                  Text(
                    "Event Name",
                    textAlign: TextAlign.left,
                    style: labelTextStyle,
                  ),
                ],
              ),
              SizedBox(
                width: 1000,
                child: TextField(
                  controller: eventNameController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.fromLTRB(10, 0, 10,0)
                  ),
                ),
              ),
              Padding(
                padding: labelTextPaddingInsets,
                child: Row(
                  children: [
                    Text(
                      "Venue",
                      textAlign: TextAlign.left,
                      style: labelTextStyle,
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
              Padding(
                padding: labelTextPaddingInsets,
                child: Row(
                  children: [
                    Text(
                      "Organizer",
                      textAlign: TextAlign.left,
                      style: labelTextStyle,
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
              Padding(
                padding: labelTextPaddingInsets,
                child: Row(
                  children: [
                    Text(
                      "Date",
                      textAlign: TextAlign.left,
                      style: labelTextStyle,
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
              Padding(
                padding: labelTextPaddingInsets,
                child: Row(
                  children: [
                    Text(
                      "Time",
                      textAlign: TextAlign.left,
                      style: labelTextStyle,
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
              Padding(
                padding: labelTextPaddingInsets,
                child: Row(
                  children: [
                    Text(
                      "Participants",
                      textAlign: TextAlign.left,
                      style: labelTextStyle,
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
              OutlinedButton(
                onPressed: () {

                  if(
                      eventNameController.text.isEmpty || 
                      venueController.text.isEmpty ||
                      organizerController.text.isEmpty
                    ) return;

                  Event eventModel = Event(
                      eventName: eventNameController.text, 
                      date: setTime(_date, _time), 
                      organizer: organizerController.text, 
                      venue: venueController.text, 
                      isOpen: false
                  );
          
                  edit ? EventService.updateEvent(eventModel, widget.docRef!) : EventService.addEvent(eventModel);

                  Fluttertoast.showToast(
                    msg: "Event successfuly ${edit ? "updated" : "added"}",
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.CENTER,
                    timeInSecForIosWeb: 1,
                    backgroundColor: Colors.blue,
                    textColor: Colors.white,
                    fontSize: 16.0
                  );

                  Navigator.pop(context);
                  
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

class EventParticipantManager extends StatefulWidget {

  const EventParticipantManager({super.key, required this.event, required this.eventDocRef});
  final Event event;
  final DocumentReference eventDocRef;

  @override
  State<StatefulWidget> createState() => _EventParticipantManager();

}

class _EventParticipantManager extends State<EventParticipantManager>{

  List<String> programs = Programs.programs;
  List<bool> participantYrLvl = List.filled(5, false);
  List<bool> participantProgram = List.filled(Programs.programs.length + 1, false);
  Map<int, String> yrLvlIndexMap = {
    0: "All Years",
    1: "1st Year",
    2: "2nd Year",
    3: "3rd Year",
    4: "4th Year"
  };
  // index 0 = all year level
  // index 1, 2, 3, 4 = 1st 2nd 3rd 4th

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DefaultAppBar(),
      body: Column(
        children: [
          Center(
            child: Text(
              widget.event.eventName,
            ),
          ),
          const Text("Year Level"),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: participantYrLvl.asMap().entries.map((entry) {
              int idx = entry.key;
              bool val = entry.value;
              bool disableYrLevelBoxes = participantYrLvl[0] && idx != 0; // checks if all year level is selected

              return Column(
                children: [
                  Checkbox(
                    value: val,
                    shape: const CircleBorder(),
                    onChanged: disableYrLevelBoxes 
                    ? null
                    : (value) {
                        setState(() {
                          participantYrLvl[idx] = !val;
                        });
                      }
                  ),
                  Text(
                    yrLvlIndexMap[idx]!,
                    maxLines: 2,
                    style: const TextStyle(
                      fontSize: 12
                    ),
                  )
                ],
              );
            }).toList(),
          ),
          const Text("Program"),
          Wrap(
            children: programs.asMap().entries.map((entry) {
              int idx = entry.key;
              String val = entry.value;
              bool disableProgamBoxes = participantProgram[0] && idx != 0; // checks if all year level is selected

              return Column(
                children: [
                  Checkbox(
                    value: participantProgram[idx],
                    shape: const CircleBorder(), 
                    onChanged: disableProgamBoxes
                    ? null
                    : (value) {
                      setState(() {
                        participantProgram[idx] = !participantProgram[idx];
                      });
                    }
                  ),
                  Text(
                    Programs.getProgramAlias(val),
                    style: const TextStyle(
                      fontSize: 12
                    ),
                  )
                ],
              );
            }).toList(),
          ),
          TextButton(
            onPressed: () {
              List<String> selectedYrLvl = List.empty(growable: true);
              List<String> selectedProgram = List.empty(growable: true);

              //gathers the selected programs
              for(int i = 0; i < participantProgram.length; i++){
                if(participantProgram[i]) {
                  selectedProgram.add(programs[i]);
                }
              }

              //gathers the selected year levels
              for(int i = 0; i < participantYrLvl.length; i++){
                if(participantYrLvl[i]){
                  selectedYrLvl.add(yrLvlIndexMap[i] ?? 'unknown');
                }
              }

              // ensures that the list only contains 'all' if it is selected
              if(selectedYrLvl.contains(yrLvlIndexMap[0])) selectedYrLvl = List.filled(1, yrLvlIndexMap[0]!);
              if(selectedYrLvl.contains(Programs.allProgram)) selectedProgram = List.filled(1, Programs.allProgram);

              EventService.addParticipants(widget.eventDocRef, selectedYrLvl, selectedProgram);
            }, 
            child: const Text("Submit"))
        ],
      ),
      bottomNavigationBar: const DefaultBottomNavbar(index: 1),
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