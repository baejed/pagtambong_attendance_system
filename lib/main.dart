import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:pagtambong_attendance_system/auth/login.dart';
import 'package:pagtambong_attendance_system/auth/session.dart';
import 'package:pagtambong_attendance_system/events.dart';
import 'package:pagtambong_attendance_system/personel.dart';
import 'package:pagtambong_attendance_system/service/LogService.dart';
import 'firebase_options.dart';
import 'scanner.dart';

LogService logger = LogService();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await Session.init();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((value) => runApp(const MyApp()));

  // runApp(const MyApp());
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
      // This is to check if the user is already logged in, then it will just proceed to scanner, else go to login (user is new)
      home: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, AsyncSnapshot<User?> user) {
          if (user.hasData) {
            return FutureBuilder(
              future: Session.initRole(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(),);
                } else if (snapshot.hasError) {
                  return const Center(child: Text("Error initializing role"),);
                } else {
                  // UserRole? userRole = snapshot.data as UserRole?;
                  // logger.i("User Fucking Role: $userRole");
                  return const ScannerPage();
                }
              },
            );
            // return const ScannerPage();
          } else{
            return Login();
            // return const ScannerPage();
          }
        },
      ),
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
  List<Widget> destinations = [
    const ScannerPage(),
    const EventsPage(),
    const PersonelPage()
  ];

  @override
  Widget build(BuildContext context) {
    return const ScannerPage();
  }
}
