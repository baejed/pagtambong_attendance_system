import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pagtambong_attendance_system/model/UserRoles.dart';
import 'package:pagtambong_attendance_system/service/LogService.dart';
import 'package:rxdart/rxdart.dart';

class UserManagement {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final logger = LogService();

  /*Future<void> addPendingUser(String email, UserRole role) async {
    try {
      final adminDoc = await _firestore
          .collection('admin')
          .where('email', isEqualTo: email)
          .get();
      final staffDoc = await _firestore
          .collection('staff')
          .where('email', isEqualTo: email)
          .get();

      if (adminDoc.docs.isNotEmpty || staffDoc.docs.isNotEmpty) {
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
  }*/
  Future<void> addPendingUser(AppUser user) async {
    try {
      final adminDoc = await _firestore
          .collection('admin')
          .where('email', isEqualTo: user.email)
          .get();
      final staffDoc = await _firestore
          .collection('staff')
          .where('email', isEqualTo: user.email)
          .get();

      if (adminDoc.docs.isNotEmpty || staffDoc.docs.isNotEmpty) {
        throw 'User already exists in admin or staff collection';
      }

      // Check if in already pending
      final pendingDoc =
          await _firestore.collection('pending_users').doc(user.email).get();
      if (pendingDoc.exists) {
        throw 'User already in pending list';
      }

      // Add to collection
      await _firestore.collection('pending_users').doc(user.email).set({
        'firstName': user.firstName,
        'lastName': user.lastName,
        'email': user.email,
        'role': user.role.toString().split('.').last,
        'yearLevel':
            user.yearLevel.isNotEmpty ? user.yearLevel : "Not Specified",
        'createdAt': DateTime.now(),
      });
    } catch (e) {
      // Add to logs please
      rethrow;
    }
  }

  // Get All Admins
  Stream<List<Map<String, dynamic>>> getAllAdmins() {
    final data = _firestore
        .collection('admin')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              // data['role'] = 'admin';
              data['source'] = 'admin';
              // logger.i("$data");
              return data;
            }).toList());

    // logger.i("$data");
    return data;
  }

  // Get All Staffs
  Stream<List<Map<String, dynamic>>> getAllStaffs() {
    return _firestore
        .collection('staff')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
          final data = doc.data();
          // data['role'] = 'staff';
          data['source'] = 'staff';
          return data;
    }).toList());
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

  Future<void> getFirstAdmin() async {
    final adminStream = getAllAdmins()
        .map((admins) => admins.map((data) => AppUser.fromMap(data)).toList());
    final firstAdminList = await adminStream.first;
    logger.i("${firstAdminList.single}");
    // return firstAdminList.isNotEmpty ? firstAdminList.first : throw 'No admin found';
  }

  // Get all users and roles
  Stream<List<AppUser>> getAllUsers() {
    final adminStream = getAllAdmins()
        .map((admins) => admins.map((data) => AppUser.fromMap(data)).toList());
    final staffStream = getAllStaffs()
        .map((staff) => staff.map((data) => AppUser.fromMap(data)).toList());


    // logger.i("${adminStream.single}");
    // logger.i("$staffStream");
    /*adminStream.listen((shit) {
      logger.i("Admin Stream: ${shit.first}");
    });

    staffStream.listen((shit) {
      logger.i("Staff Stream: ${shit.first}");
    });*/

    // logger.i("Staff Stream: ${staffStream.first}");
    /*final value = adminStream.first.then((adminStream) {
      logger.i("${adminStream.first.role}");
    });*/
    final combinedStream = Rx.combineLatest2(
      adminStream,
      staffStream,
      (List<AppUser> admins, List<AppUser> staff) => [...admins, ...staff],
    );

    return combinedStream;
    /*return _firestore.collection('users').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => AppUser.fromFirestore(doc.data()))
              .toList(),
        );*/
  }
}
