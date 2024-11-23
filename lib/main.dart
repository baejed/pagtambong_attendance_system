import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pagtambong_attendance_system/events.dart';
import 'package:pagtambong_attendance_system/personel.dart';
import 'firebase_options.dart';
import 'scanner.dart';

Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pagtambong',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Pagtambong'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index){
    setState(() {
      _selectedIndex = index;
    });
  }

  List<Widget> destinations = [const ScannerPage(), const EventsPage(), const PersonelPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(

        backgroundColor: Theme.of(context).colorScheme.inversePrimary,

        title: Row(
          children: [
            const Image(
              image: AssetImage("assets/codes_logo.png"),
              width: 40,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8.0,0,0,0),
              child: Text(widget.title),
            ),
          ],
        ),
      ),
      body: destinations[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: _onItemTapped,
        indicatorColor: Colors.lightBlueAccent,
        selectedIndex: _selectedIndex,
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
      ),
    );
  }
}
