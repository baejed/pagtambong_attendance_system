import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pagtambong_attendance_system/model/Event.dart';

class EventFormFields extends StatefulWidget {
  final bool editMode;
  final DocumentReference? docRef;
  final Event? event;
  final Function(Event) onSubmit;

  const EventFormFields({
    super.key,
    required this.editMode,
    this.docRef,
    this.event,
    required this.onSubmit,
  });

  @override
  State createState() => EventFormFieldsState();
}

class EventFormFieldsState extends State<EventFormFields> {
  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();
  final eventNameController = TextEditingController();
  final venueController = TextEditingController();
  final organizerController = TextEditingController();
  final TextStyle labelTextStyle = const TextStyle(fontSize: 16);
  final EdgeInsets labelTextPaddingInsets =
      const EdgeInsets.fromLTRB(0, 15, 0, 0);

  @override
  void initState() {
    super.initState();
    if (widget.editMode && widget.event != null) {
      eventNameController.text = widget.event!.eventName;
      venueController.text = widget.event!.venue;
      organizerController.text = widget.event!.organizer;
      _date = widget.event!.date;
      _time = TimeOfDay.fromDateTime(widget.event!.date);
    }
  } // Overrides

  @override
  Widget build(BuildContext context) {
    return Column(
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
              contentPadding: EdgeInsets.fromLTRB(10, 0, 10, 0),
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
              contentPadding: EdgeInsets.fromLTRB(10, 0, 10, 0),
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
              contentPadding: EdgeInsets.fromLTRB(10, 0, 10, 0),
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
              final date = await showDatePicker(
                context: context,
                firstDate: DateTime(2021, 1, 1),
                lastDate: DateTime(2100, 12, 31),
                initialDate: _date,
              );
              if (date != null) {
                setState(() {
                  _date = date;
                });
              }
            },
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: "${_date.year}-${_date.month}-${_date.day}",
              contentPadding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
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
              final time = await showTimePicker(
                context: context,
                initialTime: _time,
              );
              if (time != null) {
                setState(() {
                  _time = time;
                });
              }
            },
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: _time.format(context),
              contentPadding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
            ),
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
              date: DateTime(
                _date.year,
                _date.month,
                _date.day,
                _time.hour,
                _time.minute,
              ),
              organizer: organizerController.text,
              venue: venueController.text,
              isOpen: false,
            );
            widget.onSubmit(eventModel);
          },
          child: const Text("Submit"),
        ),
      ],
    );
  }
}
