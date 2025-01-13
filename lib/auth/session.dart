import 'package:firebase_auth/firebase_auth.dart';
import 'package:pagtambong_attendance_system/model/UserRoles.dart';
import 'package:pagtambong_attendance_system/service/AuthService.dart';

class Session {

  static UserRole? loggedRole;
  static User? user;

  static initRole() async {
    // if the user is null, it gets the user first
    if (user == null) {
      await initUser();
    }
    loggedRole = await AuthService().getUserRole(user!.uid);
  }

  static initUser() async {
    user = await AuthService().getCurrUser();
  }
}