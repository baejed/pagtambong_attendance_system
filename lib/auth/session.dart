import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:pagtambong_attendance_system/model/UserRoles.dart';
import 'package:pagtambong_attendance_system/service/AuthService.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Session {
  static UserRole? loggedRole;
  static User? user;
  static const String _roleKey = 'user_role';

  static Future<void> init() async {
    if (user == null) {
      await initUser();
    }

    if (user != null) {
      // Try to get role from local storage first
      loggedRole = await _getStoredRole();

      // If we have internet, update the role from server and store it
      try {
        UserRole? serverRole = await AuthService().getUserRole(user!.uid);
        if (serverRole != null) {
          loggedRole = serverRole;
          await _storeRole(serverRole);
        }
      } catch (e) {
        // If offline, we'll use the stored role
        print('Unable to fetch role from server, using cached role');
      }
    }
  }

  static Future<void> _storeRole(UserRole role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleKey, json.encode(role.toJson()));
  }

  static Future<UserRole?> _getStoredRole() async {
    final prefs = await SharedPreferences.getInstance();
    final roleJson = prefs.getString(_roleKey);
    if (roleJson != null) {
      try {
        return UserRoleExtension.fromJson(jsonDecode(roleJson));
      } catch (e) {
        logger.i('Error parsing stored role: $e');
        return null;
      }
    }
    return null;
  }

  static Future<void> initUser() async {
    user = await AuthService().getCurrUser();
  }

  static Future<void> initRole() async {
    if (loggedRole == null && user != null) {
      // Try local storage first
      loggedRole = await _getStoredRole();

      // Attempt to get from server if possible
      try {
        UserRole? serverRole = await AuthService().getUserRole(user!.uid);
        if (serverRole != null) {
          loggedRole = serverRole;
          await _storeRole(serverRole);
        }
      } catch (e) {
        // Continue with stored role if offline
        print('Unable to fetch role from server, using cached role');
      }
    }
  }

  static Future<void> resetLoggedRole() async {
    loggedRole = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_roleKey);
  }
}
