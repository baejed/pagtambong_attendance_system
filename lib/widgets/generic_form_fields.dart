import 'package:flutter/material.dart';
import 'package:pagtambong_attendance_system/service/LogService.dart';

class GenericFormFields extends StatefulWidget {
  final List<FormFieldData> fields;
  final Function(Map<String, String>) onSubmit;

  const GenericFormFields({
    super.key,
    required this.fields,
    required this.onSubmit,
  });

  @override
  State createState() => _GenericFormFieldsState();
}

class _GenericFormFieldsState extends State<GenericFormFields> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, DateTime> _selectedDates = {};
  final Map<String, TimeOfDay> _selectedTime = {};
  final Map<String, String> _selectedDropdownValues = {};
  LogService logger = LogService();

  @override
  void initState() {
    super.initState();
    for (var field in widget.fields) {
      if (!field.isDateField || !field.isTimeField) {
        _controllers[field.key] = TextEditingController();
      }
      if (field.isDateField) {
        _selectedDates[field.key] = DateTime.now();
      }
      if (field.isTimeField) {
        _selectedTime[field.key] = TimeOfDay.now();
      }
    }

    for (var key in _selectedDropdownValues.keys) {
      _selectedDropdownValues[key] = widget.fields
          .firstWhere((field) => field.key == key)
          .dropdownOptions!
          .first;
    }
    // logger.i("Selected Date: ${_selectedDates.values.first}");
  } // Overrides

  void clearForm() {
    for (var controller in _controllers.values) {
      controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...widget.fields.map((field) {
          if (field.isDateField) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    field.label,
                    textAlign: TextAlign.left,
                    style: const TextStyle(fontSize: 16),
                  ),
                  SizedBox(
                    width: 1000,
                    child: TextField(
                      readOnly: true,
                      onTap: () async {
                        // logger.i("Selected Date: ${_selectedDates.values.first}");
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedDates[field.key],
                          firstDate: DateTime(2021, 1, 1),
                          lastDate: DateTime(2100, 12, 31),
                        );
                        // logger.i("The Date is: $date");
                        if (date != null) {
                          setState(() {
                            _selectedDates[field.key] = date;
                          });
                        }
                      },
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        hintText:
                            "${_selectedDates[field.key]?.year}-${_selectedDates[field.key]?.month}-${_selectedDates[field.key]?.day}",
                        contentPadding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                      ),
                    ),
                  )
                ],
              ),
            );
          } else if (field.isTimeField) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    field.label,
                    textAlign: TextAlign.left,
                    style: const TextStyle(fontSize: 16),
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
                            _selectedTime[field.key] = value!;
                          });
                        });
                      },
                      decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          hintText: _selectedTime[field.key]?.format(context),
                          contentPadding:
                              const EdgeInsets.fromLTRB(10, 0, 10, 0)),
                    ),
                  ),
                ],
              ),
            );
          } else if (field.isChoiceField) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    field.label,
                    textAlign: TextAlign.left,
                    style: const TextStyle(fontSize: 16),
                  ),
                  SizedBox(
                    width: 1000,
                    child: DropdownButton<String>(
                      value: _selectedDropdownValues[field.key],
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedDropdownValues[field.key] = newValue!;
                        });
                      },
                      items: field.dropdownOptions!
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  )
                ],
              ),
            );
          } else {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    field.label,
                    textAlign: TextAlign.left,
                    style: const TextStyle(fontSize: 16),
                  ),
                  SizedBox(
                    width: 1000,
                    child: TextField(
                      controller: _controllers[field.key],
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                      ),
                    ),
                  )
                ],
              ),
            );
          }
        }),
        OutlinedButton(
          onPressed: () {
            final formData = <String, String>{};
            for (var field in widget.fields) {
              if (field.isDateField) {
                formData[field.key] =
                    _selectedDates[field.key]!.toIso8601String();
              } else if (field.isChoiceField) {
                formData[field.key] = _selectedDropdownValues[field.key]!;
              } else if (field.isTimeField) {
                formData[field.key] = _selectedTime[field.key]!.format(context);
              } else {
                formData[field.key] = _controllers[field.key]!.text;
              }
            }
            // logger.i("Form Data: $formData");
            widget.onSubmit(formData);
          },
          child: const Text("Submit"),
        )
      ],
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}

class FormFieldData {
  final String key;
  final String label;
  final bool isDateField;
  final bool isTimeField;
  final bool isChoiceField;
  final List<String>? dropdownOptions;

  FormFieldData({
    required this.key,
    required this.label,
    required this.isDateField,
    required this.isTimeField,
    required this.isChoiceField,
    this.dropdownOptions,
  });
}
