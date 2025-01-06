import 'package:pagtambong_attendance_system/service/LogService.dart';

enum UserRole {
  admin,
  staff,
  user,
}

class AppUser {
  final String email;
  final String uid;
  final UserRole role;
  final String source;

  AppUser({
    required this.email,
    required this.uid,
    required this.role,
    required this.source,
  });

  factory AppUser.fromFirestore(Map<String, dynamic> data, String source) {
    final logger = LogService();
    return AppUser(
      email: data['email'],
      uid: data['uid'],
      role: UserRole.values.firstWhere(
            (e) => e.toString() == 'UserRole.${data['role']}',
        orElse: () => UserRole.user,
      ),
      source: source,
    );
  }
}
