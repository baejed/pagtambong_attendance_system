import 'dart:async';

import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:pagtambong_attendance_system/generic_component.dart';
import 'package:pagtambong_attendance_system/model/PaginatedResult.dart';
import 'package:pagtambong_attendance_system/model/UserRoles.dart';
import 'package:pagtambong_attendance_system/service/AuthService.dart';
import 'package:pagtambong_attendance_system/service/LogService.dart';
import 'package:pagtambong_attendance_system/service/UserManagement.dart';
import 'package:pagtambong_attendance_system/widgets/users_form.dart';

// For Testing Purposes Only
/*class SuperAdminMain extends StatefulWidget {
  const SuperAdminMain({super.key});

  @override
  State createState() => _SuperAdminMain();
}

class _SuperAdminMain extends State<SuperAdminMain> {
  List<String> tasks = ['Task 1', 'Task 2', 'Task 3'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Super Admin Shit"),
      ),
      body: ListView.builder(
        itemBuilder: (context, index) {
          final task = tasks[index];
          return Dismissible(
            key: Key(task),
            background: Container(
              color: Colors.green,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Icon(
                Icons.edit,
                color: Colors.white,
              ),
            ),
            secondaryBackground: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Icon(
                Icons.delete,
                color: Colors.white,
              ),
            ),
            onDismissed: (direction) {
              if (direction == DismissDirection.endToStart) {
                // Swipe to delete
                setState(() {
                  tasks.removeAt(index);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("$task deleted")),
                );
              } else if (direction == DismissDirection.startToEnd) {
                // Swipe to Edit
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Edit $task (swiped right)")),
                );
              }
            },
            child: ListTile(
              title: Text(task),
            ),
          );
        },
      ),
    );
  }
}*/

class ManageUseringScreenPleaseHelpMeThisIsNotHealthyForMyMentalHealthIThinkIAmGoingInsaneWithThisProject
    extends StatefulWidget {
  const ManageUseringScreenPleaseHelpMeThisIsNotHealthyForMyMentalHealthIThinkIAmGoingInsaneWithThisProject(
      {super.key});

  @override
  State<StatefulWidget> createState() => ManageUsersScreen();
}

// Admin Page to Manager Users
class ManageUsersScreen extends State<
    ManageUseringScreenPleaseHelpMeThisIsNotHealthyForMyMentalHealthIThinkIAmGoingInsaneWithThisProject> {
  final UserManagement _userManagement = UserManagement();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _searchUserController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;
  final logger = LogService();
  late final AppUser user;

  // For the Pagination
  int _currentPage = 1;
  static const int _pageSize = 20;
  bool _isLoading = false;
  bool _hasMore = false;

  //  This is for the search functionality, for further inquiries shut the fuck up
  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent * 0.8 &&
          _isLoading &&
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

    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _isLoading = false;
    });
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _currentPage = 1;
        _hasMore = true;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    // AuthService().logSampleData();
    _setupScrollListener();
    _searchUserController.addListener(_onSearchChanged);
  } // ManageUsersScreen({super.key});

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
                    controller: _searchUserController,
                    decoration: const InputDecoration(
                      labelText: "Search Users",
                    ),
                  ),
                ),
                /*PopupMenuButton<UserRole>(
                  onSelected: (UserRole role) {
                    // TODO: After selecting role, invoke another PopMenuButton to get the Year level of the user then set it to the AppUser Model
                    if (AuthService()
                        .isEmailAuthorized(_emailController.text)) {
                      user.email = _emailController.text;
                      user.role = role;
                      _userManagement
                          .addPendingUser(user)
                          .then((_) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("User Role updated successfully!")),
                        );
                        _emailController.clear();
                      }).catchError((error) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $error')),
                        );
                        _emailController.clear();
                      });
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('We only accept umindanao Email')),
                      );
                      _emailController.clear();
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
                    child: Text("Set Role"),
                  ),
                ),*/
              ],
            ),
          ),

          // List of all users
          Expanded(
            child: StreamBuilder<PaginatedResult<AppUser>>(
              stream: _searchUserController.text.isEmpty
                  ? AuthService.getAllPaginatedUsers(
                      page: _currentPage, pageSize: _pageSize)
                  : AuthService.getSearchResults(
                      query: _searchUserController.text,
                      page: _currentPage,
                      pageSize: _pageSize),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  // logger.i("SnapShot Type: ${snapshot.runtimeType}");
                  logger.e("Error: $snapshot");
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
                logger.i("Result: ${result.items}");
                _hasMore = result.hasMore;

                logger.i("Snapshot: ${result.items.first}");
                return ListView.builder(
                  controller: _scrollController,
                  itemCount: result.items.length + (_hasMore ? 1 : 0),
                  itemBuilder: (content, index) {
                    if (index >= result.items.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    final user = result.items[index];
                    logger.i("Uset Name: ${user.firstName} ${user.lastName}");
                    return ListTile(
                      title: Text("${user.firstName} ${user.lastName}"),
                      subtitle: Text('Role: ${user.role.name}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          // Show Role Edit Dialog
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text(
                                'Change Role',
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: UserRole.values.map((role) {
                                  return ListTile(
                                    title:
                                        Text(role.toJson()),
                                    onTap: () {
                                      _userManagement.updateUserRole(
                                        user.email,
                                        role,
                                      );
                                    },
                                  );
                                  Navigator.of(context).pop();
                                }).toList(),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const DefaultBottomNavbar(index: 3),
      floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () {
            context.pushTransition(
                type: PageTransitionType.fade,
                child: CustomUsersForm(
                  onSubmit: (Map<String, String> formData) {
                    try {
                      AppUser userModel = AppUser(
                        firstName: formData['firstName']!,
                        lastName: formData['lastName']!,
                        email: formData['email']!,
                        uid: formData['uid'],
                        role: formData['role']! == 'admin'
                            ? UserRole.admin
                            : UserRole.staff,
                        yearLevel: {
                          '1': '1st Year',
                          '2': '2nd Year',
                          '3': '3rd Year',
                          '4': '4th Year'
                        }[formData['yearLevel']] ??
                            'Unknown',
                        source: formData['role']!,
                      );
                      if (AuthService().isEmailAuthorized(userModel.email)) {
                        _userManagement.addPendingUser(userModel).then((_) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("User Role added successfully!")),
                          );
                          // TODO: Need to implement catching an error for the GenericFormFields
                          // so that when the email is invalid the form clears the text
                          // we only check for um email in the users page
                        }).catchError((error) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $error')),
                          );
                          _emailController.clear();
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('We only accept umindanao Email')),
                        );
                        _emailController.clear();
                      }
                    } catch (e) {
                      logger.e("Error: $e");
                    }
                  },
                  clearForm: () {
                    _emailController.clear();
                  },
                ));
            /*Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CustomUsersForm(
                  onSubmit: (Map<String, String> formData) {
                    try {
                      AppUser userModel = AppUser(
                        firstName: formData['firstName']!,
                        lastName: formData['lastName']!,
                        email: formData['email']!,
                        uid: formData['uid'],
                        role: formData['role']! == 'admin'
                            ? UserRole.admin
                            : UserRole.staff,
                        yearLevel: {
                              '1': '1st Year',
                              '2': '2nd Year',
                              '3': '3rd Year',
                              '4': '4th Year'
                            }[formData['yearLevel']] ??
                            'Unknown',
                        source: formData['role']!,
                      );
                      if (AuthService().isEmailAuthorized(userModel.email)) {
                        _userManagement.addPendingUser(userModel).then((_) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("User Role added successfully!")),
                          );
                          // TODO: Need to implement catching an error for the GenericFormFields
                          // so that when the email is invalid the form clears the text
                          // we only check for um email in the users page
                        }).catchError((error) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $error')),
                          );
                          _emailController.clear();
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('We only accept umindanao Email')),
                        );
                        _emailController.clear();
                      }
                    } catch (e) {
                      logger.e("Error: $e");
                    }
                  },
                  clearForm: () {
                    _emailController.clear();
                  },
                ),
              ),
            );*/
          }),
    );
  }
}
