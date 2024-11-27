import 'package:flutter/material.dart';
import 'package:pagtambong_attendance_system/generic_component.dart';

class PersonelPage extends StatefulWidget {

  const PersonelPage({super.key});

  @override
  State<PersonelPage> createState() => _PersonelPageState();

}

class _PersonelPageState extends State<PersonelPage>{

  @override
  Widget build(BuildContext context){
    return const Scaffold(
      appBar: DefaultAppBar(),
      body: Center(
        child: Text("Personel Page")
      ),
      bottomNavigationBar: DefaultBottomNavbar(
        index: 2
      ),
    );
  }

}