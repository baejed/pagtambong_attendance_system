import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pagtambong_attendance_system/events.dart';
import 'package:pagtambong_attendance_system/model/UserRoles.dart';
import 'package:pagtambong_attendance_system/personel.dart';
import 'package:pagtambong_attendance_system/scanner.dart';
import 'package:pagtambong_attendance_system/service/AuthService.dart';
import 'package:pagtambong_attendance_system/service/LogService.dart';
import 'package:pagtambong_attendance_system/students.dart';
import 'package:pagtambong_attendance_system/super_admin/super_main.dart';

// Kay ambot dili man pwede ibutang lang sa class, fuck implements
final LogService logger = LogService();

class DefaultAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DefaultAppBar({super.key});

  final String title = "PAGTAMBONG";

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.blue[300],
      title: Row(
        children: [
          const Image(
            image: AssetImage("assets/codes_logo.png"),
            width: 40,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8.0, 0, 0, 0),
            child: Text(title),
          ),
        ],
      ),
    );
  }
}

class DefaultBottomNavbar extends StatelessWidget {
  const DefaultBottomNavbar({super.key, required this.index});

  final int index;

  void _onItemTapped(BuildContext context, int index) {
    if (index == this.index) return;

    switch (index) {
      case 0:
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const ScannerPage()),
            (route) => false);
        // Navigator.pushReplacement(context,
        //     MaterialPageRoute(builder: (context) => const ScannerPage()));
        break;
      case 1:
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const EventsPage()),
            (route) => false);
        // Navigator.pushReplacement(context,
        //     MaterialPageRoute(builder: (context) => const EventsPage()));
        break;
      case 2:
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const StudentPageScreenSomethingThatIDontEvenKnowWhatThisIsAnymorePleaseHelpMe()),
            (route) => false);
        // Navigator.pushReplacement(context,
        //     MaterialPageRoute(builder: (context) => const PersonelPage()));
        break;
      case 3:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => ManageUsersScreen()),
          (route) => false,
        );
        break;
    }
  }

  // OOOOOOHHH So skeri, maybe this is my final destination, fuck you
  Future<List<Widget>> getFinalDestinations() async {
    final User? currUser = await AuthService().getCurrUser();
    // logger.i("Current User Role: ${currUser?.uid}");
    List<Widget> destinations = [
      const NavigationDestination(
        icon: Icon(Icons.camera_alt),
        label: "Scanner",
      ),
      const NavigationDestination(
        icon: Icon(Icons.event_available_sharp),
        label: "Events",
      ),
      const NavigationDestination(
        icon: Icon(Icons.school),
        label: "Students",
      ),
      const NavigationDestination(
        icon: Icon(Icons.people_alt),
        label: "Staffs",
      )
    ];

    // Checking the current role of the user then pop the shit out in the list
    final role = await AuthService().getUserRole(currUser!.uid);
    // logger.i("Current Role: $role");
    if (role == UserRole.staff) {
      // This is really just a hacky way of implementing the role-based pages since u used a List of Widgets to store the NavigationDestinations
      destinations.removeAt(3);
    }

    return destinations;
  }

  @override
  Widget build(BuildContext context) {
    /// I changed the widget to FutureBuilder to handle the retrieving of asynchronous data from the function `getFinalDestinations`
    return FutureBuilder(
        future: getFinalDestinations(),
        builder: (context, snapshot) {
          // Just a bunch of checks for error handling asynchronous process (too fucking complex imo)
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const  Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                strokeWidth: 6.0,
              ),
            );
          } else if (snapshot.hasError) {
            return Text("Error: ${snapshot.error}");
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Text("No destinations available");
          } else {
            return NavigationBar(
              onDestinationSelected: (selectedIndex) =>
                  _onItemTapped(context, selectedIndex),
              indicatorColor: Colors.lightBlueAccent,
              selectedIndex: index,
              destinations: snapshot.data!,
            );
          }
        });
  }
}
