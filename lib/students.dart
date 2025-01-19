import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pagtambong_attendance_system/model/PaginatedResult.dart';
import 'package:pagtambong_attendance_system/model/Student.dart';
import 'package:pagtambong_attendance_system/service/EventService.dart';
import 'package:pagtambong_attendance_system/service/LogService.dart';

import 'generic_component.dart';

class StudentPageScreenSomethingThatIDontEvenKnowWhatThisIsAnymorePleaseHelpMe
    extends StatefulWidget {
  const StudentPageScreenSomethingThatIDontEvenKnowWhatThisIsAnymorePleaseHelpMe(
      {super.key});

  @override
  StudentPageScreenState createState() => StudentPageScreenState();
}


class StudentPageScreenState extends State<
    StudentPageScreenSomethingThatIDontEvenKnowWhatThisIsAnymorePleaseHelpMe> {
  final TextEditingController _searchStudentController =
      TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final logger = LogService();
  Timer? _debounce;
  final List<Student> _students = [];
  final StreamController<PaginatedResult<Student>> _streamController = StreamController<PaginatedResult<Student>>();

  // For the Pagination
  int _currentPage = 1;
  static const int _pageSize = 20;
  bool _isLoading = false;
  bool _hasMore = false;

  // This is for the search functionality, for further inquiries shut the fuck up
  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent * 0.8 &&
          !_isLoading &&
          _hasMore) {
        // Load More Data
        _loadMoreData();
      }
    });
  }

  Future<void> _loadMoreData() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
      _currentPage++;
    });

    // Load more shit
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      final newResult = await EventService.getAllPaginatedStudents(
        pageSize: _pageSize,
        page: _currentPage,
      ).first;

      if (newResult.items.isEmpty) {
        _hasMore = false;
      } else {
        setState(() {
          _students.addAll(newResult.items);
          _hasMore = newResult.hasMore;
        });
      }
    } catch (e) {
      logger.e("Error Loading More Data: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /*Future<void> _initializeData() async {
    setState(() {
      _isLoading = true;
    });

    _cachedStudents = await EventService.getAllStudents().first;
    _filteredStudents = _cachedStudents;

    setState(() {
      _isLoading = false;
    });
  }*/

  /*void _buildSearchIndex() {
    for (var student in _cachedStudents) {
      final key = student.firstName[0].toLowerCase();
      _searchIndex.putIfAbsent(key, () => []).add(student);
    }
  }*/

  void _onSearchChanged() {
    // Handle search input changes
    logger.i("Search input: ${_searchStudentController.text}");
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      /*if (!mounted) return;

      final searchText = _searchStudentController.text.toLowerCase();

      setState(() {
        if (searchText.isEmpty) {
          _filteredStudents = _cachedStudents;
        } else {
          // Search cached data
          _filteredStudents = _cachedStudents.where((student) {
            return student.firstName.toLowerCase().contains(searchText) ||
                student.lastName.toLowerCase().contains(searchText) ||
                student.studentId.toLowerCase().contains(searchText);
          }).toList();
        }
      });*/
      setState(() {
        _currentPage = 1;
        _hasMore = true;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    // _initializeData();
    // _buildSearchIndex();
    _setupScrollListener();
    _searchStudentController.addListener(_onSearchChanged);
  }

  /*@override
  void didChangeDependencies() {
    getClientStream();
    super.didChangeDependencies();
  }*/

  /*getClientStream() async {
    setState(() {
      _studentList = EventService.getAllStudents();
    });
  }*/

  /*searchResultList() {
    var showResults = [];
    if (_searchStudentController.text != "") {
    } else {
      // showResults = List.from(_studentList);
    }
  }*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DefaultAppBar(),
      drawer: const DefaultDrawer(),
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
            child: StreamBuilder<PaginatedResult<Student>>(
              stream: _searchStudentController.text.isEmpty
                  ? EventService.getAllPaginatedStudents(
                      page: 1, pageSize: _pageSize)
                  : EventService.getSearchResults(
                      query: _searchStudentController.text,
                      page: 1,
                      pageSize: _pageSize),
              builder: (context, snapshot) {
                // logger.i("SnapShot Type: ${snapshot.runtimeType}");
                if (snapshot.hasError) {
                  return Center(
                    child: Text("Error: ${snapshot.error}"),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final result = snapshot.data!;
                if (_currentPage == 1) {
                  _students.clear();
                  _students.addAll(result.items);
                }
                _hasMore = result.hasMore;

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: _students.length + (_hasMore ? 1 : 0),
                  itemBuilder: (content, index) {
                    if (index >= _students.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    final student = _students[index];
                    return ListTile(
                      title: Text("${index+1}. ${student.firstName} ${student.lastName}"),
                      subtitle:
                          Text("\t\t\t\t\t${student.studentId}, ${student.yearLevel}"),
                    );
                  },
                );
              },
            ),

            // This is the old implementation of the shit
            /*child: StreamBuilder<List<Student>>(
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
                      */ /*trailing: IconButton(
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
                      ),*/ /*
                    );
                  },
                );
              },
            ),*/
          ),
        ],
      ),
      bottomNavigationBar: const DefaultBottomNavbar(index: 2),
    );
  }

  @override
  void dispose() {
    _searchStudentController.removeListener(_onSearchChanged);
    _searchStudentController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }
}
