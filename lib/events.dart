import 'dart:ffi';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pagtambong_attendance_system/generic_component.dart';
import 'package:pagtambong_attendance_system/model/Event.dart';
import 'package:pagtambong_attendance_system/service/EventDatabase.dart';
import 'package:provider/provider.dart';


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
      floatingActionButton: const FloatingActionButton(
        onPressed: null,
        child: Icon(Icons.add),  
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

  @override
  Widget build(BuildContext context) {
    
    return const Column(
      children: [
        TextField(),
        TextField()
      ],
    );
    
  }

}

void showAddEventModal(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const EventForm())
  );
}
