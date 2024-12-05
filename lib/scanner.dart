import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:pagtambong_attendance_system/generic_component.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:fluttertoast/fluttertoast.dart';


class ScannerPage extends StatefulWidget {

  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();

}

class _ScannerPageState extends State<ScannerPage>{

  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  final CollectionReference _studentsDb = FirebaseFirestore.instance.collection('student-info');
  final CollectionReference _eventsDB = FirebaseFirestore.instance.collection('events');


  String _selectedEvent = "Select an event";
  String _output = "none";
  bool _scanned = false;

  @override
  Widget build(BuildContext context){

    return Scaffold(
      appBar: const DefaultAppBar(),
      body: Center(
        child: LayoutBuilder(
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
                            decoration: BoxDecoration(
                              border: Border.all()
                            ),
                            child: Text(_output),
                          ),
                        )
                      ),
                      Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              showModalBottomSheet<void>(
                                context: context,
                                builder: (BuildContext context) {

                                  final Stream<QuerySnapshot> streamEventsDB = _eventsDB.where('is_open', isEqualTo: true).snapshots();

                                  return Padding(
                                    padding: const EdgeInsets.fromLTRB(0, 30, 0, 10),
                                    child: SizedBox(
                                      height: 200,
                                      child: StreamBuilder(
                                        stream: streamEventsDB,
                                        builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
                                    
                                          if(streamSnapshot.hasData) {
                                            return ListView.builder(
                                              padding: const EdgeInsets.all(10),
                                              itemCount: streamSnapshot.data!.docs.length,
                                              itemBuilder: (context, index) {
                                                final DocumentSnapshot documentSnapshot = streamSnapshot.data!.docs[index];
                                                return Material(child: ListTile(
                                                  title: Text(documentSnapshot['event_name']),
                                                  subtitle: Text(documentSnapshot['venue']),  
                                                  onTap: () {
                                                    setState(() {
                                                      _selectedEvent = documentSnapshot['event_name'];
                                                    });
                                                    Navigator.pop(context);
                                                  },
                                                ));
                                            });
                                          }
                                    
                                          return const Center(child: CircularProgressIndicator(),);
                                    
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
              onDetect: (barcodes) {
                if(_scanned) return;
                if(_selectedEvent == "Select an event") {
                  Fluttertoast.showToast(
                    msg: "Please select an event",
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.CENTER,
                    timeInSecForIosWeb: 1,
                    backgroundColor: Colors.red,
                    textColor: Colors.white,
                    fontSize: 16.0
                  );
                  return;
                }
                String output = barcodes.barcodes.first.displayValue!;
                output = output.substring(1, output.length);

                Query students = _studentsDb.where('student_id', isEqualTo: output);
                Stream<QuerySnapshot> studentSnapshot = students.snapshots();

                students.get().then((value) {
                  if(value.docs.isNotEmpty){
                    String firstName = value.docs.first['first_name'];

                    setState(() {
                      _scanned = true;
                    });

                    showDialog(
                      context: context, 
                      builder: (BuildContext context) {
                        return AlertDialog(
                            title: Text("Confirmation"),
                            content: Text(firstName),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  setState(() {
                                    _scanned = false;
                                  });
                                },
                                child: const Text("Okay"),
                              )
                            ],
                          );
                      }
                    );
                  }
                });

                // showDialog(
                //   context: context, 
                //   barrierDismissible: false,
                //   builder: (BuildContext context) {


                //     return StreamBuilder(
                //       stream: studentSnapshot, 
                //       builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {

                //         if(streamSnapshot.hasData && streamSnapshot.data!.docs.isNotEmpty){

                //           String firstName = streamSnapshot.data!.docs.first['first_name'];

                //           return AlertDialog(
                //             title: Text("Confirmation"),
                //             content: Text(firstName),
                //             actions: [
                //               TextButton(
                //                 onPressed: () {
                //                   Navigator.pop(context);
                //                   setState(() {
                //                     _scanned = false;
                //                   });
                //                 },
                //                 child: Text("Okay"),
                //               )
                //             ],
                //           );
                          
                //         }

                //         if(streamSnapshot.connectionState == ConnectionState.waiting){
                //           return AlertDialog(
                //             title: Text("LOADING"),
                //             content: Text("searching student"),
                //           );
                //         }

                //         return SizedBox.shrink();

                //       }
                //     );
                //   }
                // );

                setState(() {
                  _output = output;
                  // _scanned = true;
                });

              },
            );
          }
        )
      ),
      bottomNavigationBar: const DefaultBottomNavbar(
        index: 0
      ),
    );
  }

}

String showSelectEventModal(BuildContext context){

  String selectedEvent = "Select edvent";

  

  return selectedEvent;
}

bool _dialogBuilder(BuildContext context, String name) {

  AlertDialog(
    title: const Text('Basic dialog title'),
    content: const Text(
      'A dialog is a type of modal window that\n'
      'appears in front of app content to\n'
      'provide critical information, or prompt\n'
      'for a decision to be made.',
    ),
    actions: <Widget>[
      TextButton(
        style: TextButton.styleFrom(
          textStyle: Theme.of(context).textTheme.labelLarge,
        ),
        child: const Text('Disable'),
        onPressed: () {
          Navigator.of(context).pop();
        },
      ),
      TextButton(
        style: TextButton.styleFrom(
          textStyle: Theme.of(context).textTheme.labelLarge,
        ),
        child: const Text('Enable'),
        onPressed: () {
          Navigator.of(context).pop();
        },
      ),
    ],
  );

  return false;
}