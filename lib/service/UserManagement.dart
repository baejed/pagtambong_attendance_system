import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pagtambong_attendance_system/model/UserRoles.dart';

class UserManagement {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addPendingUser(String email, UserRole role) async {
    try {
      final adminDoc = await _firestore
          .collection('admin')
          .where('email', isEqualTo: email)
          .get();
      final staffDoc = await _firestore
          .collection('staff')
          .where('email', isEqualTo: email)
          .get();

      if (adminDoc.docs.isEmpty || staffDoc.docs.isEmpty) {
        throw 'User already exists in admin or staff collection';
      }

      // Check if in already pending
      final pendingDoc =
          await _firestore.collection('pending_users').doc(email).get();
      if (pendingDoc.exists) {
        throw 'User already in pending list';
      }

      // Add to collection
      await _firestore.collection('pending_users').doc(email).set({
        'email': email,
        'role': role.toString().split('.').last,
        'createdAt': DateTime.now(),
      });
    } catch (e) {
      // Add to logs please
      rethrow;
    }
  }

  // Get All Admins
  Stream<List<Map<String, dynamic>>> getAllAdmins() {
    return _firestore
        .collection('admin')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());

  }

  // Get All Staffs
  Stream<List<Map<String, dynamic>>> getAllStaffs() {
    return _firestore
        .collection('staff')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());

  }

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
