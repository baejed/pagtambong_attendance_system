import 'package:flutter/material.dart';
import 'package:pagtambong_attendance_system/generic_component.dart';
import 'package:pagtambong_attendance_system/model/UserRoles.dart';
import 'package:pagtambong_attendance_system/widgets/generic_form_fields.dart';


class CustomUsersForm extends StatelessWidget {
  final bool editMode;
  final Function(Map<String, String>) onSubmit;
  final AppUser? user;
  final VoidCallback clearForm;

  const CustomUsersForm({
    super.key,
    this.editMode = false,
    required this.onSubmit,
    this.user,
    required this.clearForm,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DefaultAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GenericFormFields(
          fields: [
            FormFieldData(key: 'firstName', label: 'First Name', isDateField: false, isTimeField: false, isChoiceField: false),
            FormFieldData(key: 'lastName', label: 'Last Name', isDateField: false, isTimeField: false, isChoiceField: false),
            FormFieldData(key: 'email', label: 'Email', isDateField: false, isTimeField: false, isChoiceField: false),
            FormFieldData(key: 'yearLevel', label: 'Year Level', isDateField: false, isTimeField: false, isChoiceField: true, dropdownOptions: ['1', '2', '3', '4']),
            FormFieldData(key: 'role', label: 'Role', isDateField: false, isTimeField: false, isChoiceField: true, dropdownOptions: ['admin', 'staff']),
          ],
          onSubmit: onSubmit,
        ),
      ),
      bottomNavigationBar: const DefaultBottomNavbar(index: 3),
    );
  }
}
