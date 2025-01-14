import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pagtambong_attendance_system/auth/login.dart';
import 'package:pagtambong_attendance_system/auth/session.dart';
import 'package:pagtambong_attendance_system/model/PaginatedResult.dart';
import 'package:pagtambong_attendance_system/model/UserRoles.dart';
import 'package:pagtambong_attendance_system/service/CacheService.dart';
import 'package:pagtambong_attendance_system/service/LogService.dart';

class AuthService {
  final logger = LogService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  GoogleSignInAccount? _currentUser;
  User? _currUser;

  // PAAAAAAAAAAAAAAAGIIIIIIIIIIIIIIIINAAAAAAAAAAAAAAAAATIIIIIIIIIIIOOOOOOOON \\
  static final CollectionReference _usersDb =
      FirebaseFirestore.instance.collection('admin');

  static const int _batchSize = 100;
  static final _cache = UserCache();

  static final _usersController =
      StreamController<PaginatedResult<AppUser>>.broadcast();
  static final _searchController =
      StreamController<PaginatedResult<AppUser>>.broadcast();

  static Future<void> _loadUsers(
      int page, int pageSize, String searchQuery) async {
    try {
      var cachedData = await _cache.getUsers();
      if (cachedData.isNotEmpty) {
        // Emit Shit
        _emitPaginatedResults(cachedData, page, pageSize, searchQuery);
      }
      var freshData = await getAllUsersNotStream();
      await _cache.saveUsers(freshData);
      _emitPaginatedResults(freshData, page, pageSize, searchQuery);
    } catch (e) {
      _usersController.addError(e);
    }
  }

  static Stream<PaginatedResult<AppUser>> getAllPaginatedUsers({
    int page = 1,
    int pageSize = 20,
    String searchQuery = '',
  }) {
    _loadUsers(page, pageSize, searchQuery);
    return _usersController.stream;
  }

  static Stream<PaginatedResult<AppUser>> getSearchResults({
    required String query,
    int page = 1,
    int pageSize = 20,
  }) {
    _performSearch(query, page, pageSize);
    return _searchController.stream;
  }

  static void _emitPaginatedResults(
    List<AppUser> users,
    int page,
    int pageSize,
    String searchQuery,
  ) {
    if (searchQuery.isNotEmpty) {
      // Filter Users
      users = _filterUsers(users, searchQuery);
    }

    final startIndex = (page - 1) * pageSize;
    final endIndex = startIndex + pageSize;
    final paginatedItems = users.length > startIndex
        ? users.sublist(
            startIndex,
            endIndex > users.length ? users.length : endIndex,
          )
        : <AppUser>[];

    final result = PaginatedResult<AppUser>(
        items: paginatedItems,
        total: users.length,
        page: page,
        pageSize: pageSize,
        hasMore: endIndex < users.length);

    _usersController.add(result);
  }

  static List<AppUser> _filterUsers(List<AppUser> users, String query) {
    final lowerCaseQuery = query.toLowerCase();
    return users
        .where((user) =>
            user.firstName!.toLowerCase().contains(lowerCaseQuery) ||
            user.lastName!.toLowerCase().contains(lowerCaseQuery) ||
            user.email.toLowerCase().contains(lowerCaseQuery))
        .toList();
  }

  static Future<void> _performSearch(
      String query, int page, int pageSize) async {
    try {
      final users = await _cache.getUsers();
      final filteredUsers = _filterUsers(users, query);

      final startIndex = (page - 1) * pageSize;
      final endIndex = startIndex + pageSize;
      final paginatedItems = filteredUsers.length > startIndex
          ? filteredUsers.sublist(startIndex,
              endIndex > filteredUsers.length ? filteredUsers.length : endIndex)
          : <AppUser>[];
      final result = PaginatedResult<AppUser>(
          items: paginatedItems,
          total: filteredUsers.length,
          page: page,
          pageSize: pageSize,
          hasMore: endIndex < filteredUsers.length);

      _searchController.add(result);
    } catch (e) {
      _searchController.addError(e);
    }
  }

  static Future<void> addUsersByBatch(List<AppUser> newUsers) async {
    for (var i = 0; i < newUsers.length; i += _batchSize) {
      final end =
          (i + _batchSize < newUsers.length) ? i + _batchSize : newUsers.length;
      final batch = newUsers.sublist(i, end);

      var cachedUsers = await _cache.getUsers();
      cachedUsers.addAll(batch);
      await _cache.saveUsers(cachedUsers);

      _emitPaginatedResults(cachedUsers, 1, 20, '');
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  static Future<List<AppUser>> getAllUsersNotStream() async {
    await Future.delayed(const Duration(seconds: 1));

    try {
      // TODO: Get Admins and Staffs then return as List<AppUser>
      final snapshot = await _usersDb.get();
      final users = snapshot.docs.map((doc) {
        return AppUser.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
      return users;
    } catch (e) {
      return [];
    }
  }

  static void dispose() {
    _usersController.close();
    _searchController.close();
  }

  // ======================================================================== \\

  Future<User?> getCurrUser() async {
    if (_currUser != null) {
      return _currUser;
    } else {
      // Optionally, you can fetch the current user from FirebaseAuth if _currUser is null
      return FirebaseAuth.instance.currentUser;
    }
  }

/*  Future<void> signUp(
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
  }*/

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

      _currUser = userCredential.user;
      await Session.init();
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
        _currUser = userCredential.user;
        return await updateAndCheckUserRoleInFireStore(
            userCredential, pendingUserDoc);
      }

      return null;
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Some error occurred: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.blue,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      logger.e("Error Log", "Sign in Error: $e", StackTrace.current);
      signOut(context: null);
      return null;
    }
    // Sign In
    // return await FirebaseAuth.instance.signInWithCredential(credentials);
  }

  Future<UserRole?> updateAndCheckUserRoleInFireStore(
    UserCredential userCredential,
    DocumentSnapshot<Map<String, dynamic>> pendingUserDoc,
  ) async {
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
