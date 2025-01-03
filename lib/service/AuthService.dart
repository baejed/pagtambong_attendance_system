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

// TODO: Add a CRUD Service for the Super Admin

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

  Future<void> signIn({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      await Future.delayed(const Duration(seconds: 1));

      // TODO: Check if the account or user is authenticated
      if (await checkUserCredential(userCredential)) {
        Fluttertoast.showToast(
          msg: "Successfully Signed In!",
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
      }
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
  Future<AppUser?> signInWithGoogle() async {
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
      final userDoc = await _firestore
          .collection("users")
          .doc(userCredential.user!.uid)
          .get();

      // TODO: Check if the account or user is authenticated
      if (await checkUserCredential(userCredential)) {
        return AppUser.fromFirestore({
          ...userDoc.data() ?? {},
          'uid': userCredential.user!.uid,
          'email': userCredential.user!.email,
        });
      }
      return null;
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

  Future<bool> checkUserCredential(UserCredential userCredentials) async {
    // Check user role in Firestore
    final userDoc = await _firestore
        .collection("users")
        .doc(userCredentials.user!.uid)
        .get();

    // TODO: Check if the account or user is authenticated
    if (!userDoc.exists) {
      // TODO: Warn the user that the account selected is not yet signed up, please contact super admin
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
