import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pagtambong_attendance_system/data/college_programs.dart';
import 'package:pagtambong_attendance_system/generic_component.dart';
import 'package:pagtambong_attendance_system/model/AttendanceItem.dart';
import 'package:pagtambong_attendance_system/model/Event.dart';
import 'package:pagtambong_attendance_system/model/Student.dart';
import 'package:pagtambong_attendance_system/resources/CheckgaColors.dart';
import 'package:pagtambong_attendance_system/service/EventService.dart';
import 'package:date_picker_plus/date_picker_plus.dart';
import 'package:pagtambong_attendance_system/service/LogService.dart';
import 'package:pagtambong_attendance_system/widgets/event_form.dart';


// TODO: add feedback when adding an event, properly dispose the controllers

// this is the main page of the page
class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  final CollectionReference _eventsDB =
      FirebaseFirestore.instance.collection('events');
  late Stream<QuerySnapshot> _streamEventsDB;
  LogService logger = LogService();

  @override
  void initState() {
    super.initState();
    _streamEventsDB =
        _eventsDB.where('is_deleted', isEqualTo: false).snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DefaultAppBar(),
      body: Center(
          child: StreamBuilder(
        stream: _streamEventsDB,
        builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
          if (streamSnapshot.hasData) {
            return ListView.builder(
                itemCount: streamSnapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final DocumentReference eventDocRef =
                      streamSnapshot.data!.docs[index].reference;
                  final Event eventModel = Event(
                      eventName: streamSnapshot.data!.docs[index]['event_name'],
                      date: (streamSnapshot.data!.docs[index]['date']
                              as Timestamp)
                          .toDate(),
                      isOpen: streamSnapshot.data!.docs[index]['is_open'],
                      organizer: streamSnapshot.data!.docs[index]['organizer'],
                      venue: streamSnapshot.data!.docs[index]['venue']);

                  return Material(
                      child: ListTile(
                    title: Text(
                      eventModel.eventName,
                      style: const TextStyle(
                        color: AppColors.darkFontColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 16
                      ),
                    ),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => EventParticipantPage(eventDoc: eventDocRef, eventName: eventModel.eventName,)));
                    },
                    onLongPress: () {
                      EventService.toggleOpenEvent(eventModel.eventName);
                    },
                    subtitle: Row(
                      children: [
                        Icon(
                          Icons.circle,
                          color: eventModel.isOpen
                              ? Colors.lightGreenAccent[400]
                              : Colors.redAccent[700],
                          size: 10,
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8.0, 0, 0, 0),
                          child: Text(
                            eventModel.isOpen ? "Open" : "Closed",
                            style: const TextStyle(
                              color: AppColors.subtitleFontColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => EventForm(
                                          editMode: true,
                                          docRef: eventDocRef,
                                          event: eventModel)));
                            },
                            icon: const Icon(
                              Icons.edit,
                              color: AppColors.acccentFontColor,
                            )),
                        IconButton(
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          EventParticipantManager(
                                              event: eventModel,
                                              eventDocRef: eventDocRef)));
                            },
                            icon: const Icon(
                              Icons.group_add,
                              color: AppColors.acccentFontColor
                            )),
                      ],
                    ),
                  ));
                });
          }

          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      )),
      bottomNavigationBar: const DefaultBottomNavbar(index: 1),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => CustomEventForm(
                        onSubmit: (Map<String, String> formData) {
                          try {
                            final DateTime date =
                                DateTime.parse(formData['dates']!);
                            logger.i("Date Type: ${date.runtimeType}");
                            final TimeOfDay time =
                                parseTimeString(formData['times']!);
                            Event eventModel = Event(
                              eventName: formData['eventName']!,
                              venue: formData['venue']!,
                              organizer: formData['organizer']!,
                              date: setTime(date, time),
                              isOpen: false,
                            );
                            EventService.addEvent(eventModel);

                            Fluttertoast.showToast(
                              msg: "Event successfully added",
                              toastLength: Toast.LENGTH_SHORT,
                              gravity: ToastGravity.CENTER,
                              timeInSecForIosWeb: 1,
                              backgroundColor: Colors.blue,
                              textColor: Colors.white,
                              fontSize: 16.0,
                            );

                            Navigator.pop(context);
                          } catch (e) {
                            logger.e("$e");
                          }
                          // logger.i("Date: ${formData['date']}");
                          // logger.i("Time: ${formData['time']}");
                        },
                      )));
          // Navigator.push(context, MaterialPageRoute(builder: (context) => const EventForm()));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// TODO: Need to use this EventForm for the editing of details of students
class EventForm extends StatefulWidget {
  const EventForm({super.key, this.editMode = false, this.docRef, this.event});

  final bool editMode;
  final DocumentReference? docRef;
  final Event? event;

  @override
  State<StatefulWidget> createState() => _EventFormState();
}

class _EventFormState extends State<EventForm> {
  final CollectionReference _eventsDB =
      FirebaseFirestore.instance.collection('events');
  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();
  final eventNameController = TextEditingController();
  final venueController = TextEditingController();
  final organizerController = TextEditingController();
  final TextStyle labelTextStyle = const TextStyle(
    fontSize: 16,
  );
  final EdgeInsets labelTextPaddingInsets =
      const EdgeInsets.fromLTRB(0, 15, 0, 0);

  @override
  Widget build(BuildContext context) {
    final bool edit =
        (widget.editMode && widget.docRef != null && widget.event != null);

    if (edit) {
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
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.fromLTRB(10, 0, 10, 0)),
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
                        contentPadding: EdgeInsets.fromLTRB(10, 0, 10, 0)),
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
                        contentPadding: EdgeInsets.fromLTRB(10, 0, 10, 0)),
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
                        contentPadding:
                            const EdgeInsets.fromLTRB(10, 0, 10, 0)),
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
                        contentPadding:
                            const EdgeInsets.fromLTRB(10, 0, 10, 0)),
                  ),
                ),
                OutlinedButton(
                    onPressed: () {
                      if (eventNameController.text.isEmpty ||
                          venueController.text.isEmpty ||
                          organizerController.text.isEmpty) {
                        return;
                      }

                      Event eventModel = Event(
                          eventName: eventNameController.text,
                          date: setTime(_date, _time),
                          organizer: organizerController.text,
                          venue: venueController.text,
                          isOpen: false);

                      edit
                          ? EventService.updateEvent(eventModel, widget.docRef!)
                          : EventService.addEvent(eventModel);

                      Fluttertoast.showToast(
                          msg:
                              "Event successfuly ${edit ? "updated" : "added"}",
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.CENTER,
                          timeInSecForIosWeb: 1,
                          backgroundColor: Colors.blue,
                          textColor: Colors.white,
                          fontSize: 16.0);

                      Navigator.pop(context);
                    },
                    child: const Text("Submit")),
              ],
            ),
          )),
      bottomNavigationBar: const DefaultBottomNavbar(index: 1),
    );
  }
}

class EventParticipantManager extends StatefulWidget {
  const EventParticipantManager(
      {super.key, required this.event, required this.eventDocRef});

  final Event event;
  final DocumentReference eventDocRef;

  @override
  State<StatefulWidget> createState() => _EventParticipantManager();
}

class _EventParticipantManager extends State<EventParticipantManager> {
  List<String> programs = Programs.programs;
  List<bool> participantYrLvl = List.filled(5, false);
  List<bool> participantProgram =
      List.filled(Programs.programs.length + 1, false);
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
              bool disableYrLevelBoxes = participantYrLvl[0] &&
                  idx != 0; // checks if all year level is selected

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
                            }),
                  Text(
                    yrLvlIndexMap[idx]!,
                    maxLines: 2,
                    style: const TextStyle(fontSize: 12),
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
              bool disableProgamBoxes = participantProgram[0] &&
                  idx != 0; // checks if all year level is selected

              return Column(
                children: [
                  Checkbox(
                      value: participantProgram[idx],
                      shape: const CircleBorder(),
                      onChanged: disableProgamBoxes
                          ? null
                          : (value) {
                              setState(() {
                                participantProgram[idx] =
                                    !participantProgram[idx];
                              });
                            }),
                  Text(
                    Programs.getProgramAlias(val),
                    style: const TextStyle(fontSize: 12),
                  )
                ],
              );
            }).toList(),
          ),
          TextButton(
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (context) => Dialog(
                          child: AddParticipantDialog(
                              eventDocRef: widget.eventDocRef),
                        ));
              },
              child: const Text("Add a participant")),
          TextButton(
              onPressed: () {
                List<String> selectedYrLvl = List.empty(growable: true);
                List<String> selectedProgram = List.empty(growable: true);

                //gathers the selected programs
                for (int i = 0; i < participantProgram.length; i++) {
                  if (participantProgram[i]) {
                    selectedProgram.add(programs[i]);
                  }
                }

                //gathers the selected year levels
                for (int i = 0; i < participantYrLvl.length; i++) {
                  if (participantYrLvl[i]) {
                    selectedYrLvl.add(yrLvlIndexMap[i] ?? 'unknown');
                  }
                }

                // ensures that the list only contains 'all' if it is
                if (selectedYrLvl.contains(yrLvlIndexMap[0])) {
                  selectedYrLvl = List.filled(1, yrLvlIndexMap[0]!);
                }
                if (selectedYrLvl.contains(Programs.allProgram)) {
                  selectedProgram = List.filled(1, Programs.allProgram);
                }

                EventService.addParticipants(
                    widget.eventDocRef, selectedYrLvl, selectedProgram);
              },
              child: const Text("Submit")),
        ],
      ),
      bottomNavigationBar: const DefaultBottomNavbar(index: 1),
    );
  }
}

void showAddEventModal(BuildContext context) {
  Navigator.push(
      context, MaterialPageRoute(builder: (context) => const EventForm()));
}

DateTime setTime(DateTime dateTime, TimeOfDay time) {
  return DateTime(
      dateTime.year, dateTime.month, dateTime.day, time.hour, time.minute);
}

TimeOfDay parseTimeString(String timeString) {
  // Split into time and period (AM/PM)
  final parts = timeString.split(' ');
  final timePart = parts[0];
  final period = parts[1];

  // Split hours and minutes
  final timeComponents = timePart.split(':');
  int hours = int.parse(timeComponents[0]);
  final minutes = int.parse(timeComponents[1]);

  // Convert to 24-hour format if PM
  if (period == 'PM' && hours != 12) {
    hours += 12;
  } else if (period == 'AM' && hours == 12) {
    hours = 0;
  }

  return TimeOfDay(hour: hours, minute: minutes);
}

class AddParticipantDialog extends StatefulWidget {
  const AddParticipantDialog({super.key, required this.eventDocRef});

  final DocumentReference eventDocRef;

  @override
  State<StatefulWidget> createState() => _AddParticipantWidgetState();
}

class _AddParticipantWidgetState extends State<AddParticipantDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                labelText: "Student ID",
              ),
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6)
              ],
              controller: _controller),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
            child: TextButton(
                onPressed: () async {
                  await EventService.addParticipantWithId(
                      widget.eventDocRef, _controller.text.toString());
                },
                child: const Text("Submit")),
          )
        ],
      ),
    );
  }
}

class EventParticipantPage extends StatefulWidget {

  const EventParticipantPage({super.key, required this.eventDoc, required this.eventName});

  final DocumentReference eventDoc;
  final String eventName;
  
  @override
  State<StatefulWidget> createState() => _EventParticipantPageState();
  
}

class _EventParticipantPageState extends State<EventParticipantPage> {

  final CollectionReference attendanceItemDb = FirebaseFirestore.instance.collection('attendance-item');

  @override
  Widget build(BuildContext context) {

    final Stream<QuerySnapshot> eventParticipantsStream = attendanceItemDb
      .where('event', isEqualTo: widget.eventDoc)
      .orderBy('student_id', descending: false)
      .snapshots();

    return Scaffold(
      appBar: const DefaultAppBar(),
      body: Center(
        child: Column(
          children: [
            Text(widget.eventName),
            Expanded(
              child: StreamBuilder(
                stream: eventParticipantsStream,
                builder: (conext, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
                  if (streamSnapshot.hasData) {
                    return ListView.builder(
                      itemCount: streamSnapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final docSnapshot = streamSnapshot.data!.docs[index];
                        final Map<String, dynamic> data = docSnapshot.data() as Map<String, dynamic>;
                        final AttendanceItem attendanceItem = AttendanceItem.fromMap(data);

                        return FutureBuilder(
                          future: attendanceItem.student.get(), 
                          builder: (context, futureSnapshot) {
                            if (futureSnapshot.connectionState == ConnectionState.waiting) {
                              // Show a loading indicator while fetching the student
                              return const ListTile(
                                title: Text("Loading student info..."),
                              );
                            }
                    
                            if (futureSnapshot.hasData && futureSnapshot.data != null) {
                              final Map<String, dynamic> studentData = futureSnapshot.data!.data() as Map<String, dynamic>;
                              final Student student = Student.fromMap(studentData);
                    
                              return ListTile(
                                title: Text(student.firstName),
                                subtitle: Text(student.studentId),
                                trailing: (attendanceItem.isPresent) 
                                  ? const Icon(
                                    Icons.check,
                                    color: Colors.green,
                                  )
                                  : null
                                ,
                              );
                            }
                    
                            // Handle the case where no student data is found
                            return const ListTile(
                              title: Text("Student not found"),
                            );
                          }
                        );
                    
                        // return Material(
                        //   child: ListTile(
                        //     title: Text(docSnapshot['is_present'].toString()),
                        //   ),
                        // );
                    
                      }
                    );
                  }
                    
                  if (streamSnapshot.connectionState == ConnectionState.waiting){
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                    
                  return const Center(
                    child: Text("No participants found"),
                  );
                }),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const DefaultBottomNavbar(index: 1),
    );

  }

}