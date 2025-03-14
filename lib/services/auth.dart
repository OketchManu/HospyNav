import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
  final _secureStorage = const FlutterSecureStorage();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Connectivity _connectivity = Connectivity();

  AuthService() {
    if (kDebugMode) print('FirebaseAuth initialized with default instance');
    setupTokenRefresh();
  }

  void setupTokenRefresh() {
    Timer.periodic(const Duration(hours: 1), (timer) async {
      if (_auth.currentUser != null) {
        try {
          await _auth.currentUser!.getIdToken(true);
          await saveLoginState();
          if (kDebugMode) print('Token refreshed successfully');
        } catch (e) {
          if (kDebugMode) print('Token refresh failed: $e');
        }
      }
    });
  }

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> saveLoginState() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await _secureStorage.write(key: 'user_id', value: user.uid);
        await _secureStorage.write(key: 'last_login', value: DateTime.now().toIso8601String());
        await _secureStorage.write(key: 'email', value: user.email);
        if (kDebugMode) print('Login state saved for user: ${user.uid}');
      }
    } catch (e) {
      if (kDebugMode) print('Error saving login state: $e');
      throw Exception('Failed to save login state: $e');
    }
  }

  Future<bool> _checkConnectivity() async {
  final connectivityResults = await _connectivity.checkConnectivity();
  return connectivityResults.isNotEmpty && 
         connectivityResults.any((result) => result != ConnectivityResult.none);
}

  Future<bool> isLoggedIn() async {
    try {
      String? userId = await _secureStorage.read(key: 'user_id');
      User? firebaseUser = _auth.currentUser;
      if (kDebugMode) {
        print('Checking login state:');
        print('Stored USER ID: $userId');
        print('Firebase User: ${firebaseUser?.uid}');
      }
      if (userId != null && firebaseUser != null && userId == firebaseUser.uid) {
        bool isOnline = await _checkConnectivity();
        if (isOnline) {
          try {
            await firebaseUser.getIdToken(true);
            await _firestore.collection('users').doc(firebaseUser.uid).update({
              'lastLogin': FieldValue.serverTimestamp(),
            });
          } catch (e) {
            if (kDebugMode) print('Session validation failed: $e');
            return false;
          }
        }
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) print('Error checking login state: $e');
      return false;
    }
  }

  Future<void> tryAutoLogin() async {
    try {
      if (await isLoggedIn()) {
        if (kDebugMode) print('Auto-login successful');
      } else {
        await signOut();
        if (kDebugMode) print('Auto-login failed, user directed to login');
      }
    } catch (e) {
      if (kDebugMode) print('Error during auto-login: $e');
      throw Exception('Auto-login failed: $e');
    }
  }

  Future<UserCredential?> signInWithEmailOrPhone({
    required String identifier,
    required String password,
  }) async {
    try {
      bool isOnline = await _checkConnectivity();
      if (!isOnline) {
        if (await isLoggedIn()) {
          if (kDebugMode) print('Offline: Using cached login');
          return null;
        }
        throw Exception('You are offline. Please connect to the internet to log in.');
      }

      String emailToUse = identifier;

      if (_isValidPhoneNumber(identifier)) {
        String normalizedPhone = identifier.startsWith('+') 
            ? identifier 
            : '+254${identifier.replaceFirst(RegExp(r'^0'), '')}';
        DocumentSnapshot doc = await _firestore
            .collection('phoneToEmail')
            .doc(normalizedPhone)
            .get();
        if (!doc.exists) throw Exception('No account found with this phone number.');
        emailToUse = doc.get('email') as String;
        if (emailToUse.isEmpty) throw Exception('No email linked to this phone number.');
      }

      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: emailToUse,
        password: password,
      );
      await _firestore.collection('users').doc(userCredential.user?.uid).update({
        'lastLogin': FieldValue.serverTimestamp(),
      });
      await saveLoginState();
      return userCredential;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      bool isOnline = await _checkConnectivity();
      if (!isOnline) {
        if (await isLoggedIn()) {
          if (kDebugMode) print('Offline: Using cached Google login');
          return null;
        }
        throw Exception('You are offline. Please connect to the internet to log in with Google.');
      }

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw Exception('Google sign-in aborted by user');

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      await _firestore.collection('users').doc(userCredential.user?.uid).set({
        'email': userCredential.user?.email,
        'displayName': userCredential.user?.displayName,
        'photoURL': userCredential.user?.photoURL,
        'phoneNumber': userCredential.user?.phoneNumber ?? '',
        'lastLogin': FieldValue.serverTimestamp(),
        'createdAt': userCredential.additionalUserInfo?.isNewUser ?? false
            ? FieldValue.serverTimestamp()
            : FieldValue.serverTimestamp(),
        'registrationMethod': 'google',
      }, SetOptions(merge: true));
      await saveLoginState();
      return userCredential;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String phoneNumber,
  }) async {
    try {
      bool isOnline = await _checkConnectivity();
      if (!isOnline) {
        throw Exception('You are offline. Please connect to the internet to register.');
      }
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      String normalizedPhone = phoneNumber.startsWith('+') 
          ? phoneNumber 
          : '+254${phoneNumber.replaceFirst(RegExp(r'^0'), '')}';
      
      await _firestore.collection('users').doc(userCredential.user?.uid).set({
        'email': email,
        'phoneNumber': normalizedPhone,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'registrationMethod': 'email',
      }, SetOptions(merge: true));

      await _firestore.collection('phoneToEmail').doc(normalizedPhone).set({
        'email': email,
      }, SetOptions(merge: true));

      await saveLoginState();
      return userCredential;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(PhoneAuthCredential) onVerificationCompleted,
    required Function(FirebaseAuthException) onVerificationFailed,
    required Function(String, int?) onCodeSent,
    required Function(String) onCodeAutoRetrievalTimeout,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: onVerificationCompleted,
        verificationFailed: onVerificationFailed,
        codeSent: onCodeSent,
        codeAutoRetrievalTimeout: onCodeAutoRetrievalTimeout,
      );
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<UserCredential> signInWithPhoneCredential(PhoneAuthCredential credential) async {
    try {
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      await _firestore.collection('users').doc(userCredential.user?.uid).set({
        'phoneNumber': userCredential.user?.phoneNumber,
        'email': userCredential.user?.email ?? '',
        'lastLogin': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'registrationMethod': 'phone_sms',
      }, SetOptions(merge: true));
      await saveLoginState();
      return userCredential;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
        _secureStorage.delete(key: 'user_id'),
        _secureStorage.delete(key: 'last_login'),
        _secureStorage.delete(key: 'email'),
      ]);
      if (kDebugMode) print('User signed out successfully');
    } catch (e) {
      if (kDebugMode) print('Sign out failed: $e');
      throw _handleAuthException(e);
    }
  }

  Future<void> initialize() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await saveLoginState();
        if (kDebugMode) print('Auth initialized with existing user: ${user.uid}');
      } else {
        String? userId = await _secureStorage.read(key: 'user_id');
        if (userId != null) {
          try {
            await _auth.currentUser?.getIdToken(true);
            if (kDebugMode) print('Token refreshed during initialization');
          } catch (e) {
            await _secureStorage.deleteAll();
            if (kDebugMode) print('Cleared invalid session during initialization: $e');
          }
        }
      }
      if (kDebugMode) print('Auth initialization completed');
    } catch (e) {
      if (kDebugMode) print('Error during auth initialization: $e');
      throw Exception('Failed to initialize authentication: $e');
    }
  }

  bool _isValidPhoneNumber(String phone) {
    return RegExp(r'^(?:\+254|0)[1-9]\d{8}$').hasMatch(phone);
  }

  Exception _handleAuthException(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return Exception('No user found with these credentials.');
        case 'wrong-password':
          return Exception('Incorrect password provided.');
        case 'email-already-in-use':
          return Exception('An account already exists with this email or phone number.');
        case 'invalid-email':
          return Exception('Please provide a valid email address or phone number.');
        case 'weak-password':
          return Exception('The password provided is too weak.');
        case 'operation-not-allowed':
          return Exception('This authentication method is not enabled.');
        case 'invalid-verification-code':
          return Exception('Invalid verification code provided.');
        case 'invalid-verification-id':
          return Exception('Invalid verification ID provided.');
        case 'account-exists-with-different-credential':
          return Exception('Account exists with a different sign-in method.');
        case 'invalid-credential':
          return Exception('The sign-in credentials are invalid.');
        default:
          return Exception('An authentication error occurred: ${e.message ?? "Unknown error"}');
      }
    }
    return Exception('An unexpected error occurred: $e');
  }
}