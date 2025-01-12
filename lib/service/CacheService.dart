import 'dart:convert';

import 'package:pagtambong_attendance_system/model/UserRoles.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/Student.dart';

class StudentCache {
  static const String _cacheKey = "students_cache";
  static const Duration _cacheValidDuration = Duration(hours: 24);

  Future<void> saveStudents(List<Student> students) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = students.map((s) => s.toMap()).toList();
    await prefs.setString(_cacheKey, jsonEncode(jsonData));
    await prefs.setString("${_cacheKey}_timestamp", DateTime.now().toIso8601String());
  }

  Future<List<Student>> getStudents() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_cacheKey);
    final timeStampString = prefs.getString("${_cacheKey}_timestamp");

    if (jsonString == null || timeStampString == null) {
      return [];
    }

    final timeStamp = DateTime.parse(timeStampString);

    if (DateTime.now().difference(timeStamp) > _cacheValidDuration) {
      return []; // Cache expired
    }

    final jsonData = jsonDecode(jsonString) as List;

    return jsonData
        .map((item) => Student.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    await prefs.remove('${_cacheKey}_timestamp');
  }
}

class UserCache {
  static const String _cacheKey = "users_cache";
  static const Duration _cacheValidDuration = Duration(hours: 24);

  Future<void> saveUsers(List<AppUser> users) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = users.map((u) => u.toMap()).toList();
    await prefs.setString(_cacheKey, jsonEncode(jsonData));
    await prefs.setString("${_cacheKey}_timestamp", DateTime.now().toIso8601String());
  }

  Future<List<AppUser>> getUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_cacheKey);
    final timeStampString = prefs.getString("${_cacheKey}_timestamp");

    if (jsonString == null || timeStampString == null) {
      return [];
    }

    final timeStamp = DateTime.parse(timeStampString);

    if (DateTime.now().difference(timeStamp) > _cacheValidDuration) {
      return []; // Cache expired
    }

    final jsonData = jsonDecode(jsonString) as List;

    return jsonData
        .map((item) => AppUser.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> clearCacge() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    await prefs.remove("${_cacheKey}_timestamp");
  }
}