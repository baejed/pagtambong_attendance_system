import 'package:flutter/material.dart';
import 'package:pagtambong_attendance_system/generic_component.dart';

class ScannerPage extends StatefulWidget {

  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();

}

class _ScannerPageState extends State<ScannerPage>{

  @override
  Widget build(BuildContext context){
    return const Scaffold(
      appBar: DefaultAppBar(),
      body: Center(
        child: Text("Scanner Page"),
      ),
      bottomNavigationBar: DefaultBottomNavbar(
        index: 0
      ),
    );
  }

}