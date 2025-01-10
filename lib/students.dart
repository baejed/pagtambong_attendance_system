import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pagtambong_attendance_system/model/Student.dart';
import 'package:pagtambong_attendance_system/service/AuthService.dart';
import 'package:pagtambong_attendance_system/service/EventService.dart';
import 'package:pagtambong_attendance_system/service/LogService.dart';
import 'package:pagtambong_attendance_system/service/UserManagement.dart';

import 'generic_component.dart';
import 'model/UserRoles.dart';

class StudentPageScreenSomethingThatIDontEvenKnowWhatThisIsAnymorePleaseHelpMe
    extends StatefulWidget {
  const StudentPageScreenSomethingThatIDontEvenKnowWhatThisIsAnymorePleaseHelpMe(
      {super.key});

  @override
  StudentPageScreenState createState() => StudentPageScreenState();
}

class StudentPageScreenState extends State<
    StudentPageScreenSomethingThatIDontEvenKnowWhatThisIsAnymorePleaseHelpMe> {
  final UserManagement _userManagement = UserManagement();
  final TextEditingController _searchStudentController =
      TextEditingController();
  final logger = LogService();
  late final Stream<List<Student>> _studentList;
  late final Stream<List<Student>> _resultList;
  Timer? _debounce;

  // This is for the search functionality, for further inquiries shut the fuck up
  @override
  void initState() {
    super.initState();
    _searchStudentController.addListener(_onSearchChanged);
  }

  @override
  void didChangeDependencies() {
    getClientStream();
    super.didChangeDependencies();
  }

  getClientStream() async {
    setState(() {
      _studentList = EventService.getAllStudents();
    });
  }

  @override
  void dispose() {
    _searchStudentController.removeListener(_onSearchChanged);
    _searchStudentController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    // Handle search input changes
    logger.i("Search input: ${_searchStudentController.text}");
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {

      });
    });
  }

  searchResultList() {
    var showResults = [];
    if (_searchStudentController.text != "") {
    } else {
      // showResults = List.from(_studentList);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Students Page"),
      ),
      body: Column(
        children: [
          // Add new admin/staff form
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchStudentController,
                    decoration: const InputDecoration(
                      labelText: "Search Students",
                    ),
                  ),
                ),
                /// If you wanted to implement a filter for the search function, uncomment and change this to finalize
                /*PopupMenuButton<UserRole>(
                  onSelected: (UserRole role) {
                    if (AuthService()
                        .isEmailAuthorized(_searchStudentController.text)) {
                      _userManagement
                          .addPendingUser(_searchStudentController.text, role)
                          .then((_) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text("Student Detail updated successfully!")),
                        );
                        _searchStudentController.clear();
                      }).catchError((error) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $error')),
                        );
                        _searchStudentController.clear();
                      });
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('We only accept umindanao Email')),
                      );
                      _searchStudentController.clear();
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<UserRole>>[
                    const PopupMenuItem(
                      value: UserRole.admin,
                      child: Text("Make Admin"),
                    ),
                    const PopupMenuItem(
                      value: UserRole.staff,
                      child: Text("Make Staff"),
                    ),
                  ],
                  child: const ElevatedButton(
                    // Add Email to Firebase
                    onPressed: null,
                    child: Text("Search"),
                  ),
                ),*/
              ],
            ),
          ),

          // List of all users
          Expanded(
            child: StreamBuilder<List<Student>>(
              stream: _studentList,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final students = snapshot.data!.where((student) {
                  final searchText =
                      _searchStudentController.text.toLowerCase();
                  return student.firstName.toLowerCase().contains(searchText) ||
                      student.lastName.toLowerCase().contains(searchText) ||
                      student.studentId.toLowerCase().contains(searchText);
                }).toList();

                // logger.i("Snapshot: ${snapshot.data?.first.role}");
                return ListView.builder(
                  itemCount: students.length,
                  itemBuilder: (content, index) {
                    final student = students[index];
                    return ListTile(
                      title: Text("${student.firstName} ${student.lastName}"),
                      subtitle:
                          Text('${student.studentId}, ${student.yearLevel}'),
                      /// Uncomment and change this after finalizing the functionality of editing student's info
                      /*trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          // Show Role Edit Dialog
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Change Role'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: UserRole.values.map((role) {
                                  return ListTile(
                                    title:
                                        Text(role.toString().split('.').last),
                                    onTap: () {
                                      _userManagement.updateUserRole(
                                          student.studentId, role);
                                      Navigator.of(context).pop();
                                    },
                                  );
                                }).toList(),
                              ),
                            ),
                          );
                        },
                      ),*/
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const DefaultBottomNavbar(index: 2),
    );
  }
}
