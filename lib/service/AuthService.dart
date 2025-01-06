import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pagtambong_attendance_system/auth/login.dart';
import 'package:pagtambong_attendance_system/model/UserRoles.dart';
import 'package:pagtambong_attendance_system/scanner.dart';
import 'package:pagtambong_attendance_system/service/LogService.dart';


class AuthService {
  final logger = LogService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<void> signUp(
      {required String email,
      required String password,
      required BuildContext context}) async {
    try {
      await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      await Future.delayed(const Duration(seconds: 1));

      Fluttertoast.showToast(
        msg: "Account Successfully Created!",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.SNACKBAR,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 14.0,
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => const ScannerPage(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String message = '';
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak';
      } else if (e.code == 'email-already-in-use') {
        message = 'An account already exists with that email';
      }
      Fluttertoast.showToast(
          msg: message,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.SNACKBAR,
          backgroundColor: Colors.black54,
          textColor: Colors.white,
          fontSize: 14.0);
    } catch (e) {
      // Empty Shit
    }
  }

  Future<UserRole?> signIn({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      await Future.delayed(const Duration(seconds: 1));

      // Check user role in Firestore
      final pendingUserDoc = await _firestore
          .collection("pending_users")
          .doc(userCredential.user!.uid)
          .get();

      if (await checkUserCredential(userCredential, pendingUserDoc)) {
        return await updateAndCheckUserRoleInFireStore(
            userCredential, pendingUserDoc);
      }

      // If not in pending_users, check if already in admin/staff
      final adminDoc = await _firestore
          .collection('admin')
          .doc(userCredential.user!.uid)
          .get();

      if (adminDoc.exists) return UserRole.admin;

      final staffDoc = await _firestore
          .collection('staff')
          .doc(userCredential.user!.uid)
          .get();

      if (staffDoc.exists) return UserRole.staff;

      return UserRole.user;
    } on FirebaseAuthException catch (e) {
      String message = '';
      if (e.code == 'invalid-email') {
        message = "No user found for that email";
      } else if (e.code == 'invalid-credential') {
        message = "Wrong password provided for that user";
      }

      Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.SNACKBAR,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 14.0,
      );
    } catch (e) {
      // Empty Shit
    }
    return null;
  }

  Future<void> signOut({
    required BuildContext context,
  }) async {
    await FirebaseAuth.instance.signOut();
    await _googleSignIn.signOut();
    await Future.delayed(const Duration(seconds: 1));
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (BuildContext context) => Login()),
    );
  }

  // Google Sign In
  Future<UserRole?> signInWithGoogle() async {
    try {
      // Begin interactive sign in process
      final GoogleSignInAccount? gUser = await _googleSignIn.signIn();

      // User Cancels
      if (gUser == null) return null;

      // Obtain auth details from request
      final GoogleSignInAuthentication gAuth = await gUser.authentication;

      // Create a new credential for user
      final credentials = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credentials);

      // Check user role in Firestore
      final pendingUserDoc = await _firestore
          .collection("pending_users")
          .doc(userCredential.user!.uid)
          .get();

      // TODO: Check if the account or user is authenticated
      if (await checkUserCredential(userCredential, pendingUserDoc) &&
          pendingUserDoc.exists) {
        return await updateAndCheckUserRoleInFireStore(
            userCredential, pendingUserDoc);
      }

      // If not in pending_users, check if already in admin/staff
      final adminDoc = await _firestore
          .collection('admin')
          .doc(userCredential.user!.uid)
          .get();

      if (adminDoc.exists) return UserRole.admin;

      final staffDoc = await _firestore
          .collection('staff')
          .doc(userCredential.user!.uid)
          .get();

      if (staffDoc.exists) return UserRole.staff;

      return UserRole
          .user; // Ambot unsay pulos ani na role para guro sa mga mysterious persons HAHAHAHA
    } catch (e) {
      Fluttertoast.showToast(msg: "Some error occurred: $e");
      if (kDebugMode) {
        logger.e("Error Log", "Sign in Error: $e", StackTrace.current);
      }
      return null;
    }
    // Sign In
    // return await FirebaseAuth.instance.signInWithCredential(credentials);
  }

  Future<UserRole?> updateAndCheckUserRoleInFireStore(
      UserCredential userCredential,
      DocumentSnapshot<Map<String, dynamic>> pendingUserDoc) async {
    final role = pendingUserDoc.data()?['role'];

    if (role == 'admin') {
      await _firestore.collection('admin').doc(userCredential.user!.uid).set({
        'email': userCredential.user!.email,
        'uid': userCredential.user!.uid,
        'createdAt': DateTime.now(), // For logging purposes
      });

      // Delete from pending
      await _firestore
          .collection('pending_users')
          .doc(userCredential.user!.email)
          .delete();

      return UserRole.admin;
    } else if (role == 'staff') {
      await _firestore.collection('staff').doc(userCredential.user!.uid).set({
        'email': userCredential.user!.email,
        'uid': userCredential.user!.uid,
        'createdAt': DateTime.now(), // For logging purposes
      });

      // Delete from pending
      await _firestore
          .collection('pending_users')
          .doc(userCredential.user!.email)
          .delete();

      return UserRole.staff;
    }

    return UserRole.user;
  }

  Future<bool> checkUserCredential(UserCredential userCredentials,
      DocumentSnapshot<Map<String, dynamic>> userDoc) async {

    if (!userDoc.exists) {
      Fluttertoast.showToast(
        msg: "Account is not yet signed up, please contact Super Admin",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.SNACKBAR,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 14.0,
      );
      await userCredentials.user!.delete();
      await FirebaseAuth.instance.signOut();
      await _googleSignIn.signOut();
      _auth.signOut();
      return false;
    }

    return true;
  }

  Future<UserRole> getUserRole(String uid) async {
    final doc = await _firestore.collection("users").doc(uid).get();
    if (!doc.exists) return UserRole.user;

    return UserRole.values.firstWhere(
      (e) => e.toString() == 'UserRole.${doc.data()?['role']}',
      orElse: () => UserRole.user,
    );
  }

  bool isEmailAuthorized(String email) {
    // Define the allowed domain
    const String allowedDomain = "@umindanao.edu.ph";

    // Check if the email ends with the allowed domain
    return email.toLowerCase().endsWith(allowedDomain.toLowerCase());
  }
}
