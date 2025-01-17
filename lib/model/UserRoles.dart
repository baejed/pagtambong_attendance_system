enum UserRole {
  admin,
  staff,
  user;

  String toJson() => name;
}

extension UserRoleExtension on UserRole {
  String toJson() => toString().split('.').last;

  static UserRole fromJson(String map) {
    return UserRole.values.firstWhere(
        (role) =>
            role.toString().split('.').last.toLowerCase() == map.toLowerCase(),
        orElse: () => UserRole.staff);
  }
}

class AppUser {
  // TODO: Find a way to not use the source anymore since it is irrelevant
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
      'role': role.name,
      'yearLevel': yearLevel,
      'source': source
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'role': role.toJson(),
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    final role = UserRole.values.firstWhere(
        (e) => e.toString() == 'UserRole.${map['role']}',
        orElse: () => UserRole.user);

    return AppUser(
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      email: map['email'] ?? '',
      uid: map['uid'],
      role: _stringToUserRole(map['role'] ?? 'staff'),
      yearLevel: map['yearLevel'] ?? 'Unknown',
      source: map['source'] ?? '',
    );
  }

  static UserRole _stringToUserRole(String roleStr) {
    return UserRole.values.firstWhere(
          (role) =>
      role
          .toString()
          .split('.')
          .last
          .toLowerCase() == roleStr.toLowerCase(),
      orElse: () => UserRole.staff,
    );
  }
}
