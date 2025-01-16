import 'package:flutter/material.dart';
import 'package:pagtambong_attendance_system/generic_component.dart';
import 'package:pagtambong_attendance_system/service/LogService.dart';

class ProfileScreen extends StatelessWidget {
  final logger = LogService();

  ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: DefaultAppBar(),
      drawer: DefaultDrawer(),
    );
  }
}