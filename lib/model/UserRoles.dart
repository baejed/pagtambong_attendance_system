import 'package:pagtambong_attendance_system/service/LogService.dart';

enum UserRole {
  admin,
  staff,
  user,
}

class AppUser {
  // TODO: Find a way to not use the source anymore since it is irrelevant
  // TODO: I added first name and last name fields integrate it to other implementations
  late final String email;
  late final String? firstName;
  late final String? lastName;
  final String? uid;
  final String yearLevel;
  late final UserRole role;
  final String source;

  AppUser({
    this.firstName,
    this.lastName,
    required this.email,
    this.uid,
    required this.role,
    required this.source,
    required this.yearLevel,
  });

  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'uid': uid,
      'role': role,
      'yearLevel': yearLevel,
      'source': source
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      firstName: map['firstName'],
      lastName: map['lastName'],
      email: map['email'],
      uid: map['uid'],
      role: map['role'],
      yearLevel: map['yearLevel'],
      source: map['source'],
    );
  }

  factory AppUser.fromFirestore(Map<String, dynamic> data, String source) {
    final logger = LogService();
    return AppUser(
      firstName: data['firstName'],
      lastName: data['lastName'],
      email: data['email'],
      uid: data['uid'],
      role: UserRole.values.firstWhere(
            (e) => e.toString() == 'UserRole.${data['role']}',
        orElse: () => UserRole.user,
      ),
      source: source,
      yearLevel: data['yearLevel'],
    );
  }
}
