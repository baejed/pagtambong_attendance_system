import 'package:flutter/material.dart';
import 'package:pagtambong_attendance_system/generic_component.dart';
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

// Admin Page to Manager Users
class ManageUsersScreen extends StatelessWidget {
  final UserManagement _userManagement = UserManagement();
  final TextEditingController _emailController = TextEditingController();
  final logger = LogService();
  late final AppUser user;

  ManageUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Users"),
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
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: "Search Users",
                    ),
                  ),
                ),
                /*PopupMenuButton<UserRole>(
                  onSelected: (UserRole role) {
                    // TODO: After selecting role, invoke another PopeMenuButton to get the Year level of the user then set it to the AppUser Model
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
            child: StreamBuilder<List<AppUser>>(
              stream: _userManagement.getAllUsers(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                // logger.i("Snapshot: ${snapshot.data?.first.role}");
                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (content, index) {
                    final user = snapshot.data![index];
                    return ListTile(
                      title: Text(user.email),
                      subtitle: Text('Role: ${user.source}'),
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
                                        Text(role.toString().split('.').last),
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
            // TODO: Add Page for the detailed shit
            Navigator.push(
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
            );
          }),
    );
  }
}
