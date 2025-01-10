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
  GoogleSignInAccount? _currentUser;
  User? _currUser;

  Future<User?> getCurrUser() async {
    if (_currUser != null) {
      return _currUser;
    } else {
      // Optionally, you can fetch the current user from FirebaseAuth if _currUser is null
      return FirebaseAuth.instance.currentUser;
    }
  }

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

      _currUser = userCredential.user;

      // Check user role in Firestore
      final pendingUserDoc = await _firestore
          .collection("pending_users")
          .doc(userCredential.user!.email)
          .get();

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

      if (await checkUserCredential(userCredential, pendingUserDoc)) {
        return await updateAndCheckUserRoleInFireStore(
            userCredential, pendingUserDoc);
      }

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
      signOut(context: null);
      return null;
    }
    return null;
  }

  Future<void> signOut({
    required BuildContext? context,
  }) async {
    await FirebaseAuth.instance.signOut();
    await _googleSignIn.signOut();
    await Future.delayed(const Duration(seconds: 1));
    if (context != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (BuildContext context) => Login()),
      );
    }
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

      // _currentUser = userCredential.user as GoogleSignInAccount?;
      _currUser = userCredential.user;
      // logger.i("User Credential: ${userCredential.user}");
      // logger.i("Current User: $_currUser");

      // LOGGING
      // logger.i("Email: ${userCredential.user!.email}, UID: ${userCredential.user!.uid}");

      // Check user role in Firestore
      final pendingUserDoc = await _firestore
          .collection("pending_users")
          .doc(userCredential.user!.email)
          .get();

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

      // TODO: Check if the account or user is authenticated
      if (await checkUserCredential(userCredential, pendingUserDoc)) {
        return await updateAndCheckUserRoleInFireStore(
            userCredential, pendingUserDoc);
      }

      return null; // Ambot unsay pulos ani na role para guro sa mga mysterious persons HAHAHAHA
    } catch (e) {
      Fluttertoast.showToast(msg: "Some error occurred: $e");
      if (kDebugMode) {
        logger.e("Error Log", "Sign in Error: $e", StackTrace.current);
      }
      signOut(context: null);
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
      signOut(context: null);
      return false;
    }

    return true;
  }

  Future<UserRole> getUserRole(String uid) async {
    final adminDoc = await _firestore.collection("admin").doc(uid).get();
    final staffDoc = await _firestore.collection("staff").doc(uid).get();
    if (adminDoc.exists) {
      return UserRole.admin;
    } else if (staffDoc.exists) {
      return UserRole.staff;
    }
    return UserRole.user;
  }

  GoogleSignInAccount? getCurrentUser() {
    return _currentUser;
  }

  //================= Helper Functions =================\\
  bool isEmailAuthorized(String email) {
    // Define the allowed domain
    const String allowedDomain = "@umindanao.edu.ph";

    // Check if the email ends with the allowed domain
    return email.toLowerCase().endsWith(allowedDomain.toLowerCase());
  }
}
