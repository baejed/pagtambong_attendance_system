import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pagtambong_attendance_system/firebase_options.dart';
import 'package:pagtambong_attendance_system/model/Student.dart';
import 'package:pagtambong_attendance_system/service/OfflineAttendanceService.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late OfflineAttendanceService offlineAttendanceService;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform,);
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    offlineAttendanceService = OfflineAttendanceService();
  });

  test('cacheStudentData should cache student data', () async {
    final student = Student(
        studentId: '138530',
        firstName: 'Lance Sebastian',
        lastName: 'Limbaro',
        yearLevel: '1st Year');

    await offlineAttendanceService.cacheStudentData(student);

    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString("cached_students");

    expect(cachedData, isNotNull);

    final cachedStudent = Student.fromMap(
        Map<String, dynamic>.from(jsonDecode(cachedData!)['138530']));
    expect(cachedStudent.studentId, student.studentId);
    expect(cachedStudent.firstName, student.firstName);
    expect(cachedStudent.lastName, student.lastName);
  });
}
