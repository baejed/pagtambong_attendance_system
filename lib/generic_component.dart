import 'package:flutter/material.dart';
import 'package:pagtambong_attendance_system/events.dart';
import 'package:pagtambong_attendance_system/personel.dart';
import 'package:pagtambong_attendance_system/scanner.dart';

class DefaultAppBar extends StatelessWidget implements PreferredSizeWidget{
  const DefaultAppBar({super.key});
  
  final String title = "Pagtambong";

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,

      title: Row(
        children: [
          const Image(
            image: AssetImage("assets/codes_logo.png"),
            width: 40,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8.0,0,0,0),
            child: Text(title),
          ),
        ],
      ),
    );
  }
}

class DefaultBottomNavbar extends StatelessWidget{
  
  const DefaultBottomNavbar({super.key, required this.index});

  final int index;

  void _onItemTapped(BuildContext context, int index){
    if(index == this.index) return;
    switch (index) {
      case 0:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ScannerPage()));
        break;
      case 1:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const EventsPage()));
        break;
      case 2:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const PersonelPage()));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {

    return NavigationBar(
      onDestinationSelected: (selectedIndex) => _onItemTapped(context, selectedIndex),
      indicatorColor: Colors.lightBlueAccent,
      selectedIndex: index,
      destinations: const <Widget>[
        NavigationDestination(
          icon: Icon(Icons.camera_alt),
          label: "Scanner"
        ),
        NavigationDestination(
          icon: Icon(Icons.event_available_sharp),
          label: "Events"
        ),
        NavigationDestination(
          icon: Icon(Icons.people_alt),
          label: "Staffs"
        )
      ],
    );
  }

}