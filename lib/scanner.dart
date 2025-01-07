import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pagtambong_attendance_system/generic_component.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pagtambong_attendance_system/model/Event.dart';
import 'package:pagtambong_attendance_system/model/Student.dart';
import 'package:pagtambong_attendance_system/model/UserRoles.dart';
import 'package:pagtambong_attendance_system/service/AttendanceService.dart';
import 'package:pagtambong_attendance_system/service/AuthService.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  // TODO: Check the currently signed in user and implement shit according to role
  final currentUser = FirebaseAuth.instance.currentUser;
  
  final CollectionReference _studentsDb =
      FirebaseFirestore.instance.collection('student-info');
  final CollectionReference _eventsDB =
      FirebaseFirestore.instance.collection('events');

  String _selectedEvent = "Select an event";
  String _output = "";
  bool _scanned = false; // this variable does nothing but I don't wanna remove it cuz it might destroy something idk

  @override
  Widget build(BuildContext context) {
    final userRole = AuthService().getUserRole(currentUser!.uid); // Role of current user

    return Scaffold(
      appBar: const DefaultAppBar(),
      body: Center(child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
        final Size layoutSize = constraints.biggest;
        const double scanWindowHeight = 100;
        const double scanWindowWidth = 300;

        final Rect scanWindow = Rect.fromCenter(
          center: layoutSize.center(Offset.zero),
          width: scanWindowWidth,
          height: scanWindowHeight,
        );

        return MobileScanner(
          controller: controller,
          scanWindow: scanWindow,
          overlayBuilder: (context, constraints) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Stack(
                children: [
                  Positioned.fill(
                      child: Align(
                    child: Container(
                      width: scanWindowWidth,
                      height: scanWindowHeight,
                      decoration: BoxDecoration(border: Border.all()),
                      child: Text(_output),
                    ),
                  )),
                  Column(
                    children: [
                      GestureDetector(
                        onTap: () {

                          setState(() {
                            // cleares the id number label when switching events
                            _output = "";
                          });

                          showModalBottomSheet<void>(
                            context: context,
                            builder: (BuildContext context) {
                              final Stream<QuerySnapshot> streamEventsDB =
                                  _eventsDB
                                      .where('is_open', isEqualTo: true)
                                      .snapshots();

                              return Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(0, 30, 0, 10),
                                child: SizedBox(
                                  height: 200,
                                  child: StreamBuilder(
                                    stream: streamEventsDB,
                                    builder: (context,
                                        AsyncSnapshot<QuerySnapshot>
                                            streamSnapshot) {
                                      if (streamSnapshot.hasData) {
                                        return ListView.builder(
                                            padding: const EdgeInsets.all(10),
                                            itemCount: streamSnapshot
                                                .data!.docs.length,
                                            itemBuilder: (context, index) {
                                              Event eventModel = Event(
                                                  eventName:
                                                      streamSnapshot.data!.docs[index]
                                                          ['event_name'],
                                                  date: (streamSnapshot.data!.docs[index]
                                                          ['date'] as Timestamp)
                                                      .toDate(),
                                                  isOpen: streamSnapshot.data!
                                                      .docs[index]['is_open'],
                                                  organizer: streamSnapshot
                                                      .data!
                                                      .docs[index]['organizer'],
                                                  venue: streamSnapshot.data!
                                                      .docs[index]['venue']);
                                              return Material(
                                                  child: ListTile(
                                                title:
                                                    Text(eventModel.eventName),
                                                subtitle:
                                                    Text(eventModel.venue),
                                                onTap: () {
                                                  setState(() {
                                                    _selectedEvent =
                                                        eventModel.eventName;
                                                  });
                                                  Navigator.pop(context);
                                                },
                                              ));
                                            });
                                      }

                                      return const Center(
                                          child: CircularProgressIndicator());
                                    },
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        child: Container(
                          color: Colors.blue[700],
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: GestureDetector(
                              child: Row(
                                children: [
                                  Text(
                                    _selectedEvent,
                                    style: const TextStyle(
                                      fontSize: 20,
                                    ),
                                  ),
                                  const Spacer(),
                                  const Icon(Icons.arrow_downward_rounded)
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                    ],
                  )
                ],
              ),
            );
          },
          onDetect: (barcodes) async {
            if (_scanned) return; // useless var
            if (_selectedEvent == "Select an event") {
              Fluttertoast.showToast(
                  msg: "Please select an event",
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.CENTER,
                  timeInSecForIosWeb: 1,
                  backgroundColor: Colors.red,
                  textColor: Colors.white,
                  fontSize: 16.0);
              return;
            }
            String output = barcodes.barcodes.first.displayValue!;
            output = output.substring(1, output.length); // removes the 's' from the scanned barcode

            QuerySnapshot student = await _studentsDb
                .where('is_deleted', isEqualTo: false)
                .where('student_id', isEqualTo: output)
                .get();
            QuerySnapshot event = await _eventsDB
                .where('is_deleted', isEqualTo: false)
                .where('event_name', isEqualTo: _selectedEvent)
                .get();

            if (student.docs.isNotEmpty && event.docs.isNotEmpty) {
              QueryDocumentSnapshot studentQueryDoc = student.docs.first;
              QueryDocumentSnapshot eventQueryDoc = event.docs.first;
              Student studentModel = Student.fromMap(
                  studentQueryDoc.data() as Map<String, dynamic>);

              String firstName = studentModel.firstName;
              DocumentReference studentDocRef = studentQueryDoc.reference;
              DocumentReference eventDocRef = eventQueryDoc.reference;

              Fluttertoast.showToast(
                  msg: firstName,
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.CENTER,
                  timeInSecForIosWeb: 1,
                  backgroundColor: Colors.blue,
                  textColor: Colors.white,
                  fontSize: 16.0);

              AttendanceService.makePresent(studentDocRef, eventDocRef);
            }

            setState(() {
              _output = output;
              // _scanned = true;
            });
          },
        );
      })),
      bottomNavigationBar: const DefaultBottomNavbar(index: 0),
    );
  }
}
