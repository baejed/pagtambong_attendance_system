import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pagtambong_attendance_system/model/UserRoles.dart';

class UserManagement {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> updateUserRole(String userEmail, UserRole newRole) async {
    try {
      // Find the user document by email
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: userEmail)
          .get();

      if (querySnapshot.docs.isEmpty) throw 'User not found!';

      // Update the role
      await _firestore
          .collection('users')
          .doc(querySnapshot.docs.first.id)
          .update({
        'role': newRole.toString().split('.').last // UserRole.admin = admin
      });
    } catch (e) {
      Fluttertoast.showToast(msg: "Error updating user role: $e");
      rethrow;
    }
  }

  // Get all users and roles
  Stream<List<AppUser>> getAllUsers() {
    return _firestore.collection('users').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => AppUser.fromFirestore(doc.data()))
              .toList(),
        );
  }
}
