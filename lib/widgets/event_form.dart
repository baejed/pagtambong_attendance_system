import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pagtambong_attendance_system/generic_component.dart';
import 'package:pagtambong_attendance_system/model/Event.dart';
import 'package:pagtambong_attendance_system/widgets/generic_form_fields.dart';

class CustomEventForm extends StatelessWidget {
  final bool editMode;
  final Function(Map<String, String>) onSubmit;
  final DocumentReference? docRef;
  final Event? event;

  const CustomEventForm({
    super.key,
    this.editMode = false,
    this.docRef,
    this.event,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {


    return Scaffold(
      appBar: const DefaultAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GenericFormFields(
          fields: [
            FormFieldData(key: 'eventName', label: "Event Name", isDateField: false, isTimeField: false, isChoiceField: false),
            FormFieldData(key: 'venue', label: "Venue", isDateField: false, isTimeField: false, isChoiceField: false),
            FormFieldData(key: 'organizer', label: "Organizer", isDateField: false, isTimeField: false, isChoiceField: false),
            FormFieldData(key: 'dates', label: "Date", isDateField: true, isTimeField: false, isChoiceField: false),
            FormFieldData(key: 'times', label: "Time", isDateField: false, isTimeField: true, isChoiceField: false),
          ],
          onSubmit: onSubmit,
        ),
      ),
      bottomNavigationBar: const DefaultBottomNavbar(index: 1),
    );
  }

  /*@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DefaultAppBar(),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(40, 20, 40, 0),
        child: SingleChildScrollView(
          child: EventFormFields(
            editMode: editMode,
            docRef: docRef,
            event: event,
            onSubmit: (eventModel) {
              if (editMode) {
                EventService.updateEvent(eventModel, docRef!);
              } else {
                EventService.addEvent(eventModel);
              }

              Fluttertoast.showToast(
                msg: "Event successfully ${editMode ? "updated" : "added"}",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.CENTER,
                timeInSecForIosWeb: 1,
                backgroundColor: Colors.blue,
                textColor: Colors.white,
                fontSize: 16.0,
              );

              Navigator.pop(context);
            },
          ),
        ),
      ),
      bottomNavigationBar: const DefaultBottomNavbar(index: 1),
    );
  }*/

// Overrides
}
