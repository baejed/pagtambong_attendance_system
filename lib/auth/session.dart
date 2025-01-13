import 'package:firebase_auth/firebase_auth.dart';
import 'package:pagtambong_attendance_system/model/UserRoles.dart';
import 'package:pagtambong_attendance_system/service/AuthService.dart';

class Session {
  static UserRole? loggedRole;
  static User? user;

  static Future<void> init() async {
    // if the user is null, it gets the user first
    if (user == null) {
      await initUser();
    }
    if (user != null) {
      loggedRole = await AuthService().getUserRole(user!.uid);
    }
  }

  static Future<void> initUser() async {
    user = await AuthService().getCurrUser();
  }

  static Future<void> initRole() async {
    if (loggedRole == null && user != null) {
      loggedRole = await AuthService().getUserRole(user!.uid);
    }
  }
}
