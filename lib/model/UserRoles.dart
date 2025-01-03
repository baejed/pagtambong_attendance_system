enum UserRole {
  admin,
  staff,
  user,
}

class AppUser {
  final String email;
  final String uid;
  final UserRole role;

  AppUser({
    required this.email,
    required this.uid,
    required this.role,
  });

  factory AppUser.fromFirestore(Map<String, dynamic> data) {
    return AppUser(
      email: data['email'],
      uid: data['uid'],
      role: UserRole.values.firstWhere(
        (e) => e.toString() == 'UserRole.${data['role']}',
        orElse: () => UserRole.user,
      ),
    );
  }
}
