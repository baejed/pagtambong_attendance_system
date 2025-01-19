import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:page_transition/page_transition.dart';
import 'package:pagtambong_attendance_system/auth/session.dart';
import 'package:pagtambong_attendance_system/events.dart';
import 'package:pagtambong_attendance_system/model/UserRoles.dart';
import 'package:pagtambong_attendance_system/personel.dart';
import 'package:pagtambong_attendance_system/resources/CheckgaColors.dart';
import 'package:pagtambong_attendance_system/scanner.dart';
import 'package:pagtambong_attendance_system/service/AuthService.dart';
import 'package:pagtambong_attendance_system/service/LogService.dart';
import 'package:pagtambong_attendance_system/students.dart';
import 'package:pagtambong_attendance_system/super_admin/super_main.dart';

// Kay ambot dili man pwede ibutang lang sa class, fuck implements
final LogService logger = LogService();

class DefaultAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DefaultAppBar({super.key});

  final String title = "CheckGa!";

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.mainColor,
      title: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            const Image(
              image: AssetImage("assets/codes_logo.png"),
              width: 40,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
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
        context.pushAndRemoveUntilTransition(
          type: PageTransitionType.fade,
          child: const ScannerPage(),
          predicate: (route) => false,
        );
        /*Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const ScannerPage()),
            (route) => false);*/
        // Navigator.pushReplacement(context,
        //     MaterialPageRoute(builder: (context) => const ScannerPage()));
        break;
      case 1:
        context.pushAndRemoveUntilTransition(
          type: PageTransitionType.fade,
          child: const EventsPage(),
          predicate: (route) => false,
        );
        /*Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const EventsPage()),
            (route) => false);*/
        // Navigator.pushReplacement(context,
        //     MaterialPageRoute(builder: (context) => const EventsPage()));
        break;
      case 2:
        context.pushAndRemoveUntilTransition(
          type: PageTransitionType.fade,
          child: const StudentPageScreenSomethingThatIDontEvenKnowWhatThisIsAnymorePleaseHelpMe(),
          predicate: (route) => false,
        );
        /*Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    const StudentPageScreenSomethingThatIDontEvenKnowWhatThisIsAnymorePleaseHelpMe()),
            (route) => false);*/
        // Navigator.pushReplacement(context,
        //     MaterialPageRoute(builder: (context) => const PersonelPage()));
        break;
      case 3:
        context.pushAndRemoveUntilTransition(
          type: PageTransitionType.fade,
          child: const ManageUseringScreenPleaseHelpMeThisIsNotHealthyForMyMentalHealthIThinkIAmGoingInsaneWithThisProject(),
          predicate: (route) => false,
        );
        /*Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const ManageUseringScreenPleaseHelpMeThisIsNotHealthyForMyMentalHealthIThinkIAmGoingInsaneWithThisProject()),
          (route) => false,
        );*/
        break;
    }
  }

  // OOOOOOHHH So skeri, maybe this is my final destination, fuck you
  Future<List<Widget>> getFinalDestinations() async {
    // final User? currUser = await AuthService().getCurrUser();
    // logger.i("Current User Role: ${currUser?.uid}");
    List<Widget> destinations = [
      NavigationDestination(
        icon: Icon(Icons.qr_code,
            color: index == 0
                ? AppColors.activeNavbarColor
                : Colors.black), // Scanner
        label: "",
      ),
      NavigationDestination(
        icon: Icon(Icons.event_available_sharp,
            color: index == 1
                ? AppColors.activeNavbarColor
                : Colors.black), //Events
        label: "",
      ),
      NavigationDestination(
        icon: Icon(Icons.school,
            color: index == 2
                ? AppColors.activeNavbarColor
                : Colors.black), // Students
        label: "",
      ),
      NavigationDestination(
        icon: Icon(Icons.people_alt,
            color: index == 3
                ? AppColors.activeNavbarColor
                : Colors.black), // Staffs
        label: "",
      )
    ];

    // Checking the current role of the user then pop the shit out in the list
    final role = Session.loggedRole;
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
            return const Center(
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
              labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
              onDestinationSelected: (selectedIndex) =>
                  _onItemTapped(context, selectedIndex),
              indicatorColor: const Color.fromARGB(0, 0, 0, 0),
              // no color
              selectedIndex: index,
              destinations: snapshot.data!,
              backgroundColor: AppColors.navbarColor,
              height: 60,
            );
          }
        });
  }
}

class DefaultDrawer extends StatelessWidget {
  const DefaultDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text(
              "CheckGA! Attendance",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading:  const Icon(Icons.account_circle),
            title: const Text("Profile"),
            onTap: () {
              Fluttertoast.showToast(
                msg: "Profile Page Clicked",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.CENTER,
                timeInSecForIosWeb: 1,
                backgroundColor: Colors.blue,
                textColor: Colors.white,
                fontSize: 16.0,
              );
            },
          ),
          ListTile(
            leading:  const Icon(Icons.settings),
            title: const Text("Settings"),
            onTap: () {
              Fluttertoast.showToast(
                msg: "Settings Page Clicked",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.CENTER,
                timeInSecForIosWeb: 1,
                backgroundColor: Colors.blue,
                textColor: Colors.white,
                fontSize: 16.0,
              );
            },
          ),

          ListTile(
            leading:  const Icon(Icons.logout),
            title: const Text("Logout"),
            onTap: () {
              // logger.i("User Role: ${Session.loggedRole}");
              AuthService().signOut(context: context);
              Fluttertoast.showToast(
                msg: "Logout The Shit out of You",
                toastLength: Toast.LENGTH_LONG,
                gravity: ToastGravity.CENTER,
                timeInSecForIosWeb: 1,
                backgroundColor: Colors.blue,
                textColor: Colors.white,
                fontSize: 16.0,
              );
            },
          ),

        ],
      ),
    );
  }
}
