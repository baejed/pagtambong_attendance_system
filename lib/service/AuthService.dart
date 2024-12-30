import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
// import 'package:google_one_tap_sign_in/google_one_tap_sign_in.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pagtambong_attendance_system/auth/login.dart';
import 'package:pagtambong_attendance_system/scanner.dart';

class AuthService {
  final webClientID = "214065685114-3euvfcjun8gd4pb7d3ivsjb7trbtanmq.apps.googleusercontent.com";

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
              builder: (BuildContext context) => const ScannerPage()));
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
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      await Future.delayed(const Duration(seconds: 1));

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
    await Future.delayed(const Duration(seconds: 1));
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (BuildContext context) => Login()),
    );
  }

  // Google Sign In
  signInWithGoogle() async {
    // Begin interactive sign in process
    final GoogleSignInAccount? gUser = await GoogleSignIn().signIn();

    // User Cancels
    if (gUser == null) return;

    // Obtain auth details from request
    final GoogleSignInAuthentication gAuth = await gUser.authentication;

    // Create a new credential for user
    final credentials = GoogleAuthProvider.credential(
      accessToken: gAuth.accessToken,
      idToken: gAuth.idToken,
    );

    // Sign In
    return await FirebaseAuth.instance.signInWithCredential(credentials);
  }

  // Google 1-tap Sign In
//   googleOneTapSignIn({
//     required BuildContext context
// }) async {
//     var result = await GoogleOneTapSignIn.handleSignIn(webClientId: webClientID);
//
//     if (result.isTemporaryBlock){
//       Fluttertoast.showToast(msg: "Temporary BLOCK");
//     } else if (result.isCanceled) {
//       Fluttertoast.showToast(msg: "Operation Canceled");
//     } else if (result.isFail){
//       Fluttertoast.showToast(msg: "Operation Failed");
//     } else if (result.isOk){
//       // Returns SignInResult data
//       final idToken = result.data?.idToken;
//       final email = result.data?.username;
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (BuildContext context) => Login()),
//       );
//     }
//   }
}
