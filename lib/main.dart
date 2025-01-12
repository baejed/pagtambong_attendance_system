import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pagtambong_attendance_system/auth/login.dart';
import 'package:pagtambong_attendance_system/auth/session.dart';
import 'package:pagtambong_attendance_system/events.dart';
import 'package:pagtambong_attendance_system/personel.dart';
import 'firebase_options.dart';
import 'scanner.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Session.initUser();
  await Session.initRole();

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
        bottomSheetTheme: const BottomSheetThemeData(
          dragHandleColor: Color.fromARGB(255, 0, 66, 119)
        )
      ),
      // This is to check if the user is already logged in, then it will just proceed to scanner, else go to login (user is new)
      home: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, AsyncSnapshot<User?> user) {
          if (user.hasData) {
            return const ScannerPage();
          } else {
            return Login();
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
